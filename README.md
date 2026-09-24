# JEV News Classifier

A SwiftUI iOS app backed by a Python FastAPI service for classifying news. The backend uses JEV to determine a news category and specificity, then routes lower-confidence or ambiguous inputs to Google Gemini for summary generation and review.

 ![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/318257500cf88d7b7288a519f4b33bb32d8ff2e6/iOS3.jpg)
 ![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/089cab8ec859e3c719ff99bcc82dcbc2ae130e71/iOS2.jpg)

## Architecture

The current implementation follows a decision pipeline with a specificity gate before the confidence gate. The flow is: SwiftUI sends text to the FastAPI backend, JEV first classifies the article and scores specificity, and Gemini is only used for human-review or enrichment cases.

```mermaid
flowchart LR
    User[User enters headline or article] --> UI[SwiftUI ContentView]
    UI --> Store[NewsStore\nMainActor observable state]
    Store --> APIClient[NewsAPIService\nURLSession POST /api/v1/news/classify]
    APIClient --> FastAPI[FastAPI app\napp.main:app]
    FastAPI --> Router[News router\n/api/v1/news/classify]
    Router --> Classifier[ClassifierService.classify()]

    Classifier --> JEV[JevService\nAsyncTypeSafeClient / jev-latest]
    JEV --> Category[category + confidence + probabilities]
    JEV --> Specificity[specificity + specificity_score]

    Specificity --> Gate{specificity_score >= 0.50?}

    Gate -- No --> GeminiSpecific[GeminiService.summarize()] 
    GeminiSpecific --> Review1[needs_human_review = true\nprocessing_path = jev_specificity_check_then_gemini]

    Gate -- Yes --> Confidence{confidence >= 0.90?}

    Confidence -- Yes --> High[summary = "High-confidence JEV classification."\nprocessing_path = jev_only\nneeds_human_review = false]

    Confidence -- No --> Medium{confidence >= 0.60?}

    Medium -- Yes --> GeminiMedium[GeminiService.summarize()] 
    GeminiMedium --> Enriched[processing_path = jev_then_gemini\nneeds_human_review = false]

    Medium -- No --> GeminiLow[GeminiService.summarize()] 
    GeminiLow --> Review2[processing_path = jev_then_gemini\nneeds_human_review = true]

    High --> Response[NewsResponse JSON]
    Review1 --> Response
    Enriched --> Response
    Review2 --> Response

    Response --> APIClient
    APIClient --> Store
    Store --> Result[SwiftUI result card\ncategory, confidence, summary, probabilities]
```

### Component view

### Frontend component responsibilities

| Component | Responsibility |
| --- | --- |
| `NewsJevApp.swift` | SwiftUI application entry point. Creates the app window and presents `ContentView`. |
| `ContentView.swift` | Presentation layer. Collects headline/article text, enables the classify action, displays loading and error states, and renders category, confidence, probabilities, summary information, and human review states. |
| `NewsStore.swift` | Main-actor observable state layer. Coordinates classification and exposes the `idle`, `loading`, `loaded`, and `error` states to the view. |
| `NewsAPIService.swift` | Networking layer. Builds the `POST /api/v1/news/classify` request, encodes the request body, validates HTTP responses, maps API failures to `APIError`, and decodes the backend `NewsResponse`. |
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
4. `JevService` classifies the text into `technology`, `business`, `sports`, `politics`, `entertainment`, `science`, `health`, or `other`, and computes a `specificity_score`.
5. `ClassifierService` runs a specificity gate first: if `specificity_score < 0.50`, it calls `GeminiService` and returns `needs_human_review = true` with `processing_path = "jev_specificity_check_then_gemini"`.
6. If the input is specific and `confidence >= 0.90`, it returns a pure JEV result with `processing_path = "jev_only"` and no human review.
7. If the input is specific and confidence is in the medium or low range, it calls Gemini and sets `processing_path = "jev_then_gemini"`; low-confidence results also trigger human review.
8. The response is decoded into `NewsResponse` and rendered by the SwiftUI result card.

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
├── README.md
```

## Technology stack

- **iOS:** Swift 5, SwiftUI, Observation, URLSession
- **Backend:** Python 3.12+, FastAPI, Uvicorn, Pydantic
- **AI services:** TypeSafe JEV (`jev-latest`) for classification and specificity; Google Gemini (`gemini-3.6-flash`) for summaries
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
    model="jev-latest",
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

The response includes `category`, `confidence`, `probabilities`, `summary`, `needs_human_review`, `processing_path`, `specificity`, and `specificity_score`.

## iOS setup

1. Start the backend using the commands above.
2. Open `NewsJev_ios/NewsJev.xcodeproj` in Xcode.
3. Select the `NewsJev` scheme and an iOS Simulator or connected device.
4. Build and run the app.
5. Enter a headline or article and tap **Classify News**.

The development API URL is configured in `NewsJev_ios/NewsJev/APIServices/NewsAPIService.swift` as `http://127.0.0.1:8000`. This works for an iOS Simulator running on the same Mac. For a physical device, update the base URL to the backend host.

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
  "specificity_score": 0.98
}
```

### Processing policy

- **High confidence (`>= 0.90`):** JEV classification only; no human review is required.
- **Medium confidence (`>= 0.60` and `< 0.90`):** JEV classification plus Gemini summary.
- **Low confidence (`< 0.60`):** JEV classification plus Gemini summary and human review.
- **Non-specific input (`specificity_score < 0.50`):** Gemini summary and human review, regardless of category confidence.
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
