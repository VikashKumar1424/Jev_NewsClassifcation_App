import json
import os
import time

from dotenv import load_dotenv
from google import genai
from google.genai import errors

load_dotenv(".env", override=True)


class GeminiService:

    CATEGORIES = [
        "technology",
        "business",
        "sports",
        "politics",
        "entertainment",
        "science",
        "health",
        "other",
    ]

    def __init__(self):

        api_key = os.getenv("GOOGLE_API_KEY")

        if not api_key:
            raise RuntimeError(
                "GOOGLE_API_KEY is not configured"
            )

        self.client = genai.Client(
            api_key=api_key
        )

        self.model = os.getenv(
            "GEMINI_MODEL",
            "gemini-3.6-flash",
        )

        # -----------------------------------------
        # Pricing configuration
        # USD per 1M tokens
        # -----------------------------------------

        self.input_price_per_million = float(
            os.getenv(
                "GEMINI_INPUT_PRICE_PER_MILLION",
                "0",
            )
        )

        self.output_price_per_million = float(
            os.getenv(
                "GEMINI_OUTPUT_PRICE_PER_MILLION",
                "0",
            )
        )

    # -----------------------------------------
    # Usage metadata helper
    # -----------------------------------------

    def _get_usage_value(
        self,
        usage,
        *names,
    ):

        for name in names:

            value = getattr(
                usage,
                name,
                None,
            )

            if value is not None:
                return int(value)

        return 0

    # -----------------------------------------
    # COST
    # -----------------------------------------

    def _calculate_cost(
        self,
        input_tokens: int,
        output_tokens: int,
    ):

        input_cost = (
            input_tokens
            / 1_000_000
        ) * self.input_price_per_million

        output_cost = (
            output_tokens
            / 1_000_000
        ) * self.output_price_per_million

        return {
            "input_cost_usd": input_cost,
            "output_cost_usd": output_cost,
            "total_cost_usd": (
                input_cost + output_cost
            ),
        }

    # -----------------------------------------
    # SUMMARY
    # -----------------------------------------

    async def summarize(
        self,
        text: str,
    ) -> str:

        prompt = f"""
Summarize the following news article
in one concise sentence.

Do not add information that is not
present in the article.

News:
{text}
"""

        try:

            response = (
                await self.client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                )
            )

            if not response.text:
                return (
                    "Gemini did not return a summary."
                )

            return response.text.strip()

        except errors.ServerError as error:

            print(
                f"Gemini server error: {error}"
            )

            return (
                "Gemini is temporarily unavailable."
            )

        except Exception as error:

            print(
                f"Gemini error: {error}"
            )

            return (
                "Summary unavailable."
            )

    # -----------------------------------------
    # CLASSIFY
    # -----------------------------------------

    async def classify(
        self,
        text: str,
    ) -> dict:

        categories = ", ".join(
            self.CATEGORIES
        )

        prompt = f"""
You are a news classification system.

Classify the following news into exactly
ONE category.

Allowed categories:

{categories}

News:
{text}

Return ONLY valid JSON.

The JSON MUST contain:

{{
    "category": "technology",
    "confidence": 0.95,
    "reason": "Short explanation."
}}

Rules:

1. category MUST be one of:

{categories}

2. confidence must be between 0 and 1.

3. reason must be concise.

4. Do not add markdown.

5. Do not add additional fields.
"""

        try:

            # ---------------------------------
            # START TIMER
            # ---------------------------------

            start_time = time.perf_counter()

            response = (
                await self.client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                )
            )

            # ---------------------------------
            # END TIMER
            # ---------------------------------

            latency_ms = (
                time.perf_counter()
                - start_time
            ) * 1000

            # ---------------------------------
            # TOKEN USAGE
            # ---------------------------------

            usage = getattr(
                response,
                "usage_metadata",
                None,
            )

            input_tokens = 0
            output_tokens = 0
            thought_tokens = 0
            total_tokens = 0

            if usage:

                input_tokens = self._get_usage_value(
                    usage,
                    "prompt_token_count",
                    "prompt_tokens",
                    "total_input_tokens",
                )

                output_tokens = self._get_usage_value(
                    usage,
                    "candidates_token_count",
                    "output_tokens",
                    "total_output_tokens",
                )

                thought_tokens = self._get_usage_value(
                    usage,
                    "thoughts_token_count",
                    "thoughts_tokens",
                    "total_thought_tokens",
                )

                total_tokens = self._get_usage_value(
                    usage,
                    "total_token_count",
                    "total_tokens",
                )

            # ---------------------------------
            # COST
            # ---------------------------------

            cost = self._calculate_cost(
                input_tokens=input_tokens,
                output_tokens=(
                    output_tokens
                    + thought_tokens
                ),
            )

            # ---------------------------------
            # RESPONSE
            # ---------------------------------

            if not response.text:

                raise RuntimeError(
                    "Gemini returned empty response."
                )

            raw_text = response.text.strip()

            if raw_text.startswith("```"):

                raw_text = raw_text.replace(
                    "```json",
                    "",
                )

                raw_text = raw_text.replace(
                    "```",
                    "",
                )

                raw_text = raw_text.strip()

            result = json.loads(
                raw_text
            )

            category = result.get(
                "category"
            )

            confidence = result.get(
                "confidence"
            )

            reason = result.get(
                "reason"
            )

            if category not in self.CATEGORIES:

                raise ValueError(
                    f"Invalid Gemini category: "
                    f"{category}"
                )

            confidence = float(
                confidence
            )

            if not 0 <= confidence <= 1:

                raise ValueError(
                    "Gemini confidence must "
                    "be between 0 and 1."
                )

            final_result = {

                "category": category,

                "confidence": confidence,

                "reason": reason or "",

                # Performance
                "latency_ms": round(
                    latency_ms,
                    2,
                ),

                # Tokens
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "thought_tokens": thought_tokens,
                "total_tokens": total_tokens,

                # Cost
                **cost,
            }

            print()
            print(
                "========== GEMINI RESULT =========="
            )

            print(final_result)

            print(
                "===================================="
            )

            return final_result

        except json.JSONDecodeError as error:

            raise RuntimeError(
                "Gemini returned invalid JSON."
            ) from error

        except errors.ServerError as error:

            raise RuntimeError(
                "Gemini server is temporarily unavailable."
            ) from error

        except errors.APIError as error:

            raise RuntimeError(
                "Gemini classification failed."
            ) from error