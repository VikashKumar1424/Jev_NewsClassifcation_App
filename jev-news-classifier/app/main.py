from fastapi import FastAPI

from app.api.routes.news import router as news_router


app = FastAPI(
    title="JEV News Classifier",
    description="News classification using Gemini and TypeSafe Jev",
    version="1.0.0",
)


app.include_router(news_router)


@app.get("/")
def root():
    return {
        "service": "jev-news-classifier",
        "status": "running",
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "jev-news-classifier",
    }