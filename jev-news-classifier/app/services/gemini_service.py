import json
import os

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

        self.model = "gemini-3.6-flash"

    # ============================================================
    # SUMMARY
    # ============================================================

    async def summarize(self, text: str) -> str:

        prompt = f"""
Summarize the following news article in one concise sentence.

Do not add information that is not present in the article.

News:
{text}
"""

        try:

            response = await self.client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
            )

            if not response.text:
                return (
                    "Gemini did not return a summary."
                )

            return response.text.strip()

        except errors.ServerError as error:

            print(
                f"⚠️ Gemini server error: {error}"
            )

            return (
                "Gemini is temporarily unavailable. "
                "The news requires human review."
            )

        except errors.APIError as error:

            print(
                f"⚠️ Gemini API error: {error}"
            )

            return (
                "Gemini could not process the request. "
                "The news requires human review."
            )

        except Exception as error:

            print(
                f"⚠️ Unexpected Gemini error: {error}"
            )

            return (
                "Summary unavailable. "
                "The news requires human review."
            )

    # ============================================================
    # CLASSIFICATION
    # ============================================================

    async def classify(self, text: str) -> dict:

        categories = ", ".join(
            self.CATEGORIES
        )

        prompt = f"""
You are a news classification system.

Classify the following news into exactly ONE category.

Allowed categories:

{categories}

News:
{text}

Return ONLY valid JSON.

The JSON MUST have exactly these fields:

{{
    "category": "technology",
    "confidence": 0.95,
    "reason": "Short explanation of why this category was selected."
}}

Rules:

1. category MUST be one of:

{categories}

2. confidence MUST be a number between 0 and 1.

3. confidence represents your estimated confidence
   in the selected category.

4. reason must be concise.

5. Do not add markdown.

6. Do not return any additional fields.
"""

        try:

            print()
            print("========== GEMINI CLASSIFICATION ==========")
            print("Sending request to Gemini...")
            print("============================================")

            response = await self.client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
            )

            if not response.text:

                raise RuntimeError(
                    "Gemini returned an empty classification response."
                )

            raw_text = response.text.strip()

            print("Gemini raw response:")
            print(raw_text)

            # ----------------------------------------------------
            # Remove markdown fences if Gemini returns them
            # ----------------------------------------------------

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

            # ----------------------------------------------------
            # Parse JSON
            # ----------------------------------------------------

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

            # ----------------------------------------------------
            # Validate category
            # ----------------------------------------------------

            if category not in self.CATEGORIES:

                raise ValueError(
                    f"Invalid Gemini category: {category}"
                )

            # ----------------------------------------------------
            # Validate confidence
            # ----------------------------------------------------

            if not isinstance(
                confidence,
                (int, float),
            ):

                raise ValueError(
                    "Gemini confidence must be numeric."
                )

            confidence = float(
                confidence
            )

            if not 0.0 <= confidence <= 1.0:

                raise ValueError(
                    "Gemini confidence must be between 0 and 1."
                )

            # ----------------------------------------------------
            # Final result
            # ----------------------------------------------------

            final_result = {

                "category": category,

                "confidence": confidence,

                "reason": reason or "",
            }

            print()
            print("Gemini parsed result:")
            print(final_result)
            print()

            return final_result

        except json.JSONDecodeError as error:

            print(
                f"⚠️ Gemini JSON parsing error: {error}"
            )

            raise RuntimeError(
                "Gemini returned an invalid classification response."
            )

        except errors.ServerError as error:

            print(
                f"⚠️ Gemini server error: {error}"
            )

            raise RuntimeError(
                "Gemini server is temporarily unavailable."
            )

        except errors.APIError as error:

            print(
                f"⚠️ Gemini API error: {error}"
            )

            raise RuntimeError(
                "Gemini classification failed."
            )

        except Exception as error:

            print(
                f"⚠️ Gemini classification error: {error}"
            )

            raise