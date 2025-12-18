from collections import defaultdict
from time import time
from typing import Dict, Tuple

from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware

# In-memory rate limiter (for dev/test)
# For production, use Redis: https://redis.io/docs/manual/patterns/rate-limiting/
_rate_limit_store: Dict[str, Tuple[float, int]] = defaultdict(lambda: (0.0, 0))


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Rate limiting middleware for critical endpoints."""

    def __init__(self, app, rate_limit_config: Dict[str, Tuple[int, int]] = None):
        super().__init__(app)
        # rate_limit_config: {path: (max_requests, window_seconds)}
        self.rate_limit_config = rate_limit_config or {
            "/auth/login": (5, 60),  # 5 requests per 60 seconds
            "/auth/refresh": (10, 60),  # 10 requests per 60 seconds
            "/auth/reset-password": (3, 300),  # 3 requests per 5 minutes
        }

    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path

        # Check rate limit for configured paths
        if path in self.rate_limit_config:
            max_requests, window_seconds = self.rate_limit_config[path]
            key = f"{client_ip}:{path}"
            now = time()

            last_reset, count = _rate_limit_store[key]

            # Reset window if expired
            if now - last_reset > window_seconds:
                _rate_limit_store[key] = (now, 1)
            else:
                if count >= max_requests:
                    raise HTTPException(
                        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                        detail=f"Rate limit exceeded: {max_requests} requests per {window_seconds} seconds",
                    )
                _rate_limit_store[key] = (last_reset, count + 1)

        response = await call_next(request)
        return response





