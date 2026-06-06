import os
import unittest

os.environ["POLL_ENABLED"] = "false"

from fastapi.testclient import TestClient

from app.main import app


class MainTests(unittest.TestCase):
    def test_health_is_public(self):
        with TestClient(app) as client:
            self.assertEqual(client.get("/health").json(), {"ok": True})

    def test_run_once_requires_service_token(self):
        with TestClient(app) as client:
            self.assertEqual(client.post("/v1/jobs/run-once").status_code, 401)


if __name__ == "__main__":
    unittest.main()
