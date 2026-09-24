from fastapi import APIRouter

from app.models.news import (
    NewsRequest,
    NewsResponse,
    NewsComparisonResponse,
    JEVComparisonResult,
    GeminiClassification,
    ComparisonResult,
    RoutingResponse,
)

from app.services.classifier_service import ClassifierService


router = APIRouter(
    prefix="/api/v1/news",
    tags=["News"],
)


classifier_service = ClassifierService()


# ============================================================
# CLASSIFY
# ============================================================

@router.post(
    "/classify",
    response_model=NewsResponse,
)
async def classify_news(
    request: NewsRequest,
):

    result = await classifier_service.classify(
        request.text
    )

    return NewsResponse(
        **result
    )


# ============================================================
# COMPARE JEV vs GEMINI
# ============================================================

@router.post(
    "/compare",
    response_model=NewsComparisonResponse,
)
async def compare_news(
    request: NewsRequest,
):

    result = await classifier_service.compare(
        request.text
    )

    return NewsComparisonResponse(
        text=result["text"],

        jev=JEVComparisonResult(
            **result["jev"]
        ),

        gemini=GeminiClassification(
            **result["gemini"]
        ),

        comparison=ComparisonResult(
            **result["comparison"]
        ),

        routing=RoutingResponse(
            **result["routing"]
        ),
    )