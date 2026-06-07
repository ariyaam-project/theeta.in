from typing import Literal

from pydantic import BaseModel, Field, HttpUrl


class ClaimedJob(BaseModel):
    id: str
    reelId: str
    url: HttpUrl
    attempt: int
    maxAttempts: int


class ClaimResponse(BaseModel):
    job: ClaimedJob | None


class Segment(BaseModel):
    start: float
    end: float
    text: str


class Transcript(BaseModel):
    language: str | None
    text: str
    segments: list[Segment]
    modelUsed: str


class ReelComment(BaseModel):
    id: str | None = None
    author: str | None = None
    text: str
    likeCount: int | None = None
    timestamp: int | None = None


class ReelEvidence(BaseModel):
    caption: str | None = None
    uploader: str | None = None
    channel: str | None = None
    comments: list[ReelComment] = Field(default_factory=list)


class EvidenceQuote(BaseModel):
    source: Literal["caption", "comment", "transcript"]
    text: str


class LocationExtraction(BaseModel):
    is_food_related: bool = True
    rejection_reason: str | None = None
    restaurant_name: str | None = None
    branch_name: str | None = None
    area: str | None = None
    city: str | None = None
    state: str | None = None
    country: str | None = None
    suggested_address: str | None = None
    suggested_lat: float | None = None
    suggested_lng: float | None = None
    suggested_location_confidence: float = Field(default=0, ge=0, le=1)
    landmarks: list[str] = Field(default_factory=list)
    evidence: list[EvidenceQuote] = Field(default_factory=list)
    confidence: float = Field(ge=0, le=1)
    needs_transcription: bool


class CommentAnalysis(BaseModel):
    analyzed_count: int = 0
    positive_count: int = 0
    negative_count: int = 0
    neutral_count: int = 0
    sentiment_score: float = Field(default=0, ge=-1, le=1)
    common_praise: list[str] = Field(default_factory=list)
    common_complaints: list[str] = Field(default_factory=list)
    sponsored_signal: bool = False
    authenticity_note: str | None = None
    verdict: str | None = None


class PipelineResult(BaseModel):
    evidence: ReelEvidence
    extraction: LocationExtraction
    transcript: Transcript | None = None
    comment_analysis: CommentAnalysis | None = None
