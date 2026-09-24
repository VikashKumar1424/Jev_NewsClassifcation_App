from fastapi import APIRouter

from app.models.news import (
    NewsRequest,
    NewsResponse,
    NewsComparisonResponse,
    GeminiClassification,
    ComparisonResult,
)

from app.services.classifier_service import ClassifierService


router = APIRouter(
    prefix="/api/v1/news",
    tags=["News"],
)

classifier_service = ClassifierService()


# ---------------------------------------------------------
# Existing endpoint
# ---------------------------------------------------------

@router.post(
    "/classify",
    response_model=NewsResponse,
)
async def classify_news(request: NewsRequest):

    result = await classifier_service.classify(
        request.text
    )

    return NewsResponse(**result)


# ---------------------------------------------------------
# JEV vs Gemini comparison
# ---------------------------------------------------------

@router.post(
    "/compare",
    response_model=NewsComparisonResponse,
)
async def compare_news(request: NewsRequest):

    result = await classifier_service.compare(
        request.text
    )

    return NewsComparisonResponse(
        text=result["text"],

        jev=result["jev"],

        gemini=GeminiClassification(
            **result["gemini"]
        ),

        comparison=ComparisonResult(
            **result["comparison"]
        ),
    )