from pydantic import BaseModel, Field


class NewsRequest(BaseModel):

    text: str = Field(
        ...,
        min_length=5,
        description="News headline or article text",
    )


class NewsResponse(BaseModel):

    # Final classification
    category: str
    confidence: float

    # Top-2 classification
    top_category: str
    top_confidence: float

    second_category: str
    second_confidence: float

    # Difference between Top-1 and Top-2
    confidence_margin: float

    # All category probabilities
    probabilities: dict[str, float]

    # Gemini / JEV result
    summary: str

    # Routing information
    needs_human_review: bool
    processing_path: str

    # Specificity
    specificity: str
    specificity_score: float

    # Explainable decision
    decision_reason: str