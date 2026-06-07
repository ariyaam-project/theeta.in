import os
import unittest
from unittest.mock import MagicMock, patch

os.environ["POLL_ENABLED"] = "false"

from app.comment_analyzer import CommentAnalyzer
from app.config import Settings
from app.models import CommentAnalysis, ReelComment, ReelEvidence


class CommentAnalyzerTests(unittest.TestCase):
    def setUp(self):
        self.settings = Settings(poll_enabled=False, openai_api_key="test")

    def test_requires_api_key(self):
        with self.assertRaises(RuntimeError):
            CommentAnalyzer(Settings(poll_enabled=False, openai_api_key=None))

    @patch("app.comment_analyzer.OpenAI")
    def test_no_comments_short_circuits_without_calling_llm(self, openai_cls):
        analyzer = CommentAnalyzer(self.settings)
        result = analyzer.analyze(ReelEvidence(caption="Cafe One"))

        self.assertIsInstance(result, CommentAnalysis)
        self.assertEqual(result.analyzed_count, 0)
        openai_cls.return_value.responses.parse.assert_not_called()

    @patch("app.comment_analyzer.OpenAI")
    def test_parses_comments_via_llm(self, openai_cls):
        parsed = CommentAnalysis(analyzed_count=2, positive_count=2, sentiment_score=0.8)
        response = MagicMock()
        response.output_parsed = parsed
        openai_cls.return_value.responses.parse.return_value = response

        analyzer = CommentAnalyzer(self.settings)
        result = analyzer.analyze(
            ReelEvidence(
                caption="Cafe One",
                comments=[ReelComment(text="amazing"), ReelComment(text="loved it")],
            )
        )

        openai_cls.return_value.responses.parse.assert_called_once()
        self.assertEqual(result.positive_count, 2)
        self.assertEqual(result.sentiment_score, 0.8)


if __name__ == "__main__":
    unittest.main()
