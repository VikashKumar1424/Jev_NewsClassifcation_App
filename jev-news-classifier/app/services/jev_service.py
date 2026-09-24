import os
import time

from dotenv import load_dotenv
from typesafe_sdk import AsyncTypeSafeClient, Choice, Noul

load_dotenv(".env", override=True)


class JevService:

    def __init__(self):

        api_key = os.getenv("TYPESAFE_API_KEY")

        if not api_key:
            raise RuntimeError(
                "TYPESAFE_API_KEY is not configured"
            )

        self.api_key = api_key
        self.model = "jev-latest"

    async def classify(self, text: str) -> dict:

        state = {
            "news": text
        }

        # -----------------------------------------
        # MULTIPLE JEV QUESTIONS
        # -----------------------------------------

        questions = {

            "category": Choice(
                instructions=(
                    "Classify the news into exactly "
                    "one category."
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
                        "A specific understandable news topic that "
                        "does not belong to the other categories."
                    ),
                },
            ),

            # Question 2
            "specificity": Noul(
                instructions=(
                    "Does this news contain enough concrete "
                    "information to understand what actually happened?"
                ),
            ),

            # Question 3
            "is_sports": Noul(
                instructions=(
                    "Is this news primarily about sports, "
                    "sporting events, players, teams or competitions?"
                ),
            ),

            # Question 4
            "is_business": Noul(
                instructions=(
                    "Is this news primarily about business, "
                    "companies, markets, finance or the economy?"
                ),
            ),

            # Question 5
            "is_technology": Noul(
                instructions=(
                    "Is this news primarily about technology, "
                    "software, AI, computers, devices or cybersecurity?"
                ),
            ),

            # Question 6
            "is_politics": Noul(
                instructions=(
                    "Is this news primarily about government, "
                    "politics, elections, legislation or public policy?"
                ),
            ),
        }

        # -----------------------------------------
        # LATENCY
        # -----------------------------------------

        start_time = time.perf_counter()

        async with AsyncTypeSafeClient(
            api_key=self.api_key,
            model=self.model,
        ) as client:

            response = await client.system_one(
                state=state,
                questions=questions,
            )

        latency_ms = (
            time.perf_counter() - start_time
        ) * 1000

        # -----------------------------------------
        # RESULTS
        # -----------------------------------------

        category_answer = (
            response.choices["category"]
        )

        specificity_answer = (
            response.nouls["specificity"]
        )

        specificity_score = float(
            specificity_answer.noul
        )

        # Additional JEV questions

        is_sports = float(
            response.nouls["is_sports"].noul
        )

        is_business = float(
            response.nouls["is_business"].noul
        )

        is_technology = float(
            response.nouls["is_technology"].noul
        )

        is_politics = float(
            response.nouls["is_politics"].noul
        )

        specificity = (
            "specific"
            if specificity_score >= 0.50
            else "not_specific"
        )

        result = {

            "category": category_answer.choice,

            "confidence": float(
                category_answer.confidence
            ),

            "probabilities": dict(
                category_answer.probabilities
            ),

            "specificity": specificity,

            "specificity_score": specificity_score,

            # Multiple question results
            "questions": {
                "category": category_answer.choice,
                "specificity": specificity_score,
                "is_sports": is_sports,
                "is_business": is_business,
                "is_technology": is_technology,
                "is_politics": is_politics,
            },

            # Performance
            "latency_ms": round(
                latency_ms,
                2,
            ),

            "question_count": len(questions),

            "execution_mode": "system_one",
        }

        print()
        print("========== JEV RESULT ==========")
        print(result)
        print("================================")
        print()

        return result