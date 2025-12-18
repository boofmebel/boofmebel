from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import RefreshToken, User


class UserRepository:
    """Repository for user operations."""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, email: str, hashed_password: str, full_name: Optional[str] = None) -> User:
        """Create a new user."""
        user = User(email=email, hashed_password=hashed_password, full_name=full_name)
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user

    async def save_refresh_token(
        self, user_id: int, token_hash: str, device_info: Optional[str] = None
    ) -> RefreshToken:
        """Save refresh token to database."""
        token = RefreshToken(user_id=user_id, token_hash=token_hash, device_info=device_info)
        self.session.add(token)
        await self.session.commit()
        await self.session.refresh(token)
        return token

    async def get_refresh_token(self, token_hash: str) -> Optional[RefreshToken]:
        """Get refresh token by hash."""
        result = await self.session.execute(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash, RefreshToken.revoked_at.is_(None)
            )
        )
        return result.scalar_one_or_none()

    async def revoke_refresh_token(self, token_hash: str) -> None:
        """Revoke a refresh token (rotation)."""
        from datetime import datetime

        token = await self.get_refresh_token(token_hash)
        if token:
            token.revoked_at = datetime.utcnow()
            await self.session.commit()





