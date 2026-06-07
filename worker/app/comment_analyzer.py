from openai import OpenAI

from .config import Settings
from .models import CommentAnalysis, ReelEvidence

SYSTEM_PROMPT = """You analyse the audience comments under an Instagram food reel.
Judge the crowd reaction, not the creator's caption.
Count how many comments are positive, negative, and neutral about the food/place
(ignore pure emoji, tags, and off-topic spam in the counts).
sentiment_score is the overall mood from -1 (very negative) to 1 (very positive).
common_praise and common_complaints are short phrases people actually repeat
(e.g. "great portions", "long wait", "overpriced"); leave empty if none.
Set sponsored_signal=true when comments suggest a paid/sponsored promo
("#ad", "collab", "promo", accusations of a paid review).
authenticity_note: one short line on how trustworthy the reaction looks.
verdict: one short sentence summarising what the comments say about the place."""


class CommentAnalyzer:
    def __init__(self, config: Settings):
        if not config.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is required for comment analysis")
        self.model = config.openai_location_model
        self.client = OpenAI(api_key=config.openai_api_key)

    def analyze(self, evidence: ReelEvidence) -> CommentAnalysis:
        comments = [c.text.strip() for c in evidence.comments if c.text and c.text.strip()]
        if not comments:
            return CommentAnalysis()

        joined = "\n".join(f"- {text}" for text in comments)
        input_text = (
            f"Caption (creator, context only):\n{evidence.caption or '(none)'}\n\n"
            f"Audience comments ({len(comments)}):\n{joined}"
        )
        response = self.client.responses.parse(
            model=self.model,
            input=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": input_text},
            ],
            text_format=CommentAnalysis,
        )
        result = response.output_parsed
        if not result:
            return CommentAnalysis(analyzed_count=len(comments))
        return result
