from typing import List

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..data.models import JournalEntry, JournalEntryInDB, UserInDB
from ..db.connect import pb_client
from ..db.authenticate import get_current_user_required

class ResponseID(BaseModel):
    id: str

class JournalService:
    def __init__(self, pb_client):
        self.pb_client = pb_client

    # TODO: not sure if this is valid to pass JournalEntry instead of json dict.
    async def post_journal_entry(self, user_id: str, entry: JournalEntry):
        """Add user journal to database"""
        print("ENTRY TYPE:", type(entry))
        print("ENTRY FIELDS:", entry.model_dump())

        result = await self.pb_client.create_record("journal_entry", entry)

        return ResponseID(id=result["id"])

    async def fetch_journal_entries(self, user_id: str) -> List[dict]:
        """List all journal entries"""
        params = {}

        params["filter"] = f"user_id = '{user_id}'"

        result = await self.pb_client.get_records("journal_entry", params)
        return result["items"]

journal_service = JournalService(pb_client)

router = APIRouter(prefix="/api/journal", tags=["journal"])


@router.post("", response_model=ResponseID)  # Fixed response model
async def post_journal_entry(
    entry: JournalEntry,
    user: UserInDB = Depends(get_current_user_required),
):
    """Post user Journal Entry"""
    result = await journal_service.post_journal_entry(user_id=user.id, entry=entry)
    return result

@router.get("", response_model=List[JournalEntryInDB])
async def fetch_journal_entries(
    user: UserInDB = Depends(get_current_user_required),
):
    """List journal entries accessible to the user"""
    records = await journal_service.fetch_journal_entries(user_id=user.id)
    return [JournalEntryInDB.model_validate(record) for record in records]
