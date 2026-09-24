from app.services.jev_service import JevService
from app.services.gemini_service import GeminiService


class ClassifierService:

    HIGH_CONFIDENCE = 0.90
    MEDIUM_CONFIDENCE = 0.60
    SPECIFICITY_THRESHOLD = 0.50
    MIN_CONFIDENCE_MARGIN = 0.15

    def __init__(self):
        self.jev = JevService()
        self.gemini = GeminiService()

    async def classify(self, text: str) -> dict:

        # ---------------------------------------------------------
        # 1. JEV classification
        # ---------------------------------------------------------
        jev_result = await self.jev.classify(text)

        category = jev_result["category"]
        confidence = float(jev_result["confidence"])
        probabilities = jev_result["probabilities"]

        # ---------------------------------------------------------
        # 2. Top 1 / Top 2
        # ---------------------------------------------------------
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

        # ---------------------------------------------------------
        # 3. Specificity
        # ---------------------------------------------------------
        specificity = jev_result["specificity"]
        specificity_score = float(
            jev_result["specificity_score"]
        )

        # ---------------------------------------------------------
        # 4. Decision reason
        # ---------------------------------------------------------
        decision_reason = self._determine_decision_reason(
            confidence=top_confidence,
            confidence_margin=confidence_margin,
            specificity_score=specificity_score,
        )

        # ---------------------------------------------------------
        # 5. Decide processing path
        # ---------------------------------------------------------
        summary = ""
        needs_human_review = False

        # Case 1:
        # News is not specific
        if specificity_score < self.SPECIFICITY_THRESHOLD:

            summary = await self.gemini.summarize(text)

            processing_path = (
                "jev_specificity_check_then_gemini"
            )

            needs_human_review = True

        # Case 2:
        # High confidence + good separation
        elif (
            top_confidence >= self.HIGH_CONFIDENCE
            and confidence_margin >= self.MIN_CONFIDENCE_MARGIN
        ):

            summary = (
                "JEV classification completed with high confidence."
            )

            processing_path = "jev_only"

        # Case 3:
        # Medium confidence OR ambiguous top two
        elif (
            top_confidence >= self.MEDIUM_CONFIDENCE
            or confidence_margin < self.MIN_CONFIDENCE_MARGIN
        ):

            summary = await self.gemini.summarize(text)

            processing_path = "jev_then_gemini"

        # Case 4:
        # Low confidence
        else:

            summary = await self.gemini.summarize(text)

            processing_path = "jev_then_gemini"

            needs_human_review = True

        # ---------------------------------------------------------
        # 6. Final response
        # ---------------------------------------------------------
        result = {
            "category": category,
            "confidence": confidence,

            "top_category": top_category,
            "top_confidence": top_confidence,

            "second_category": second_category,
            "second_confidence": second_confidence,

            "confidence_margin": confidence_margin,

            "probabilities": probabilities,

            "summary": summary,

            "needs_human_review": needs_human_review,

            "processing_path": processing_path,

            "specificity": specificity,
            "specificity_score": specificity_score,

            "decision_reason": decision_reason,
        }

        print("\n========== CLASSIFIER RESULT ==========")
        print(result)
        print("=======================================\n")

        return result

    # -------------------------------------------------------------
    # Decision reason
    # -------------------------------------------------------------
    def _determine_decision_reason(
        self,
        confidence: float,
        confidence_margin: float,
        specificity_score: float,
    ) -> str:

        if specificity_score < self.SPECIFICITY_THRESHOLD:
            return "not_specific"

        if (
            confidence >= self.HIGH_CONFIDENCE
            and confidence_margin >= self.MIN_CONFIDENCE_MARGIN
        ):
            return "high_confidence_specific"

        if confidence_margin < self.MIN_CONFIDENCE_MARGIN:
            return "ambiguous_top_two"

        if confidence >= self.MEDIUM_CONFIDENCE:
            return "medium_confidence"

        return "low_confidence"

    # -------------------------------------------------------------
    # JEV vs Gemini comparison
    # -------------------------------------------------------------
    async def compare(self, text: str) -> dict:

        # Run JEV
        jev_result = await self.jev.classify(text)

        # Run Gemini
        gemini_result = await self.gemini.classify(text)

        jev_category = jev_result["category"]
        gemini_category = gemini_result["category"]

        jev_confidence = float(
            jev_result["confidence"]
        )

        gemini_confidence = float(
            gemini_result["confidence"]
        )

        same_category = (
            jev_category == gemini_category
        )

        confidence_difference = abs(
            jev_confidence - gemini_confidence
        )

        category_match = (
            "match"
            if same_category
            else "mismatch"
        )

        result = {
            "text": text,

            "jev": {
                "category": jev_category,
                "confidence": jev_confidence,
                "probabilities": jev_result["probabilities"],
                "specificity": jev_result["specificity"],
                "specificity_score": jev_result[
                    "specificity_score"
                ],
            },

            "gemini": {
                "category": gemini_category,
                "confidence": gemini_confidence,
                "reason": gemini_result["reason"],
            },

            "comparison": {
                "same_category": same_category,
                "confidence_difference": confidence_difference,
                "category_match": category_match,

                "jev_category": jev_category,
                "jev_confidence": jev_confidence,

                "gemini_category": gemini_category,
                "gemini_confidence": gemini_confidence,

                "gemini_reason": gemini_result["reason"],
            },
        }

        print("\n========== JEV vs GEMINI ==========")
        print(result)
        print("===================================\n")

        return result