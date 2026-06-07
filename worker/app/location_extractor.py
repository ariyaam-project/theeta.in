from openai import OpenAI

from .config import Settings
from .models import LocationExtraction, ReelEvidence

SYSTEM_PROMPT = """Extract restaurant and location clues from Instagram reel evidence.
First decide if the reel is about food: a restaurant, cafe, street food, bakery, bar, dish, or eating-out experience.
Set is_food_related=false for anything not about a food spot (travel vlogs, comedy, products, fitness, news, memes, etc.).
When is_food_related=false, give a short rejection_reason and leave all location fields null/0.
Only continue extracting location details when is_food_related=true.
Return the most likely address, latitude, and longitude when the evidence is strong enough to identify one real place.
Coordinates and address are AI-suggested, so only fill suggested_address/suggested_lat/suggested_lng when the place is specific, not just a city or vague area.
If exact coordinates are uncertain, leave suggested_lat and suggested_lng null and explain confidence through suggested_location_confidence.
Do not invent a restaurant name not supported by evidence.
Comments can be jokes or unrelated; use them only when they contain concrete place clues.
Set needs_transcription=true when the restaurant and city/area cannot be identified confidently.
Evidence quotes must be short verbatim excerpts from the supplied text."""


class LocationExtractor:
    def __init__(self, config: Settings):
        if not config.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is required for location extraction")
        self.model = config.openai_location_model
        self.client = OpenAI(api_key=config.openai_api_key)

    def extract(self, evidence: ReelEvidence, transcript: str | None = None) -> LocationExtraction:
        comments = "\n".join(f"- {comment.text}" for comment in evidence.comments)
        input_text = (
            f"Caption:\n{evidence.caption or '(none)'}\n\n"
            f"Uploader/channel:\n{evidence.uploader or ''} / {evidence.channel or ''}\n\n"
            f"Comments:\n{comments or '(none)'}\n\n"
            f"Transcript:\n{transcript or '(not available)'}"
        )
        response = self.client.responses.parse(
            model=self.model,
            input=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": input_text},
            ],
            text_format=LocationExtraction,
        )
        if not response.output_parsed:
            raise RuntimeError("OpenAI returned no structured location extraction")
        return response.output_parsed
