from app.services.gemini_service import GeminiService
from app.services.jev_service import JevService


class ClassifierService:

    # -----------------------------------------
    # Confidence thresholds
    # -----------------------------------------

    HIGH_CONFIDENCE = 0.90
    MEDIUM_CONFIDENCE = 0.60

    # -----------------------------------------
    # Specificity threshold
    # -----------------------------------------

    SPECIFICITY_THRESHOLD = 0.50

    # -----------------------------------------
    # Margin threshold
    # -----------------------------------------

    MIN_CONFIDENCE_MARGIN = 0.15

    def __init__(self):

        self.jev = JevService()
        self.gemini = GeminiService()

    async def classify(
        self,
        text: str,
    ) -> dict:

        # =========================================
        # STEP 1
        # JEV classification
        # =========================================

        decision = await self.jev.classify(
            text
        )

        category = decision["category"]

        confidence = decision["confidence"]

        probabilities = decision["probabilities"]

        specificity = decision["specificity"]

        specificity_score = (
            decision["specificity_score"]
        )

        # =========================================
        # STEP 2
        # Top-1 / Top-2
        # =========================================

        sorted_probabilities = sorted(
            probabilities.items(),
            key=lambda item: item[1],
            reverse=True,
        )

        # Safety check
        if len(sorted_probabilities) == 0:

            raise RuntimeError(
                "JEV returned no category probabilities."
            )

        # Top-1
        top_category, top_confidence = (
            sorted_probabilities[0]
        )

        # Top-2
        if len(sorted_probabilities) > 1:

            second_category, second_confidence = (
                sorted_probabilities[1]
            )

        else:

            second_category = "none"
            second_confidence = 0.0

        # =========================================
        # STEP 3
        # Confidence margin
        # =========================================

        confidence_margin = (
            top_confidence
            - second_confidence
        )

        # =========================================
        # STEP 4
        # Specificity
        # =========================================

        is_specific = (
            specificity_score
            >= self.SPECIFICITY_THRESHOLD
        )

        # =========================================
        # STEP 5
        # Decision reason
        # =========================================

        decision_reason = self._determine_decision_reason(
            confidence=confidence,
            confidence_margin=confidence_margin,
            is_specific=is_specific,
        )

        # =========================================
        # STEP 6
        # Routing
        # =========================================

        needs_human_review = False

        # -----------------------------------------
        # Not specific
        # -----------------------------------------

        if not is_specific:

            summary = (
                await self.gemini.summarize(text)
            )

            processing_path = (
                "jev_specificity_check_then_gemini"
            )

            needs_human_review = True

        # -----------------------------------------
        # High confidence AND strong margin
        # -----------------------------------------

        elif (
            confidence >= self.HIGH_CONFIDENCE
            and confidence_margin
            >= self.MIN_CONFIDENCE_MARGIN
        ):

            summary = (
                "High-confidence JEV classification."
            )

            processing_path = "jev_only"

            needs_human_review = False

        # -----------------------------------------
        # Medium confidence OR weak margin
        # -----------------------------------------

        elif (
            confidence >= self.MEDIUM_CONFIDENCE
            or confidence_margin
            < self.MIN_CONFIDENCE_MARGIN
        ):

            summary = (
                await self.gemini.summarize(text)
            )

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = False

        # -----------------------------------------
        # Low confidence
        # -----------------------------------------

        else:

            summary = (
                await self.gemini.summarize(text)
            )

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = True

        # =========================================
        # STEP 7
        # Final response
        # =========================================

        return {

            "category": category,

            "confidence": confidence,

            "top_category": top_category,

            "top_confidence": top_confidence,

            "second_category": second_category,

            "second_confidence": second_confidence,

            "confidence_margin": confidence_margin,

            "probabilities": probabilities,

            "summary": summary,

            "needs_human_review": (
                needs_human_review
            ),

            "processing_path": (
                processing_path
            ),

            "specificity": specificity,

            "specificity_score": (
                specificity_score
            ),

            "decision_reason": (
                decision_reason
            ),
        }

    # =============================================
    # Decision Reason
    # =============================================

    def _determine_decision_reason(
        self,
        confidence: float,
        confidence_margin: float,
        is_specific: bool,
    ) -> str:

        if not is_specific:

            return (
                "not_specific"
            )

        if (
            confidence >= self.HIGH_CONFIDENCE
            and confidence_margin
            >= self.MIN_CONFIDENCE_MARGIN
        ):

            return (
                "high_confidence_specific"
            )

        if (
            confidence_margin
            < self.MIN_CONFIDENCE_MARGIN
        ):

            return (
                "ambiguous_top_two"
            )

        if confidence >= self.MEDIUM_CONFIDENCE:

            return (
                "medium_confidence"
            )

        return (
            "low_confidence"
        )