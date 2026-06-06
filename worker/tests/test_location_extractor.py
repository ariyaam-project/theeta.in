import os
import types
import unittest
from unittest.mock import patch

os.environ["POLL_ENABLED"] = "false"

from app.config import Settings
from app.location_extractor import LocationExtractor
from app.models import EvidenceQuote, LocationExtraction, ReelComment, ReelEvidence


SAMPLE_REEL_URL = "https://www.instagram.com/reel/DZPMkmLiu9n/"
SAMPLE_EVIDENCE = ReelEvidence(
    caption=(
        "Mollywood times my honest review ❤️\n\n"
        "@naslenofficial @abhinavsnayak @binupappu @vineeth84 @sharaf_u_dheen \n\n"
        "#review #maheshmimics #mollywoodtimes #naslen #viral"
    ),
    uploader="Mahesh Kunjumon",
    channel="mahesh_mimics",
    comments=[
        ReelComment(text="Review പറയാൻ വന്നാൽ പറഞ്ഞിട്ട് പോണം അയിന്റെ ഇടയിൽ കൂടെ മിമിക്രി ഇടല്ലേ 😂😍"),
        ReelComment(text="Sathyam parayaaalo eee padam ishtaaayillla 😕😕"),
        ReelComment(text="mimicry + movie review 📈🔥"),
    ],
)


class LocationExtractorTests(unittest.TestCase):
    @patch("app.location_extractor.OpenAI")
    def test_movie_review_reel_needs_transcription_when_text_has_no_location(self, openai):
        expected = LocationExtraction(
            restaurant_name=None,
            branch_name=None,
            area=None,
            city=None,
            state=None,
            country=None,
            suggested_address=None,
            suggested_lat=None,
            suggested_lng=None,
            suggested_location_confidence=0,
            landmarks=[],
            evidence=[
                EvidenceQuote(source="caption", text="Mollywood times my honest review ❤️"),
                EvidenceQuote(source="caption", text="#mollywoodtimes #naslen #viral"),
            ],
            confidence=0.05,
            needs_transcription=True,
        )
        parse = openai.return_value.responses.parse
        parse.return_value = types.SimpleNamespace(output_parsed=expected)

        result = LocationExtractor(Settings(openai_api_key="test-key")).extract(SAMPLE_EVIDENCE)

        self.assertIsNone(result.restaurant_name)
        self.assertEqual(result.landmarks, [])
        self.assertIsNone(result.suggested_address)
        self.assertIsNone(result.suggested_lat)
        self.assertIsNone(result.suggested_lng)
        self.assertLess(result.confidence, 0.2)
        self.assertTrue(result.needs_transcription)

        request = parse.call_args.kwargs
        self.assertEqual(request["text_format"], LocationExtraction)
        user_content = request["input"][1]["content"]
        self.assertIn("Mollywood times my honest review", user_content)
        self.assertIn("mimicry + movie review", user_content)
        self.assertIn("Transcript:\n(not available)", user_content)
        self.assertIn("suggested_address", request["input"][0]["content"])

    @unittest.skipUnless(
        os.getenv("RUN_LIVE_AI_EXTRACTION_TEST") == "1" and os.getenv("OPENAI_API_KEY"),
        "Set RUN_LIVE_AI_EXTRACTION_TEST=1 and OPENAI_API_KEY to run the live Instagram/OpenAI test.",
    )
    def test_live_sample_reel_text_extraction_needs_transcription(self):
        from app.instagram_extractor import extract_evidence

        settings = Settings(
            openai_api_key=os.environ["OPENAI_API_KEY"],
            openai_location_model=os.getenv("OPENAI_LOCATION_MODEL", "gpt-5.4-mini"),
            max_location_comments=30,
        )

        evidence = extract_evidence(SAMPLE_REEL_URL, settings)
        result = LocationExtractor(settings).extract(evidence)

        self.assertIsNone(result.restaurant_name)
        self.assertIsNone(result.suggested_address)
        self.assertIsNone(result.suggested_lat)
        self.assertIsNone(result.suggested_lng)
        self.assertLess(result.confidence, 0.2)
        self.assertTrue(result.needs_transcription)


if __name__ == "__main__":
    unittest.main()
