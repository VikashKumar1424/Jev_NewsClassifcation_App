from pydantic import BaseModel, Field


class NewsRequest(BaseModel):
    text: str = Field(
        ...,
        min_length=5,
        description="News headline or article text",
    )


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


# ---------------------------------------------------------
# JEV vs Gemini Comparison
# ---------------------------------------------------------

class GeminiClassification(BaseModel):
    category: str
    confidence: float
    reason: str


class ComparisonResult(BaseModel):
    same_category: bool

    confidence_difference: float

    category_match: str

    jev_category: str
    jev_confidence: float

    gemini_category: str
    gemini_confidence: float

    gemini_reason: str


class NewsComparisonResponse(BaseModel):
    text: str

    jev: dict
    gemini: GeminiClassification
    comparison: ComparisonResult