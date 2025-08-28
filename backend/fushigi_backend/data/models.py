from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict, EmailStr

# =============================================================================
# USER MODELS
# =============================================================================

class User(BaseModel):
    """
    Base user model with public fields
    """
    email: Optional[EmailStr] = Field(None, description="User's email address")
    name: Optional[str] = Field(None, description="User's display name")
    avatar: Optional[str] = Field(None, description="URL to user's avatar image")

class UserInDB(User):
    """
    Complete user model including PocketBase fields
    """
    id: str = Field(..., description="PocketBase record ID")
    created: datetime = Field(..., description="Account creation timestamp")
    updated: datetime = Field(..., description="Last update timestamp")

    model_config = ConfigDict(from_attributes=True)

# =============================================================================
# LANGUAGE LEARNING MODELS
# =============================================================================

class Languages(BaseModel):
    """
    Supported language for grammar content
    """
    name: str = Field(..., description="Language name ('Japanese', etc.)")

class LanguagesInDB(Languages):
    """
    Complete language model including PocketBase fields
    """
    id: str = Field(..., description="PocketBase record ID")
    created: datetime = Field(..., description="Creation timestamp")
    updated: datetime = Field(..., description="Last update timestamp")
    model_config = ConfigDict(from_attributes=True)

# =============================================================================
# GRAMMAR CONTENT MODELS
# =============================================================================

class Example(BaseModel):
    """
    Example sentence pair for grammar demonstrations
    """
    japanese: Optional[str] = Field(None, description="Example in Japanese")
    english: Optional[str] = Field(None, description="English translation")

class Grammar(BaseModel):
    """
    Grammar point/pattern with explanations and examples
    """
    usage: str = Field(..., description="How to use this grammar pattern")
    meaning: str = Field(..., description="What this grammar pattern means")
    context: Optional[str] = Field(None, description="When/where to use this pattern")
    tags: Optional[List[str]] = Field(None, description="Categorization tags")
    notes: Optional[str] = Field(None, description="Additional notes or warnings")
    nuance: Optional[str] = Field(None, description="Subtle meaning differences")
    examples: Optional[List[Example]] = Field(None, description="Example sentences")

class GrammarInDB(Grammar):
    """
    Complete grammar model including PocketBase fields and metadata
    """
    id: str = Field(..., description="PocketBase record ID")
    language_id: str = Field(..., description="References languages.id")
    created_by: Optional[str] = Field(None, description="References users.id or null")
    created: datetime = Field(..., description="Content creation timestamp")
    updated: datetime = Field(..., description="Last update timestamp")

    model_config = ConfigDict(from_attributes=True)

# =============================================================================
# JOURNAL MODELS
# =============================================================================

class JournalEntry(BaseModel):
    """
    User journal entry for language practice
    """
    title: str = Field(..., max_length=200, description="Entry title")
    content: str = Field(..., description="Entry content/body")
    private: bool = Field(default=True, description="Whether entry is private to user")

class JournalEntryInDB(JournalEntry):
    """
    Complete journal entry model including PocketBase fields
    """
    id: str = Field(..., description="PocketBase record ID")
    user_id: str = Field(..., description="References users.id")
    created: datetime = Field(..., description="Entry creation timestamp")
    updated: datetime = Field(..., description="Last update timestamp")

    model_config = ConfigDict(from_attributes=True)

# =============================================================================
# SENTENCE ANALYSIS MODELS
# =============================================================================

class Sentence(BaseModel):
    """
    Analyzed sentence from journal entries
    """
    content: str = Field(..., description="The sentence text")

class SentenceInDB(Sentence):
    """
    Complete sentence model with relationships to journal and grammar
    """
    id: str = Field(..., description="PocketBase record ID")
    user_id: str = Field(..., description="References users.id")
    journal_entry_id: str = Field(..., description="References journal_entry.id")
    grammar_id: str = Field(..., description="References grammar.id")
    created: datetime = Field(..., description="Creation timestamp")
    updated: datetime = Field(..., description="Last update timestamp")

    model_config = ConfigDict(from_attributes=True)

# =============================================================================
# SPACED REPETITION SYSTEM (SRS) MODELS
# =============================================================================

class SRSReview(BaseModel):
    """
    Spaced repetition system data for grammar learning
    """
    ease_factor: Optional[float] = Field(default=2.5, ge=1.0, le=5.0, description="Ease of recall (1.0-5.0)")
    interval_days: Optional[float] = Field(default=1, ge=0, description="Days until next review")
    repetition: Optional[float] = Field(default=0, ge=0, description="Number of successful reviews")

class SRSReviewInDB(SRSReview):
    """
    Complete SRS model including scheduling and tracking fields
    """
    id: str = Field(..., description="PocketBase record ID")
    user_id: str = Field(..., description="References users.id")
    grammar_id: str = Field(..., description="References grammar.id")
    due_date: datetime = Field(..., description="When next review is due")
    last_reviewed: Optional[datetime] = Field(None, description="When last reviewed")
    created: datetime = Field(..., description="When SRS tracking started")
    updated: datetime = Field(..., description="Last SRS update")

    model_config = ConfigDict(from_attributes=True)
