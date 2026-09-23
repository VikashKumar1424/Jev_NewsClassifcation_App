from app.services.gemini_service import GeminiService
from app.services.jev_service import JevService


class ClassifierService:

    HIGH_CONFIDENCE = 0.90
    MEDIUM_CONFIDENCE = 0.60

    SPECIFICITY_THRESHOLD = 0.50

    def __init__(self):

        self.jev = JevService()
        self.gemini = GeminiService()

    async def classify(
        self,
        text: str
    ) -> dict:

        # -----------------------------------------
        # Step 1: JEV classification
        # -----------------------------------------

        decision = await self.jev.classify(text)

        category = decision["category"]

        confidence = decision["confidence"]

        probabilities = decision["probabilities"]

        specificity = decision["specificity"]

        specificity_score = (
            decision["specificity_score"]
        )

        # -----------------------------------------
        # Step 2: Check specificity
        # -----------------------------------------

        is_specific = (
            specificity_score
            >= self.SPECIFICITY_THRESHOLD
        )

        # -----------------------------------------
        # Step 3: Not specific
        # -----------------------------------------

        if not is_specific:

            summary = await self.gemini.summarize(
                text
            )

            return {

                "category": category,

                "confidence": confidence,

                "probabilities": probabilities,

                "summary": summary,

                "needs_human_review": True,

                "processing_path": (
                    "jev_specificity_check_then_gemini"
                ),

                "specificity": specificity,

                "specificity_score": (
                    specificity_score
                ),
            }

        # -----------------------------------------
        # Step 4: High confidence
        # -----------------------------------------

        if confidence >= self.HIGH_CONFIDENCE:

            summary = (
                "High-confidence JEV classification."
            )

            processing_path = "jev_only"

            needs_human_review = False

        # -----------------------------------------
        # Step 5: Medium confidence
        # -----------------------------------------

        elif confidence >= self.MEDIUM_CONFIDENCE:

            summary = await self.gemini.summarize(
                text
            )

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = False

        # -----------------------------------------
        # Step 6: Low confidence
        # -----------------------------------------

        else:

            summary = await self.gemini.summarize(
                text
            )

            processing_path = (
                "jev_then_gemini"
            )

            needs_human_review = True

        # -----------------------------------------
        # Final response
        # -----------------------------------------

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

            "specificity_score": (
                specificity_score
            ),
        }