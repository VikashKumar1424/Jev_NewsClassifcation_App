# JEV News Classifier

A SwiftUI iOS app backed by a Python FastAPI service for classifying news. The backend uses JEV to determine a news category and specificity, then routes lower-confidence or ambiguous inputs to Google Gemini for summarization and contextual enrichment.

https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/main/iOS.jpeg?raw=true

## Architecture

The classification pipeline uses JEV as the first-stage classifier. It evaluates both the news category and whether the input is specific enough to classify. Medium- or low-confidence and non-specific inputs are then escalated to Gemini for summary generation before the final response is returned to the app.

```mermaid
flowchart TD
    Input[News text from SwiftUI] --> API[FastAPI POST /api/v1/news/classify]
    API --> Classifier[ClassifierService]
    Classifier --> JEV[JevService / TypeSafe JEV]
    JEV --> Decision{Specific and confidence >= 0.90?}
    Decision -- Yes --> JEVResult[JEV-only result]
    Decision -- No --> Gemini[GeminiService / Gemini Flash]
    Gemini --> GeminiResult{Gemini response}
    GeminiResult -- Success --> Enriched[Summary + classification]
    GeminiResult -- Server/API error --> Fallback[Fallback summary]
    JEVResult --> Response[NewsResponse JSON]
    Enriched --> Response
    Fallback --> Review[needs_human_review = true]
    Review --> Response
    Response --> APIClient[NewsAPIService / URLSession]
    APIClient --> Store[NewsStore]
    Store --> UI[ContentView result card]
```

### Component view

### Frontend component responsibilities

| Component | Responsibility |
| --- | --- |
| `NewsJevApp.swift` | SwiftUI application entry point. Creates the app window and presents `ContentView`. |
| `ContentView.swift` | Presentation layer. Collects headline/article text, enables the classify action, displays loading and error states, and renders category, confidence, probabilities, summary, and review flags. |
| `NewsStore.swift` | Main-actor observable state layer. Coordinates classification and exposes the `idle`, `loading`, `loaded`, and `error` states to the view. |
| `NewsAPIService.swift` | Networking layer. Builds the `POST /api/v1/news/classify` request, encodes the request body, validates HTTP responses, maps API failures to `APIError`, and decodes the backend result. |
| `NewsModel.swift` | API contract layer. Defines the Codable `NewsRequest` and `NewsResponse` models and maps snake_case backend fields such as `needs_human_review` to Swift properties. |

### Backend component responsibilities

| Component | Responsibility |
| --- | --- |
| `app/main.py` | Application bootstrap. Creates the FastAPI app, registers the news router, and exposes the root and `/health` endpoints. |
| `app/api/routes/news.py` | HTTP/API layer. Defines the `/api/v1/news` router, accepts `NewsRequest`, invokes `ClassifierService`, and returns a validated `NewsResponse`. |
| `app/models/news.py` | Validation and schema layer. Enforces the five-character minimum for incoming text and defines the response fields returned to the iOS client. |
| `app/services/classifier_service.py` | Orchestration and policy layer. Calls JEV first, evaluates specificity and confidence thresholds, decides whether Gemini is needed, and assembles the final response. |
| `app/services/jev_service.py` | JEV integration layer. Creates the TypeSafe client, defines the supported categories and specificity criteria, and returns category/specificity confidence and probabilities. |
| `app/services/gemini_service.py` | Gemini integration layer. Generates a concise summary for ambiguous or lower-confidence input and returns safe fallback messages when Gemini fails. |

### Request flow

1. `ContentView` collects the news text and asks `NewsStore` to classify it.
2. `NewsAPIService` sends the text as JSON to `POST /api/v1/news/classify`.
3. FastAPI validates the request with `NewsRequest` and delegates to `ClassifierService`.
4. `JevService` classifies the text into `technology`, `business`, `sports`, `politics`, `entertainment`, `science`, `health`, or `other`, and evaluates specificity.
5. `ClassifierService` uses JEV only for specific high-confidence results. Medium/low-confidence or non-specific results call `GeminiService`.
6. The response is decoded into `NewsResponse` and rendered by the SwiftUI result card.

## Repository layout

```text
.
├── NewsJev_ios/
│   ├── NewsJev.xcodeproj/          # Xcode project
│   └── NewsJev/
│       ├── NewsJevApp.swift        # SwiftUI application entry point
│       ├── UI/ContentView.swift    # Input form and result presentation
│       ├── State/NewsStore.swift   # Observable state and actions
│       ├── Model/NewsModel.swift   # Codable API models
│       └── APIServices/
│           └── NewsAPIService.swift # HTTP client and error handling
├── jev-news-classifier/
│   ├── app/
│   │   ├── main.py                 # FastAPI app and health endpoints
│   │   ├── api/routes/news.py      # News classification route
│   │   ├── models/news.py          # Pydantic schemas
│   │   └── services/
│   │       ├── classifier_service.py # Routing and thresholds
│   │       ├── jev_service.py        # TypeSafe JEV classification
│   │       └── gemini_service.py     # Gemini summaries and fallbacks
│   ├── pyproject.toml              # Python project metadata/dependencies
│   ├── uv.lock                     # Locked dependency resolution
│   └── tests/test_news.py           # Backend tests
└── README.md
```

## Technology stack

- **iOS:** Swift 5, SwiftUI, Observation, URLSession
- **Backend:** Python 3.12+, FastAPI, Uvicorn, Pydantic
- **AI services:** TypeSafe JEV (`jev-1.13.0`) for classification and specificity; Google Gemini (`gemini-3.6-flash`) for summaries
- **Dependency management:** `uv` with `pyproject.toml` and `uv.lock`

## Backend setup

### Prerequisites

- Python 3.12 or newer
- [`uv`](https://docs.astral.sh/uv/)
- `TYPESAFE_API_KEY`
- `GOOGLE_API_KEY`

Create `jev-news-classifier/.env`:

```env
TYPESAFE_API_KEY=your_typesafe_api_key
GOOGLE_API_KEY=your_google_api_key
```

### Environment variables and TypeSafe client example

```python
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
TYPESAFE_API_KEY = os.getenv("TYPESAFE_API_KEY")

client = TypeSafeClient(
    api_key=TYPESAFE_API_KEY,
    model="jev-1.13.0",
)
```

If your service stores the API key in `self.api_key`, use that value instead of the raw environment variable when building the client. Do not commit `.env` or API keys.

### Install and run

```bash
cd jev-news-classifier
uv sync
uv run uvicorn app.main:app --reload
```

The API is available at `http://127.0.0.1:8000`. Interactive documentation is available at `http://127.0.0.1:8000/docs`.

### Health check

```bash
curl http://127.0.0.1:8000/health
```

### Classify news with curl

```bash
curl -X POST http://127.0.0.1:8000/api/v1/news/classify \
  -H "Content-Type: application/json" \
  -d '{"text":"Apple announced a new artificial intelligence feature for its devices."}'
```

The response includes `category`, `confidence`, `probabilities`, `summary`, `needs_human_review`, `processing_path`, `specificity`, and `specificity_confidence`.

## iOS setup

1. Start the backend using the commands above.
2. Open `NewsJev_ios/NewsJev.xcodeproj` in Xcode.
3. Select the `NewsJev` scheme and an iOS Simulator or connected device.
4. Build and run the app.
5. Enter a headline or article and tap **Classify News**.

The development API URL is configured in `NewsJev_ios/NewsJev/APIServices/NewsAPIService.swift` as `http://127.0.0.1:8000`. This works for an iOS Simulator running on the same Mac. For a physical device, replace it with your machine's local IP address.

## API reference

### `POST /api/v1/news/classify`

Request:

```json
{
  "text": "A news headline or article with at least five characters"
}
```

Response shape:

```json
{
  "category": "technology",
  "confidence": 0.95,
  "probabilities": {
    "technology": 0.95,
    "business": 0.02
  },
  "summary": "...",
  "needs_human_review": false,
  "processing_path": "jev_only",
  "specificity": "specific",
  "specificity_confidence": 0.98
}
```

### Processing policy

- **High confidence (`>= 0.90`):** JEV classification only; no human review is required.
- **Medium confidence (`>= 0.60` and `< 0.90`):** JEV classification plus Gemini summary.
- **Low confidence (`< 0.60`):** JEV classification plus Gemini summary and human review.
- **Non-specific input:** Gemini summary and human review, regardless of category confidence.
- **Gemini server/API failure:** A fallback summary is returned and the result requires human review.

## Testing

```bash
cd jev-news-classifier
uv run pytest
```

## Current development notes

- The iOS client currently targets a local backend URL rather than a deployed API.
- The backend imports `load_dotenv` from `python-dotenv`; if `uv sync` reports that this package is missing, add `python-dotenv` to the project dependencies and refresh `uv.lock`.
- Python bytecode under `app/**/__pycache__` is generated and should generally be excluded from version control.

## License

No license has been specified yet.
