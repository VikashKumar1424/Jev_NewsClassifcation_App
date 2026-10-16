# JEV News Classifier

A SwiftUI iOS frontend backed by a Python FastAPI backend for classifying news. The backend uses JEV to determine a news category, confidence, specificity, and ambiguity, then uses Gemini to enrich the response when needed.

![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/36601a5d831558f4cc82500db5a049b13aad97d8/jev1.png)
![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/b474e73b36a7f6ebe3595f1953fc4c3591e2f898/jev2.png)
![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/83681f206d74d8a93bd7ec1958a93bd558daa8d2/jev3.png)
![Image Alt](https://github.com/VikashKumar1424/Jev_NewsClassifcation_App/blob/24056f41f986af2f21523274d96bc9a02d991e03/jev4.png)

## Architecture

This repository is organized into two cooperating runtime layers:

- **iOS frontend (`NewsJev_ios/NewsJev`):** A SwiftUI client that captures user-entered text, submits classification requests, handles loading/error states, and renders the classification outcome.
- **Python backend (`jev-news-classifier`):** A FastAPI service that validates input, invokes JEV, applies category-routing logic, and optionally calls Gemini for a second-pass validation or summary.

The Swift client never calls JEV or Gemini directly. It communicates with the backend through the versioned `/api/v1/news` endpoints. This keeps model credentials, policy logic, and routing decisions on the server side.

### System architecture (block diagram)

The diagram below uses a block-style layout to show the major runtime components and the primary request/response paths between the iOS client and the backend classifier stack.

```mermaid
flowchart TB
  subgraph Frontend
    direction TB
    User[User\n(enters headline/article)] --> UI[SwiftUI\nContentView]
    UI --> Store[NewsState\n@MainActor @Observable]
    Store --> APIClient[NewsAPIService\nPOST /api/v1/news/classify]
  end

  subgraph Backend
    direction TB
    API[FastAPI app\napp.main:app] --> Router[News router\n/api/v1/news]
    Router --> Classify[ClassifierService.classify]
    Router --> Compare[ClassifierService.compare]

    Classify --> Validate[NewsRequest\nPydantic validation]
    Validate --> Orchestrator[ClassifierService\norchestration & routing]

    Orchestrator --> JEV[JevService\nTypeSafe JEV client]
    Orchestrator --> Gemini[GeminiService\noptional second-pass]
    JEV --> Signals[category, confidence, probabilities, specificity, latency]
    Gemini --> GeminiSignals[category, confidence, summary]

    Orchestrator --> AutoRouter[AutoRouter\napply routing policy]
    AutoRouter -->|high confidence| JEVOnly[jev_only\nreturn response]
    AutoRouter -->|medium confidence| GeminiCheck[jev_then_gemini\ncompare results]
    AutoRouter -->|low confidence or non-specific| HumanReview[human_review\nneeds_human_review = true]
    AutoRouter -->|ambiguous| FollowUp[ask_follow_up\nrequest clarifying input]

    GeminiCheck --> CompareDecision{JEV == Gemini?}
    CompareDecision -->|yes| Accepted[accept & return]
    CompareDecision -->|no| HumanReview
  end

  %% Cross-boundary flows
  APIClient -->|JSON request| API
  API -->|JSON response| APIClient
  APIClient --> Store
  Store --> ResultCard[SwiftUI result card\ncategory, confidence, margin, summary, processing_path]
  Accepted --> Response[NewsResponse JSON]
  JEVOnly --> Response
  HumanReview --> Response
  FollowUp --> Response
  Response --> API
  API --> APIClient

  %% Notes
  classDef service fill:#f9f,stroke:#333,stroke-width:1px;
  class Orchestrator,JEV,Gemini,AutoRouter service;
```

### Backend architecture (`jev-news-classifier`)

The backend follows a layered FastAPI design:

1. **Application layer (`app/main.py`)** creates the FastAPI application, registers the news router, and exposes the root and health endpoints.
2. **API layer (`app/api/routes/news.py`)** defines the `/api/v1/news` routes for classification and JEV-vs-Gemini comparison, then returns validated response payloads.
3. **Schema layer (`app/models/news.py`)** validates incoming text and defines the response contract shared with the iOS app.
4. **Orchestration layer (`app/services/classifier_service.py`)** calls the JEV service, derives probabilities and confidence margins, and executes the route-selection policy.
5. **JEV integration (`app/services/jev_service.py`)** invokes the TypeSafe JEV model and returns category, probabilities, specificity, confidence, and latency metadata.
6. **Gemini integration (`app/services/gemini_service.py`)** produces a second-pass classification or summary when the system deems it necessary and safely falls back when the API is unavailable.
7. **Routing layer (`app/router/auto_router.py`)** decides whether the request should be resolved as `jev_only`, `jev_then_gemini`, `ask_follow_up`, or `human_review` based on confidence and specificity thresholds.

### iOS frontend architecture (`NewsJev_ios`)

The client follows a lightweight presentation/state/networking split:

1. **View (`UI/ContentView.swift`)** collects a headline or article and renders the category, confidence metrics, top-two comparison, summary, and decision reason.
2. **State (`State/NewsState.swift`)** is a `@MainActor`/`@Observable` layer that manages `idle`, `loading`, `loaded`, and `error` states, cancels in-flight requests, and exposes the latest response data to views.
3. **API client (`APIServices/NewsAPIService.swift`)** builds the HTTP requests, serializes `NewsRequest`, validates 2xx responses, and decodes the `NewsResponse` payload.
4. **Models (`Model/NewsModel.swift`)** define the request/response contracts used across the Swift codebase, including the mapping between backend snake_case fields and Swift property names.
5. **Application entry point (`NewsJevApp.swift`)** creates the SwiftUI app and presents the main screen.

### End-to-end request flow

1. The user enters news text in `ContentView` and taps **Classify News**.
2. `NewsState` transitions to `loading` and sends the request through `NewsAPIService`.
3. `NewsAPIService` posts JSON to `POST /api/v1/news/classify`.
4. FastAPI validates the request using `NewsRequest` and delegates to `ClassifierService`.
5. `JevService` classifies the text and returns probability signals plus specificity metadata.
6. `AutoRouter` calculates the confidence margin and applies the routing policy.
7. If the result requires Gemini, `GeminiService` produces a JSON classification and compares it with JEV; mismatches or outages lead to review/fallback handling.
8. The backend returns `NewsResponse`, which the iOS app decodes and renders in the SwiftUI result card.

### Backend decision policy

- **Non-specific input (`specificity_score < 0.50`):** route to `human_review` and set `needs_human_review = true`.
- **Ambiguous input (`margin < 0.15`):** route to `ask_follow_up` and request the primary focus of the story.
- **High confidence (`confidence >= 0.90`):** return `jev_only` without human review.
- **Medium confidence (`0.60 <= confidence < 0.90`):** call Gemini and return `jev_then_gemini`.
- **Low confidence (`confidence < 0.60`):** route to `human_review` and set `needs_human_review = true`.
- **Gemini failure:** return a fallback summary and set `needs_human_review = true`.

## Repository layout

```text
.
├── NewsJev_ios/
│   ├── NewsJev.xcodeproj/              # Xcode project
│   └── NewsJev/
│       ├── NewsJevApp.swift            # SwiftUI application entry point
│       ├── UI/ContentView.swift        # Input form and result presentation
│       ├── State/NewsState.swift       # Observable state and network orchestration
│       ├── Model/NewsModel.swift       # Codable API models
│       └── APIServices/
│           └── NewsAPIService.swift    # HTTP client and error handling
├── jev-news-classifier/
│   ├── app/
│   │   ├── main.py                     # FastAPI app and health endpoints
│   │   ├── api/routes/news.py          # News classification and comparison routes
│   │   ├── models/news.py              # Pydantic schemas
│   │   ├── router/
│   │   │   ├── auto_router.py          # Routing rules and thresholds
│   │   │   └── route_models.py         # Enum + route metadata models
│   │   └── services/
│   │       ├── classifier_service.py  # Routing and thresholds
│   │       ├── jev_service.py         # TypeSafe JEV classification
│   │       └── gemini_service.py      # Gemini summaries and fallbacks
│   ├── pyproject.toml                  # Python project metadata/dependencies
│   ├── uv.lock                         # Locked dependency resolution
│   └── tests/test_news.py              # Backend tests
├── README.md
```

## Technology stack

- **iOS frontend:** Swift 5, SwiftUI, Observation, URLSession
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

Do not commit `.env` or API keys.

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

The response includes `category`, `confidence`, `top_category`, `top_confidence`, `second_category`, `second_confidence`, `confidence_margin`, `probabilities`, `summary`, `needs_human_review`, `processing_path`, `specificity`, `specificity_score`, and `decision_reason`.

## iOS frontend setup

1. Start the backend using the commands above.
2. Open `NewsJev_ios/NewsJev.xcodeproj` in Xcode.
3. Select the `NewsJev` scheme and an iOS Simulator or connected device.
4. Build and run the app.
5. Enter a headline or article and tap **Classify News**.

The development API URL is configured in `NewsJev_ios/NewsJev/APIServices/NewsAPIService.swift` as `http://127.0.0.1:8000`. This works for an iOS Simulator running on the same Mac. For a physical device, update the base URL to a reachable host or use a tunneling service.

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
  "top_category": "technology",
  "top_confidence": 0.95,
  "second_category": "business",
  "second_confidence": 0.02,
  "confidence_margin": 0.93,
  "probabilities": {
    "technology": 0.95,
    "business": 0.02
  },
  "summary": "High-confidence JEV classification.",
  "needs_human_review": false,
  "processing_path": "jev_only",
  "specificity": "specific",
  "specificity_score": 0.98,
  "decision_reason": "high_confidence_specific"
}
```

## Testing

```bash
cd jev-news-classifier
uv run pytest
```

## Current development notes

- The iOS frontend currently targets a local backend URL rather than a deployed API.
- The backend imports `load_dotenv` from `python-dotenv`; if `uv sync` reports that this package is missing, add `python-dotenv` to the project dependencies and refresh `uv.lock`.
- Python bytecode under `app/**/__pycache__` is generated and should generally be excluded from version control.

## License

No license has been specified yet.
