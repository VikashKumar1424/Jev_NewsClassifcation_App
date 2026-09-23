import os

from dotenv import load_dotenv

from typesafe_sdk import (
    AsyncTypeSafeClient,
    Choice,
    Noul,
)


load_dotenv(".env", override=True)


class JevService:

    def __init__(self):

        api_key = os.getenv(
            "TYPESAFE_API_KEY"
        )

        if not api_key:
            raise RuntimeError(
                "TYPESAFE_API_KEY is not configured"
            )

        self.api_key = api_key

        self.model = "jev-latest"

    async def classify(
        self,
        text: str,
    ) -> dict:

        state = {
            "news": text
        }

        questions = {

            # -----------------------------------------
            # Category
            # -----------------------------------------

            "category": Choice(

                instructions=(
                    "Classify the news into exactly one "
                    "category."
                ),

                criteria={

                    "technology": (
                        "Technology, software, AI, computers, "
                        "devices, internet, cybersecurity, "
                        "digital products or technology companies."
                    ),

                    "business": (
                        "Companies, markets, finance, economy, "
                        "trade, investment, banking or business."
                    ),

                    "sports": (
                        "Sports, teams, players, matches, "
                        "tournaments, competitions or athletics."
                    ),

                    "politics": (
                        "Government, elections, politicians, "
                        "legislation, public policy or political events."
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
                        "that does not belong to the other categories."
                    ),
                },
            ),

            # -----------------------------------------
            # Specificity
            # -----------------------------------------

            "specificity": Noul(

                instructions=(
                    "Does this news contain enough concrete "
                    "information to understand what actually "
                    "happened? Return a high value when the news "
                    "describes a concrete event, subject, "
                    "organization, person, product, discovery, "
                    "decision or situation. Return a low value "
                    "when the text is vague, generic, incomplete, "
                    "hypothetical, ambiguous, or does not provide "
                    "enough concrete details."
                ),
            ),
        }

        async with AsyncTypeSafeClient(
            api_key=self.api_key,
            model=self.model,
        ) as client:

            response = await client.system_one(
                state=state,
                questions=questions,
            )

        # -----------------------------------------
        # Extract JEV responses
        # -----------------------------------------

        category_answer = (
            response.choices["category"]
        )

        specificity_answer = (
            response.nouls["specificity"]
        )

        specificity_score = (
            specificity_answer.noul
        )

        if specificity_score >= 0.50:
            specificity = "specific"
        else:
            specificity = "not_specific"

        return {

            "category": category_answer.choice,

            "confidence": category_answer.confidence,

            "probabilities": (
                category_answer.probabilities
            ),

            "specificity": specificity,

            "specificity_score": specificity_score,
        }