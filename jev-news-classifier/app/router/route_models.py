from enum import Enum

from pydantic import BaseModel, Field


class ProcessingRoute(str, Enum):
    JEV_ONLY = "jev_only"
    JEV_THEN_GEMINI = "jev_then_gemini"
    ASK_FOLLOW_UP = "ask_follow_up"
    HUMAN_REVIEW = "human_review"


class RouteDecision(BaseModel):
    route: ProcessingRoute
    reason: str

    needs_follow_up: bool = False
    needs_human_review: bool = False

    question: str | None = None

    options: list[str] = Field(
        default_factory=list
    )