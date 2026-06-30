import importlib.util
import unittest
from datetime import datetime, timezone
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("koenig-cron-driver.py")
SPEC = importlib.util.spec_from_file_location("koenig_cron_driver", MODULE_PATH)
cron = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(cron)


class CronDriverStaleGuardTests(unittest.TestCase):
    def setUp(self) -> None:
        self.orig_get_json = cron.get_json
        self.orig_fetch = cron.fetch_issue_details_and_comments
        self.orig_patch = cron.patch_issue_status

    def tearDown(self) -> None:
        cron.get_json = self.orig_get_json
        cron.fetch_issue_details_and_comments = self.orig_fetch
        cron.patch_issue_status = self.orig_patch

    def _issue(self, issue_id: str, status: str, updated_at: str, title: str, description: str = "", labels=None):
        return {
            "id": issue_id,
            "identifier": f"KOEA-{issue_id}",
            "status": status,
            "title": title,
            "description": description,
            "updatedAt": updated_at,
            "labels": labels or [],
        }

    def test_true_positive_cancels_stale_superseded_issue(self):
        now = datetime(2026, 5, 26, 12, 0, tzinfo=timezone.utc)
        stale = self._issue(
            "A",
            "blocked",
            "2026-05-26T02:00:00Z",
            "daily-synthesis backlog item",
            "for 2026-05-25",
        )
        superseder = self._issue(
            "B",
            "done",
            "2026-05-26T09:00:00Z",
            "daily-synthesis complete 2026-05-25",
            "evidence: vault/research/_daily/2026-05-25.md",
        )

        def fake_get_json(url, token, timeout=10):
            if "status=blocked" in url:
                return 200, {"issues": [stale]}
            if "status=done" in url:
                return 200, {"issues": [superseder]}
            if "status=in_review" in url:
                return 200, {"issues": []}
            return 200, {"issues": []}

        def fake_fetch(issue_id, token):
            if issue_id == "A":
                return stale, []
            if issue_id == "B":
                return superseder, []
            return None, []

        patched = []

        def fake_patch(issue_id, token, status, comment):
            patched.append((issue_id, status, comment))
            return 200, "ok"

        cron.get_json = fake_get_json
        cron.fetch_issue_details_and_comments = fake_fetch
        cron.patch_issue_status = fake_patch

        cron.run_daily_synthesis_stale_guard("board-token", now)

        self.assertEqual(len(patched), 1)
        issue_id, status, comment = patched[0]
        self.assertEqual(issue_id, "A")
        self.assertEqual(status, "cancelled")
        self.assertIn("[daily-synthesis-stale-guard]", comment)
        self.assertIn("superseded by KOEA-B", comment)
        self.assertIn("vault/research/_daily/2026-05-25.md", comment)
        self.assertIn("evaluated_at: 2026-05-26T12:00:00Z", comment)

    def test_non_stale_issue_is_not_cancelled(self):
        now = datetime(2026, 5, 26, 12, 0, tzinfo=timezone.utc)
        fresh = self._issue(
            "A",
            "blocked",
            "2026-05-26T11:00:00Z",
            "daily-synthesis for 2026-05-25",
        )

        def fake_get_json(url, token, timeout=10):
            if "status=blocked" in url:
                return 200, {"issues": [fresh]}
            return 200, {"issues": []}

        patched = []
        cron.get_json = fake_get_json
        cron.fetch_issue_details_and_comments = lambda issue_id, token: (fresh, [])
        cron.patch_issue_status = lambda *args, **kwargs: patched.append(args) or (200, "ok")

        cron.run_daily_synthesis_stale_guard("board-token", now)
        self.assertEqual(patched, [])

    def test_no_evidence_does_not_cancel_and_creates_triage(self):
        now = datetime(2026, 5, 26, 12, 0, tzinfo=timezone.utc)
        stale = self._issue("A", "blocked", "2026-05-26T01:00:00Z", "daily-synthesis 2026-05-25")
        superseder = self._issue("B", "done", "2026-05-26T09:00:00Z", "daily-synthesis 2026-05-25")

        def fake_get_json(url, token, timeout=10):
            if "status=blocked" in url:
                return 200, {"issues": [stale]}
            if "status=done" in url:
                return 200, {"issues": [superseder]}
            return 200, {"issues": []}

        def fake_fetch(issue_id, token):
            if issue_id == "A":
                return stale, []
            if issue_id == "B":
                return superseder, []
            return None, []

        patched = []
        cron.get_json = fake_get_json
        cron.fetch_issue_details_and_comments = fake_fetch
        cron.patch_issue_status = lambda issue_id, token, status, comment: patched.append((status, comment)) or (200, "ok")

        cron.run_daily_synthesis_stale_guard("board-token", now)
        self.assertEqual(len(patched), 1)
        self.assertEqual(patched[0][0], "blocked")
        self.assertIn("triage requested", patched[0][1])

    def test_ambiguous_multi_match_triages_once_per_24h(self):
        now = datetime(2026, 5, 26, 12, 0, tzinfo=timezone.utc)
        stale = self._issue("A", "blocked", "2026-05-26T01:00:00Z", "daily-synthesis 2026-05-25")
        s1 = self._issue("B", "done", "2026-05-26T09:00:00Z", "daily-synthesis 2026-05-25", "vault/research/_synthesis/a.md")
        s2 = self._issue("C", "in_review", "2026-05-26T09:00:00Z", "daily-synthesis 2026-05-25", "vault/research/_synthesis/b.md")
        comments = [{
            "createdAt": "2026-05-26T00:00:00Z",
            "comment": "[daily-synthesis-stale-guard] triage requested: prior ambiguity; evaluated_at: 2026-05-26T00:00:00Z",
        }]

        def fake_get_json(url, token, timeout=10):
            if "status=blocked" in url:
                return 200, {"issues": [stale]}
            if "status=done" in url:
                return 200, {"issues": [s1]}
            if "status=in_review" in url:
                return 200, {"issues": [s2]}
            return 200, {"issues": []}

        def fake_fetch(issue_id, token):
            if issue_id == "A":
                return stale, comments
            if issue_id == "B":
                return s1, []
            if issue_id == "C":
                return s2, []
            return None, []

        patched = []
        cron.get_json = fake_get_json
        cron.fetch_issue_details_and_comments = fake_fetch
        cron.patch_issue_status = lambda issue_id, token, status, comment: patched.append((issue_id, status, comment)) or (200, "ok")

        cron.run_daily_synthesis_stale_guard("board-token", now)
        self.assertEqual(patched, [])

    def test_no_same_cycle_superseder_does_not_cancel(self):
        now = datetime(2026, 5, 26, 12, 0, tzinfo=timezone.utc)
        stale = self._issue("A", "blocked", "2026-05-26T01:00:00Z", "daily-synthesis 2026-05-25")
        other_cycle = self._issue(
            "B",
            "done",
            "2026-05-26T09:00:00Z",
            "daily-synthesis 2026-05-24",
            "vault/research/_daily/2026-05-24.md",
        )

        def fake_get_json(url, token, timeout=10):
            if "status=blocked" in url:
                return 200, {"issues": [stale]}
            if "status=done" in url:
                return 200, {"issues": [other_cycle]}
            return 200, {"issues": []}

        def fake_fetch(issue_id, token):
            if issue_id == "A":
                return stale, []
            if issue_id == "B":
                return other_cycle, []
            return None, []

        patched = []
        cron.get_json = fake_get_json
        cron.fetch_issue_details_and_comments = fake_fetch
        cron.patch_issue_status = lambda issue_id, token, status, comment: patched.append((status, comment)) or (200, "ok")

        cron.run_daily_synthesis_stale_guard("board-token", now)
        self.assertEqual(len(patched), 1)
        self.assertEqual(patched[0][0], "blocked")
        self.assertIn("triage requested", patched[0][1])

    def test_label_based_candidate_detection_and_dedupe(self):
        issue = self._issue(
            "A",
            "blocked",
            "2026-05-26T01:00:00Z",
            "unrelated title",
            labels=[{"name": "RESEARCH-OPS"}],
        )

        def fake_get_json(url, token, timeout=10):
            if "q=daily-synthesis" in url:
                return 200, {"issues": [issue]}
            if "q=research" in url:
                return 200, {"issues": [issue]}
            if "q=synthesis" in url:
                return 200, {"issues": [issue]}
            return 200, {"issues": []}

        cron.get_json = fake_get_json
        found = cron.discover_daily_synthesis_candidates("board-token")
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0]["id"], "A")


if __name__ == "__main__":
    unittest.main()
