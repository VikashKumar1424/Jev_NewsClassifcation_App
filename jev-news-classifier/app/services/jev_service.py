import os

from dotenv import load_dotenv
from typesafe_sdk import Choice, TypeSafeClient

load_dotenv(".env", override=True)


class JevService:

    def __init__(self):

        api_key = os.getenv("TYPESAFE_API_KEY")

        if not api_key:
            raise RuntimeError(
                "TYPESAFE_API_KEY is not configured"
            )

        self.api_key = api_key
        self.model = "jev-1.13.0"

    async def classify(self, text: str) -> dict:

        state = {
            "news": text
        }

        questions = {

            "category": Choice(
                instructions=(
                    "Classify the news into exactly one category. "
                    "Use other only when the news is sufficiently "
                    "specific and understandable but clearly belongs "
                    "outside the listed categories. "
                    "Do not use other merely because the news is vague."
                ),
                criteria={
                    "technology": (
                        "Technology, software, AI, computers, devices, "
                        "internet, cybersecurity, digital products "
                        "or technology companies."
                    ),

                    "business": (
                        "Companies, markets, finance, economy, trade, "
                        "investment, banking or business."
                    ),

                    "sports": (
                        "Sports, teams, players, matches, tournaments, "
                        "competitions or athletics."
                    ),

                    "politics": (
                        "Government, elections, politicians, legislation, "
                        "public policy or political events."
                    ),

                    "entertainment": (
                        "Movies, music, television, celebrities, "
                        "streaming or popular entertainment."
                    ),

                    "science": (
                        "Scientific discoveries, research, space, "
                        "experiments or scientific studies."
                    ),

                    "health": (
                        "Medicine, healthcare, diseases, wellness, "
                        "hospitals or medical research."
                    ),

                    "other": (
                        "A specific and understandable news topic "
                        "that does not belong to technology, business, "
                        "sports, politics, entertainment, science "
                        "or health."
                    ),
                },
            ),

            "specificity": Choice(
                instructions=(
                    "Determine whether the news contains enough "
                    "concrete information to understand what actually "
                    "happened. Vague, generic, incomplete, hypothetical "
                    "or non-specific statements are not_specific."
                ),
                criteria={
                    "specific": (
                        "The text identifies a concrete event, subject, "
                        "organization, person, product, discovery, "
                        "decision or situation with enough information "
                        "to understand the news."
                    ),

                    "not_specific": (
                        "The text is vague, generic, incomplete, "
                        "ambiguous, hypothetical, or does not provide "
                        "enough concrete details."
                    ),
                },
            ),
        }

        client = TypeSafeClient(
            api_key=self.api_key,
            model=self.model,
        )

        response = client.system_one(
            state=state,
            questions=questions,
        )

        category_answer = response.choices["category"]
        specificity_answer = response.choices["specificity"]

        return {
            "category": category_answer.choice,
            "confidence": category_answer.confidence,
            "probabilities": category_answer.probabilities,

            "specificity": specificity_answer.choice,
            "specificity_confidence": (
                specificity_answer.confidence
            ),
            "specificity_probabilities": (
                specificity_answer.probabilities
            ),
        }
