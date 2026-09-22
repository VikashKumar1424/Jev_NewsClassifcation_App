import os

from dotenv import load_dotenv
from google import genai
from google.genai import errors

load_dotenv(".env", override=True)


class GeminiService:

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

    async def summarize(
        self,
        text: str
    ) -> str:

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