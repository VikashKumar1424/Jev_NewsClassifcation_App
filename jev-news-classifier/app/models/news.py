from pydantic import BaseModel, Field
from typing import Optional, List


# ============================================================
# REQUEST
# ============================================================

class NewsRequest(BaseModel):
    text: str = Field(
        ...,
        min_length=5,
        description="News headline or article text",
    )


# ============================================================
# NORMAL CLASSIFICATION RESPONSE
# ============================================================

class NewsResponse(BaseModel):
    category: str
    confidence: float

    top_category: str
    top_confidence: float

    second_category: str
    second_confidence: float

    confidence_margin: float

    probabilities: dict[str, float]

    summary: str

    needs_human_review: bool
    processing_path: str

    specificity: str
    specificity_score: float

    decision_reason: str


# ============================================================
# JEV MULTI-QUESTION RESULTS
# ============================================================

class JEVQuestionResults(BaseModel):
    category: str

    specificity: float

    is_sports: float
    is_business: float
    is_technology: float
    is_politics: float


# ============================================================
# JEV COMPARISON RESULT
# ============================================================

class JEVComparisonResult(BaseModel):
    category: str
    confidence: float

    probabilities: dict[str, float]

    specificity: str
    specificity_score: float

    questions: JEVQuestionResults

    question_count: int
    execution_mode: str
    latency_ms: float


# ============================================================
# GEMINI
# ============================================================

class GeminiClassification(BaseModel):
    category: str
    confidence: float
    reason: str

    latency_ms: float

    input_tokens: int
    output_tokens: int
    thought_tokens: int
    total_tokens: int

    input_cost_usd: float
    output_cost_usd: float
    total_cost_usd: float


# ============================================================
# JEV vs GEMINI COMPARISON
# ============================================================

class ComparisonResult(BaseModel):
    same_category: bool

    confidence_difference: float

    category_match: str

    jev_category: str
    jev_confidence: float

    gemini_category: str
    gemini_confidence: float

    latency_difference_ms: float


# ============================================================
# ROUTING
# ============================================================

class RoutingResponse(BaseModel):
    route: str

    reason: str

    needs_follow_up: bool
    needs_human_review: bool

    question: str | None
    options: list[str]


# ============================================================
# COMPLETE COMPARISON RESPONSE
# ============================================================

class NewsComparisonResponse(BaseModel):
    text: str

    jev: JEVComparisonResult

    gemini: GeminiClassification

    comparison: ComparisonResult

    routing: RoutingResponse