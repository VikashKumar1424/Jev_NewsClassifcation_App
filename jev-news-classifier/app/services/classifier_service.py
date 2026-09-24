import time

from app.router.auto_router import AutoRouter
from app.router.route_models import ProcessingRoute
from app.services.jev_service import JevService
from app.services.gemini_service import GeminiService


class ClassifierService:

    def __init__(self):
        self.jev = JevService()
        self.gemini = GeminiService()
        self.router = AutoRouter()

    async def classify(self, text: str) -> dict:
        """
        Production classification flow.

        JEV classifies first.
        AutoRouter decides what should happen next.
        """

        start = time.perf_counter()

        # -----------------------------------------
        # 1. JEV classification
        # -----------------------------------------
        jev_result = await self.jev.classify(text)

        jev_latency_ms = (time.perf_counter() - start) * 1000
        jev_result["latency_ms"] = round(jev_latency_ms, 2)

        # -----------------------------------------
        # 2. Auto routing
        # -----------------------------------------
        route = self.router.decide(jev_result)

        # -----------------------------------------
        # 3. Extract JEV values
        # -----------------------------------------
        probabilities = jev_result["probabilities"]

        sorted_probabilities = sorted(
            probabilities.items(),
            key=lambda item: item[1],
            reverse=True,
        )

        top_category = sorted_probabilities[0][0]
        top_confidence = float(sorted_probabilities[0][1])

        if len(sorted_probabilities) > 1:
            second_category = sorted_probabilities[1][0]
            second_confidence = float(sorted_probabilities[1][1])
        else:
            second_category = "other"
            second_confidence = 0.0

        confidence_margin = (
            top_confidence - second_confidence
        )

        # -----------------------------------------
        # 4. Default processing path
        # -----------------------------------------
        processing_path = route.route.value
        summary = (
            f"Classified as {top_category} "
            f"with {top_confidence:.2%} confidence."
        )

        needs_human_review = route.needs_human_review

        # -----------------------------------------
        # 5. Gemini verification
        # -----------------------------------------
        if route.route == ProcessingRoute.JEV_THEN_GEMINI:

            try:
                gemini_result = await self.gemini.classify(text)

                gemini_category = gemini_result["category"]
                gemini_confidence = float(
                    gemini_result["confidence"]
                )

                processing_path = "jev_then_gemini"

                summary = (
                    f"JEV classified this as {top_category} "
                    f"({top_confidence:.2%}). "
                    f"Gemini classified it as "
                    f"{gemini_category} "
                    f"({gemini_confidence:.2%})."
                )

                # JEV and Gemini disagree
                if top_category != gemini_category:
                    needs_human_review = True

            except RuntimeError as exc:

                print()
                print("========== GEMINI FALLBACK ==========")
                print(f"Gemini unavailable: {exc}")
                print("Using JEV result.")
                print("======================================")
                print()

                # Gemini failure should NOT make /classify fail.
                processing_path = "jev_then_gemini_fallback"

                summary = (
                    f"JEV classified this as "
                    f"{top_category} "
                    f"({top_confidence:.2%}). "
                    f"Gemini verification was temporarily "
                    f"unavailable, so the JEV result is returned."
                )

                # Since Gemini verification was not completed,
                # flag this result for review.
                needs_human_review = True

        # -----------------------------------------
        # 6. Follow-up route
        # -----------------------------------------
        elif route.route == ProcessingRoute.ASK_FOLLOW_UP:

            processing_path = "jev_ambiguous"

            summary = (
                f"JEV detected ambiguity between "
                f"{route.options}."
            )

        # -----------------------------------------
        # 7. Human review route
        # -----------------------------------------
        elif route.route == ProcessingRoute.HUMAN_REVIEW:

            processing_path = "human_review"

            summary = (
                "The news could not be classified "
                "with sufficient confidence."
            )

        # -----------------------------------------
        # 8. JEV-only route
        # -----------------------------------------
        elif route.route == ProcessingRoute.JEV_ONLY:

            processing_path = "jev_only"

        # -----------------------------------------
        # 9. Final API response
        # -----------------------------------------
        return {
            "category": top_category,
            "confidence": top_confidence,

            "top_category": top_category,
            "top_confidence": top_confidence,

            "second_category": second_category,
            "second_confidence": second_confidence,

            "confidence_margin": confidence_margin,

            "probabilities": probabilities,

            "summary": summary,

            "needs_human_review": needs_human_review,

            "processing_path": processing_path,

            "specificity": jev_result["specificity"],
            "specificity_score": jev_result["specificity_score"],

            "decision_reason": route.reason,
        }

    async def compare(self, text: str) -> dict:
        """
        Benchmark endpoint.

        Runs JEV and Gemini independently.
        If Gemini is temporarily unavailable, return
        a structured comparison response instead of HTTP 500.
        """

        # -----------------------------------------
        # 1. JEV
        # -----------------------------------------
        jev_start = time.perf_counter()

        jev_result = await self.jev.classify(text)

        jev_latency_ms = (
            time.perf_counter() - jev_start
        ) * 1000

        jev_result["latency_ms"] = round(
            jev_latency_ms,
            2,
        )

        # -----------------------------------------
        # 2. Router
        # -----------------------------------------
        route = self.router.decide(jev_result)

        # -----------------------------------------
        # 3. Gemini
        # -----------------------------------------
        gemini_error = None
        gemini_result = None

        try:
            gemini_result = await self.gemini.classify(text)

        except RuntimeError as exc:
            gemini_error = str(exc)

            print()
            print("========== GEMINI COMPARISON ERROR ==========")
            print(f"Gemini unavailable: {gemini_error}")
            print("JEV result is still available.")
            print("==============================================")
            print()

        # -----------------------------------------
        # 4. JEV values
        # -----------------------------------------
        jev_category = jev_result["category"]

        jev_confidence = float(
            jev_result["confidence"]
        )

        # -----------------------------------------
        # 5. Gemini unavailable
        # -----------------------------------------
        if gemini_result is None:

            return {
                "text": text,

                "jev": {
                    "category": jev_category,
                    "confidence": jev_confidence,

                    "probabilities":
                        jev_result["probabilities"],

                    "specificity":
                        jev_result["specificity"],

                    "specificity_score":
                        jev_result["specificity_score"],

                    "questions":
                        jev_result["questions"],

                    "question_count":
                        jev_result["question_count"],

                    "execution_mode":
                        jev_result["execution_mode"],

                    "latency_ms":
                        jev_result["latency_ms"],
                },

                "gemini": {
                    "category": "unavailable",
                    "confidence": 0.0,
                    "reason": gemini_error or "Gemini unavailable.",
                    "latency_ms": 0.0,

                    "input_tokens": 0,
                    "output_tokens": 0,
                    "thought_tokens": 0,
                    "total_tokens": 0,

                    "input_cost_usd": 0.0,
                    "output_cost_usd": 0.0,
                    "total_cost_usd": 0.0,
                },

                "comparison": {
                    "same_category": False,
                    "confidence_difference": 0.0,
                    "category_match": "unavailable",

                    "jev_category":
                        jev_category,

                    "jev_confidence":
                        jev_confidence,

                    "gemini_category":
                        "unavailable",

                    "gemini_confidence":
                        0.0,

                    "latency_difference_ms":
                        0.0,
                },

                "routing": {
                    "route": route.route.value,
                    "reason": route.reason,

                    "needs_follow_up":
                        route.needs_follow_up,

                    "needs_human_review":
                        True,

                    "question":
                        route.question,

                    "options":
                        route.options,
                },
            }

        # -----------------------------------------
        # 6. Gemini available
        # -----------------------------------------
        gemini_category = gemini_result["category"]

        gemini_confidence = float(
            gemini_result["confidence"]
        )

        same_category = (
            jev_category == gemini_category
        )

        confidence_difference = abs(
            jev_confidence -
            gemini_confidence
        )

        latency_difference = abs(
            jev_result["latency_ms"] -
            gemini_result["latency_ms"]
        )

        # -----------------------------------------
        # 7. Normal comparison response
        # -----------------------------------------
        return {
            "text": text,

            "jev": {
                "category": jev_category,
                "confidence": jev_confidence,

                "probabilities":
                    jev_result["probabilities"],

                "specificity":
                    jev_result["specificity"],

                "specificity_score":
                    jev_result["specificity_score"],

                "questions":
                    jev_result["questions"],

                "question_count":
                    jev_result["question_count"],

                "execution_mode":
                    jev_result["execution_mode"],

                "latency_ms":
                    jev_result["latency_ms"],
            },

            "gemini": gemini_result,

            "comparison": {
                "same_category":
                    same_category,

                "confidence_difference":
                    confidence_difference,

                "category_match": (
                    "match"
                    if same_category
                    else "mismatch"
                ),

                "jev_category":
                    jev_category,

                "jev_confidence":
                    jev_confidence,

                "gemini_category":
                    gemini_category,

                "gemini_confidence":
                    gemini_confidence,

                "latency_difference_ms":
                    round(
                        latency_difference,
                        2,
                    ),
            },

            "routing": {
                "route":
                    route.route.value,

                "reason":
                    route.reason,

                "needs_follow_up":
                    route.needs_follow_up,

                "needs_human_review":
                    route.needs_human_review,

                "question":
                    route.question,

                "options":
                    route.options,
            },
        }