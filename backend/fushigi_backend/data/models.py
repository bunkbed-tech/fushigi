from datetime import datetime

from pydantic import BaseModel, ConfigDict

import uuid


class Example(BaseModel):
    japanese: str
    english: str


class Grammar(BaseModel):
    usage: str
    meaning: str
    context: str
    tags: list[str]
    notes: str
    nuance: str
    examples: list[Example]


class GrammarWrapper(BaseModel):
    grammar: list[Grammar]


class GrammarInDB(Grammar):
    id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)


class JournalEntry(BaseModel):
    title: str
    content: str
    private: bool


class JournalEntryInDB(JournalEntry):
    id: uuid.UUID
    created_at: datetime
    user_id: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

class SRSReview(BaseModel):
    user_id: uuid.UUID
    grammar_id: uuid.UUID
    quality: int  # 0-5 quality rating; 5 = perfect
