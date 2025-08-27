from typing import Optional, Dict, Any
import os
import uuid
from datetime import datetime, timedelta

import httpx
from authlib.jose import jwt, JWTClaims
from fastapi import APIRouter, Depends, HTTPException, status
from psycopg import AsyncConnection
from psycopg.errors import DatabaseError
from psycopg.rows import dict_row
from pydantic import BaseModel

from ..db.connect import get_connection

class AuthRequest(BaseModel):
   provider: str
   identity_token: str
   provider_user_id: str
   email: Optional[str] = None

class UserInDB(BaseModel):
   user: dict
   token: str

OAUTH_CONFIG = {
   "apple": {
       "client_id": "tech.bunkbed.fushigi",
       "issuer": "https://appleid.apple.com",
       "jwks_uri": "https://appleid.apple.com/auth/keys"
   },
}

router = APIRouter(prefix="/auth/oauth", tags=["authorization"])

@router.post("", response_model=UserInDB)
async def oauth_signin(
   auth_request: AuthRequest,
   conn: AsyncConnection = Depends(get_connection),
) -> UserInDB:
   provider_config = OAUTH_CONFIG.get(auth_request.provider)
   if not provider_config:
       raise HTTPException(
           status_code=status.HTTP_400_BAD_REQUEST,
           detail="Unsupported provider"
       )

   user_claims = await verify_oauth_token(
       auth_request.identity_token,
       provider_config
   )

   if not user_claims:
       raise HTTPException(
           status_code=status.HTTP_401_UNAUTHORIZED,
           detail="Invalid token"
       )

   user = await get_or_create_user(
       conn=conn,
       provider=auth_request.provider,
       provider_user_id=auth_request.provider_user_id,
       email=auth_request.email or user_claims.get("email")
   )

   session_token = generate_session_token(user["id"])
   return UserInDB(user=user, token=session_token)

async def verify_oauth_token(identity_token: str, config: Dict[str, Any]) -> Optional[dict]:
   async with httpx.AsyncClient() as client:
       try:
           response = await client.get(config["jwks_uri"])
           response.raise_for_status()
           keys = response.json()["keys"]

           claims = jwt.decode(
               identity_token,
               keys,
               claims_cls=JWTClaims,
               claims_options={
                   "aud": {"essential": True, "value": config["client_id"]},
                   "iss": {"essential": True, "value": config["issuer"]}
               }
           )

           return dict(claims)

       except Exception as e:
           print(f"Token verification failed for {config['issuer']}: {e}")
           return None

async def get_or_create_user(
   conn: AsyncConnection,
   provider: str,
   provider_user_id: str,
   email: Optional[str],
) -> Dict[str, Any]:
   try:
       async with conn.transaction():
           async with conn.cursor(row_factory=dict_row) as cur:
               await cur.execute(
                   "SELECT * FROM users WHERE provider = %(provider)s AND provider_user_id = %(provider_user_id)s",
                   {"provider": provider, "provider_user_id": provider_user_id}
               )
               user_record = await cur.fetchone()

               if user_record:
                   await cur.execute(
                       "UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = %(id)s",
                       {"id": user_record["id"]}
                   )
                   return user_record

               new_user_id = str(uuid.uuid4())
               await cur.execute(
                   """INSERT INTO users (id, provider, provider_user_id, email, created_at, updated_at)
                      VALUES (%(id)s, %(provider)s, %(provider_user_id)s, %(email)s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)""",
                   {
                       "id": new_user_id,
                       "provider": provider,
                       "provider_user_id": provider_user_id,
                       "email": email
                   }
               )

               await cur.execute(
                   "SELECT * FROM users WHERE id = %(id)s",
                   {"id": new_user_id}
               )
               new_user_record = await cur.fetchone()

               if not new_user_record:
                   raise HTTPException(
                       status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                       detail="Failed to create user"
                   )
               return new_user_record

   except DatabaseError as e:
       raise HTTPException(
           status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
           detail=f"Database error: {e}"
       )

def generate_session_token(user_id: str) -> str:
   payload = {
       "user_id": user_id,
       "exp": datetime.utcnow() + timedelta(days=30),
       "iat": datetime.utcnow()
   }

   secret_key = os.getenv("JWT_SECRET_KEY", "your-dev-secret-change-in-production")
   header = {"alg": "HS256"}
   return jwt.encode(header, payload, secret_key)
