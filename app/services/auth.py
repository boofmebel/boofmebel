from datetime import datetime
from typing import Optional

from fastapi import HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    verify_password,
)
from app.repositories.user import UserRepository


class AuthService:
    """Authentication service."""

    def __init__(self, session: AsyncSession):
        self.session = session
        self.user_repo = UserRepository(session)

    async def login(self, email: str, password: str, device_info: Optional[str] = None) -> tuple[str, str]:
        """Authenticate user and return access + refresh tokens."""
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is disabled",
            )

        # Create tokens
        access_token = create_access_token(data={"sub": user.id})
        refresh_token = create_refresh_token(data={"sub": user.id})

        # Hash and save refresh token
        import hashlib

        token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        await self.user_repo.save_refresh_token(user.id, token_hash, device_info)

        return access_token, refresh_token

    async def refresh(self, refresh_token: str) -> tuple[str, str]:
        """Refresh access token with rotation."""
        # Decode token
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )

        user_id: int = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
            )

        # Check token in database
        import hashlib

        token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        stored_token = await self.user_repo.get_refresh_token(token_hash)
        if not stored_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or revoked refresh token",
            )

        # Revoke old token (rotation)
        await self.user_repo.revoke_refresh_token(token_hash)

        # Create new tokens
        new_access_token = create_access_token(data={"sub": user_id})
        new_refresh_token = create_refresh_token(data={"sub": user_id})

        # Save new refresh token
        new_token_hash = hashlib.sha256(new_refresh_token.encode()).hexdigest()
        await self.user_repo.save_refresh_token(user_id, new_token_hash, stored_token.device_info)

        return new_access_token, new_refresh_token

    async def logout(self, refresh_token: str) -> None:
        """Revoke refresh token (logout)."""
        import hashlib

        token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        await self.user_repo.revoke_refresh_token(token_hash)





