from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from ..data.models import UserInDB
from .connect import pb_client

security = HTTPBearer(auto_error=False)

async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[UserInDB]:
    """Get current user if authenticated, None otherwise"""
    if not credentials:
        return None
    try:
        user_data = await pb_client.verify_token(credentials.credentials)
        return UserInDB.model_validate(user_data["record"])
    except HTTPException:
        return None

async def get_current_user_required(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> UserInDB:
    """Get current authenticated user, raise 401 if not authenticated"""
    user_data = await pb_client.verify_token(credentials.credentials)
    return UserInDB.model_validate(user_data["record"])
