from typing import Optional, List

from fastapi import APIRouter, Depends

from ..data.models import UserInDB, GrammarInDB
from ..db.connect import pb_client
from ..db.authenticate import get_current_user_optional

class GrammarService:
    def __init__(self, pb_client):
        self.pb_client = pb_client

    async def list_grammar(self, user_id: Optional[str] = None, limit: bool = False) -> List[dict]:
        """Grammar-specific business logic"""
        params = {}
        if limit:
            params["perPage"] = "5"
            params["sort"] = "@random"

        if user_id:
            params["filter"] = f"created_by = '' || created_by = '{user_id}'"
        else:
            params["filter"] = "created_by = ''"

        result = await self.pb_client.get_records("grammar", params)
        return result["items"]

grammar_service = GrammarService(pb_client)

router = APIRouter(prefix="/api/grammar", tags=["grammar"])

@router.get("", response_model=List[GrammarInDB])
async def list_grammar(
    user: Optional[UserInDB] = Depends(get_current_user_optional),
    limit: bool = False,
):
    """List grammar entries accessible to the user"""
    user_id = user.id if user else None
    records = await grammar_service.list_grammar(user_id=user_id, limit=limit)
    return [GrammarInDB.model_validate(record) for record in records]
