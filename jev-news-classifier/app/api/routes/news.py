from fastapi import APIRouter

from app.models.news import NewsRequest, NewsResponse
from app.services.classifier_service import ClassifierService


router = APIRouter(
    prefix="/api/v1/news",
    tags=["News"],
)


classifier_service = ClassifierService()


@router.post(
    "/classify",
    response_model=NewsResponse,
)
async def classify_news(request: NewsRequest):

    result = await classifier_service.classify(
        request.text
    )

    return NewsResponse(**result)
