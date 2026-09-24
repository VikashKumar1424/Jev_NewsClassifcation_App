from app.router.route_models import (
    ProcessingRoute,
    RouteDecision,
)


class AutoRouter:

    HIGH_CONFIDENCE = 0.90
    MEDIUM_CONFIDENCE = 0.60

    SPECIFICITY_THRESHOLD = 0.50
    MIN_MARGIN = 0.15

    def decide(
        self,
        jev_result: dict,
    ) -> RouteDecision:

        confidence = float(
            jev_result["confidence"]
        )

        specificity_score = float(
            jev_result["specificity_score"]
        )

        probabilities = jev_result[
            "probabilities"
        ]

        # ------------------------------------------------
        # Sort probabilities
        # ------------------------------------------------

        sorted_probabilities = sorted(
            probabilities.items(),
            key=lambda item: item[1],
            reverse=True,
        )

        top_category = (
            sorted_probabilities[0][0]
        )

        top_confidence = float(
            sorted_probabilities[0][1]
        )

        if len(sorted_probabilities) > 1:

            second_category = (
                sorted_probabilities[1][0]
            )

            second_confidence = float(
                sorted_probabilities[1][1]
            )

        else:

            second_category = "other"
            second_confidence = 0.0

        margin = (
            top_confidence
            - second_confidence
        )

        # ------------------------------------------------
        # 1. Not specific
        # ------------------------------------------------

        if (
            specificity_score
            < self.SPECIFICITY_THRESHOLD
        ):

            return RouteDecision(
                route=ProcessingRoute.HUMAN_REVIEW,

                reason=(
                    "News is not specific enough "
                    "for reliable classification."
                ),

                needs_human_review=True,
            )

        # ------------------------------------------------
        # 2. Ambiguous
        # ------------------------------------------------

        if margin < self.MIN_MARGIN:

            candidates = [
                item[0]
                for item in sorted_probabilities[:2]
            ]

            return RouteDecision(
                route=ProcessingRoute.ASK_FOLLOW_UP,

                reason=(
                    "Top two JEV categories "
                    "are too close."
                ),

                needs_follow_up=True,

                question=(
                    "What is the primary "
                    "focus of this news?"
                ),

                options=candidates,
            )

        # ------------------------------------------------
        # 3. High confidence
        # ------------------------------------------------

        if (
            top_confidence
            >= self.HIGH_CONFIDENCE
        ):

            return RouteDecision(
                route=ProcessingRoute.JEV_ONLY,

                reason=(
                    "JEV has high confidence "
                    "and sufficient category "
                    "separation."
                ),
            )

        # ------------------------------------------------
        # 4. Medium confidence
        # ------------------------------------------------

        if (
            top_confidence
            >= self.MEDIUM_CONFIDENCE
        ):

            return RouteDecision(
                route=ProcessingRoute.JEV_THEN_GEMINI,

                reason=(
                    "JEV confidence is moderate; "
                    "Gemini verification is required."
                ),
            )

        # ------------------------------------------------
        # 5. Low confidence
        # ------------------------------------------------

        return RouteDecision(
            route=ProcessingRoute.HUMAN_REVIEW,

            reason=(
                "JEV confidence is too low "
                "for automatic classification."
            ),

            needs_human_review=True,
        )