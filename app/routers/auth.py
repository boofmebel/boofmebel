from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.security import HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.auth import LoginRequest, RefreshRequest, TokenResponse
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])
security = HTTPBearer(auto_error=False)


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def login(
    request: Request,
    login_data: LoginRequest,
    response: Response,
    session: AsyncSession = Depends(get_session),
):
    """Login endpoint. Returns access token and sets refresh token in HttpOnly cookie."""
    auth_service = AuthService(session)
    device_info = request.headers.get("User-Agent", "unknown")

    access_token, refresh_token = await auth_service.login(
        login_data.email, login_data.password, device_info
    )

    # Set refresh token in HttpOnly, Secure, SameSite cookie
    response.set_cookie(
        key="refresh_token",
        value=refresh_token,
        httponly=True,
        secure=True,  # HTTPS only
        samesite="lax",
        max_age=30 * 24 * 60 * 60,  # 30 days
    )

    return TokenResponse(access_token=access_token)


@router.post("/refresh", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def refresh(
    request: Request,
    response: Response,
    session: AsyncSession = Depends(get_session),
):
    """Refresh access token with rotation. Reads refresh token from cookie."""
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token not found",
        )

    auth_service = AuthService(session)
    new_access_token, new_refresh_token = await auth_service.refresh(refresh_token)

    # Set new refresh token in cookie (rotation)
    response.set_cookie(
        key="refresh_token",
        value=new_refresh_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=30 * 24 * 60 * 60,
    )

    return TokenResponse(access_token=new_access_token)


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    request: Request,
    response: Response,
    session: AsyncSession = Depends(get_session),
):
    """Logout endpoint. Revokes refresh token."""
    refresh_token = request.cookies.get("refresh_token")
    if refresh_token:
        auth_service = AuthService(session)
        await auth_service.logout(refresh_token)

    # Clear cookie
    response.delete_cookie(key="refresh_token", httponly=True, secure=True, samesite="lax")

    return {"message": "Logged out successfully"}


@router.get("/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user info."""
    return {
        "id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "is_active": current_user.is_active,
    }





