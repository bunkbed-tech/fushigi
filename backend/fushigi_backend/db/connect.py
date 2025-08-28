import httpx
from typing import Optional, Any
from fastapi import HTTPException, status

class PocketBaseClient:
    def __init__(self, base_url: str = "http://db:8080"):
        self.base_url = base_url
        self.client = httpx.AsyncClient()

    async def get_records(self, collection: str, params: Optional[dict] = None) -> dict:
        """Generic method to fetch records from any collection"""
        response = await self.client.get(
            f"{self.base_url}/api/collections/{collection}/records",
            params=params or {}
        )

        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"PocketBase error: {response.text}"
            )
        return response.json()

    # TODO: is there a smarter way than to type data as Any?
    async def create_record(self, collection: str, data: Any) -> dict:
        """Generic method to create records in any collection"""
        response = await self.client.post(
            f"{self.base_url}/api/collections/{collection}/records",
            json=data
        )

        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"PocketBase error: {response.text}"
            )
        return response.json()

    async def verify_token(self, token: str) -> dict:
        """Verify and refresh a user token, returning user data"""
        headers = {"Authorization": f"Bearer {token}"}
        response = await self.client.post(
            f"{self.base_url}/api/collections/users/auth-refresh",
            headers=headers
        )
        if response.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        return response.json()

pb_client = PocketBaseClient()
