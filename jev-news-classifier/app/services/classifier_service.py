from app.services.gemini_service import GeminiService
from app.services.jev_service import JevService


class ClassifierService:

    HIGH_CONFIDENCE = 0.90
    MEDIUM_CONFIDENCE = 0.60

    def __init__(self):

        self.jev = JevService()
        self.gemini = GeminiService()

    async def classify(
        self,
        text: str
    ) -> dict:

        # =========================================
        # STEP 1: JEV
        # =========================================

        decision = await self.jev.classify(text)

        category = decision["category"]
        confidence = decision["confidence"]
        probabilities = decision["probabilities"]

        specificity = decision["specificity"]

        specificity_confidence = (
            decision["specificity_confidence"]
        )

        # =========================================
        # STEP 2: CHECK SPECIFICITY
        # =========================================

        is_specific = (
            specificity == "specific"
        )

        # =========================================
        # STEP 3: VAGUE / AMBIGUOUS NEWS
        # =========================================

        if not is_specific:

            summary = await self.gemini.summarize(text)

            return {
        "category": category,

        "confidence": min(
            confidence,
            specificity_confidence
        ),

        "probabilities": probabilities,

        "summary": summary,

        "needs_human_review": True,

        "processing_path": (
            "jev_ambiguity_check_then_gemini"
        ),

        "specificity": specificity,

        "specificity_confidence": (
            specificity_confidence
        ),

                "specificity": specificity,

                "specificity_confidence": (
                    specificity_confidence
                ),
            }

        # =========================================
        # STEP 4: HIGH CONFIDENCE
        # =========================================

        if confidence >= self.HIGH_CONFIDENCE:

            summary = (
                "High-confidence JEV classification."
            )

            processing_path = "jev_only"

            needs_human_review = False

        # =========================================
        # STEP 5: MEDIUM CONFIDENCE
        # =========================================

        elif confidence >= self.MEDIUM_CONFIDENCE:

            summary = await self.gemini.summarize(text)

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = False

        # =========================================
        # STEP 6: LOW CONFIDENCE
        # =========================================

        else:

            summary = await self.gemini.summarize(text)

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = True

        # =========================================
        # FINAL RESPONSE
        # =========================================

        return {

            "category": category,

            "confidence": confidence,

            "probabilities": probabilities,

            "summary": summary,

            "needs_human_review": (
                needs_human_review
            ),

            "processing_path": processing_path,

            "specificity": specificity,

            "specificity_confidence": (
                specificity_confidence
            ),
        }