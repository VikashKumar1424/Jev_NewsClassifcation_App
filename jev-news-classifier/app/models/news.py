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

    probabilities: dict[str, float]

    summary: str

    needs_human_review: bool

    processing_path: str

    specificity: str

    specificity_confidence: float