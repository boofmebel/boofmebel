from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.rate_limit import RateLimitMiddleware
from app.core.security_headers import security_headers_middleware
from app.routers import auth, health

# Setup logging and Sentry
setup_logging()


def create_app() -> FastAPI:
    app = FastAPI(title="BoofMebel API", version="0.1.0")

    # Rate limiting (before CORS)
    app.add_middleware(RateLimitMiddleware)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )
    app.middleware("http")(security_headers_middleware)

    app.include_router(health.router, tags=["health"])
    app.include_router(auth.router)

    return app


app = create_app()


@app.get("/")
async def root():
    return {"status": "ok"}

