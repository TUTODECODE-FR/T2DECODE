#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
"""Unit tests for volunteer claim parser + anti-collision (no network)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from volunteer_claim_apply import (  # noqa: E402
    Claim,
    IssueSnapshot,
    author_mismatch,
    bot_fingerprint,
    claim_iid_from_mr,
    claimable_errors,
    claimable_warnings,
    collision_message,
    desired_labels,
    discover_claim_files,
    is_allowed_claim_path,
    is_stale_mr,
    lock_holder,
    other_active_claims,
    parse_claim_file_username,
    parse_prendre_branch,
    parse_prendre_title,
    resolve_claims,
    scope_violations,
)


class ParseTitleTests(unittest.TestCase):
    def test_exact(self) -> None:
        self.assertEqual(parse_prendre_title("prendre #42"), 42)

    def test_case_and_spaces(self) -> None:
        self.assertEqual(parse_prendre_title("  Prendre #7 "), 7)

    def test_rejects_noise(self) -> None:
        self.assertIsNone(parse_prendre_title("feat: prendre #42 later"))
        self.assertIsNone(parse_prendre_title("prendre 42"))
        self.assertIsNone(parse_prendre_title(""))


class ParseBranchTests(unittest.TestCase):
    def test_branch(self) -> None:
        self.assertEqual(parse_prendre_branch("volunteer/prendre-12"), 12)
        self.assertEqual(parse_prendre_branch("refs/heads/volunteer/prendre-3"), 3)

    def test_reject(self) -> None:
        self.assertIsNone(parse_prendre_branch("feature/prendre-12"))


class ParseClaimFileTests(unittest.TestCase):
    def test_bare_username(self) -> None:
        self.assertEqual(parse_claim_file_username("alice\n"), "alice")

    def test_at_username(self) -> None:
        self.assertEqual(parse_claim_file_username("@bob"), "bob")

    def test_keyed(self) -> None:
        self.assertEqual(
            parse_claim_file_username("# comment\nusername: carol\n"),
            "carol",
        )

    def test_gitlab_key(self) -> None:
        self.assertEqual(parse_claim_file_username("GitLab: dave"), "dave")

    def test_empty(self) -> None:
        self.assertIsNone(parse_claim_file_username("# only comment\n\n"))


class DiscoverAndResolveTests(unittest.TestCase):
    def test_discover_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            claims = root / "volunteer" / "claims"
            claims.mkdir(parents=True)
            (claims / "9.md").write_text("alice\n", encoding="utf-8")
            (claims / "README.md").write_text("ignore\n", encoding="utf-8")
            found = discover_claim_files(root)
            self.assertEqual(len(found), 1)
            self.assertEqual(found[0].iid, 9)
            self.assertEqual(found[0].username, "alice")

    def test_resolve_from_title_and_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            claims = root / "volunteer" / "claims"
            claims.mkdir(parents=True)
            (claims / "42.md").write_text("username: eve\n", encoding="utf-8")
            resolved = resolve_claims(
                mr_title="prendre #42",
                root=root,
            )
            self.assertEqual(len(resolved), 1)
            self.assertEqual(resolved[0].username, "eve")

    def test_title_fallback_username(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            resolved = resolve_claims(
                mr_title="prendre #5",
                root=root,
                fallback_username="frank",
            )
            self.assertEqual(len(resolved), 1)
            self.assertEqual(resolved[0].iid, 5)
            self.assertEqual(resolved[0].username, "frank")

    def test_bad_claim_file_raises(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            claims = root / "volunteer" / "claims"
            claims.mkdir(parents=True)
            (claims / "1.md").write_text("# empty of user\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                discover_claim_files(root)


class CollisionTests(unittest.TestCase):
    def test_free_issue_ok(self) -> None:
        claim = Claim(iid=1, username="alice", source="t")
        issue = IssueSnapshot(iid=1, assignees=[], labels=["benevolat"], state="opened")
        self.assertIsNone(collision_message(claim, issue))

    def test_same_assignee_idempotent(self) -> None:
        claim = Claim(iid=1, username="alice", source="t")
        issue = IssueSnapshot(
            iid=1, assignees=["alice"], labels=["en-cours"], state="opened"
        )
        self.assertIsNone(collision_message(claim, issue))

    def test_different_assignee_blocked(self) -> None:
        claim = Claim(iid=1, username="alice", source="t")
        issue = IssueSnapshot(
            iid=1, assignees=["bob"], labels=["en-cours"], state="opened"
        )
        msg = collision_message(claim, issue)
        self.assertIsNotNone(msg)
        assert msg is not None
        self.assertIn("@bob", msg)
        self.assertIn("@alice", msg)

    def test_desired_labels(self) -> None:
        labels = desired_labels(["benevolat", "libre", "wishlist"])
        self.assertNotIn("libre", [l.lower() for l in labels])
        self.assertTrue(any(l.lower() == "en-cours" for l in labels))
        self.assertIn("benevolat", labels)


class ClaimableTests(unittest.TestCase):
    def test_closed_ticket_rejected(self) -> None:
        claim = Claim(iid=2, username="alice", source="t")
        issue = IssueSnapshot(iid=2, assignees=[], labels=[], state="closed")
        errors = claimable_errors(claim, issue)
        self.assertTrue(any("fermé" in e for e in errors))

    def test_en_cours_label_blocks_stranger(self) -> None:
        claim = Claim(iid=3, username="alice", source="t")
        issue = IssueSnapshot(iid=3, assignees=[], labels=["en-cours"], state="opened")
        errors = claimable_errors(claim, issue)
        self.assertTrue(any("en-cours" in e for e in errors))

    def test_missing_libre_is_warning_not_error(self) -> None:
        claim = Claim(iid=4, username="alice", source="t")
        issue = IssueSnapshot(iid=4, assignees=[], labels=["benevolat"], state="opened")
        self.assertEqual(claimable_errors(claim, issue), [])
        warnings = claimable_warnings(claim, issue)
        self.assertTrue(any("libre" in w for w in warnings))

    def test_missing_benevolat_warns(self) -> None:
        claim = Claim(iid=5, username="alice", source="t")
        issue = IssueSnapshot(iid=5, assignees=[], labels=["libre"], state="opened")
        warnings = claimable_warnings(claim, issue)
        self.assertTrue(any("benevolat" in w for w in warnings))


class ScopeTests(unittest.TestCase):
    def test_allowed_paths(self) -> None:
        self.assertTrue(is_allowed_claim_path("volunteer/claims/42.md"))
        self.assertTrue(is_allowed_claim_path("VOLUNTEER_BOARD.md"))
        self.assertTrue(is_allowed_claim_path("CONTRIBUTORS.md"))

    def test_rejected_paths(self) -> None:
        self.assertFalse(is_allowed_claim_path("lib/main.dart"))
        self.assertFalse(is_allowed_claim_path(".gitlab-ci.yml"))
        self.assertFalse(is_allowed_claim_path("volunteer/claims/README.md"))
        self.assertFalse(is_allowed_claim_path("scripts/volunteer_claim_apply.py"))

    def test_scope_violations_lists_bad_only(self) -> None:
        bad = scope_violations(["volunteer/claims/1.md", "lib/x.dart", "", "pubspec.yaml"])
        self.assertEqual(bad, ["lib/x.dart", "pubspec.yaml"])


def _mr(iid: int, title: str, author: str = "alice", **kw) -> dict:
    mr = {
        "iid": iid,
        "title": title,
        "source_branch": f"volunteer/prendre-{iid}",
        "author": {"username": author},
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    mr.update(kw)
    return mr


class MrLockTests(unittest.TestCase):
    def test_claim_iid_from_mr(self) -> None:
        self.assertEqual(claim_iid_from_mr(_mr(10, "prendre #42")), 42)
        self.assertEqual(
            claim_iid_from_mr(_mr(11, "whatever", source_branch="volunteer/prendre-7")),
            7,
        )
        self.assertIsNone(
            claim_iid_from_mr(_mr(12, "fix bug", source_branch="fix/bug"))
        )

    def test_lock_holder_oldest_mr_wins(self) -> None:
        mrs = [_mr(30, "prendre #42", "bob"), _mr(25, "prendre #42", "alice")]
        holder = lock_holder(mrs, 42)
        self.assertIsNotNone(holder)
        self.assertEqual(holder["iid"], 25)

    def test_lock_holder_none_when_free(self) -> None:
        self.assertIsNone(lock_holder([_mr(25, "prendre #42")], 99))

    def test_other_active_claims_excludes_self_mr(self) -> None:
        mrs = [_mr(25, "prendre #42", "alice"), _mr(26, "prendre #43", "alice")]
        active = other_active_claims(mrs, "alice", exclude_mr_iid=25)
        self.assertEqual([m["iid"] for m in active], [26])

    def test_other_active_claims_ignores_others(self) -> None:
        mrs = [_mr(25, "prendre #42", "bob")]
        self.assertEqual(other_active_claims(mrs, "alice", exclude_mr_iid=None), [])

    def test_author_mismatch(self) -> None:
        claim = Claim(iid=1, username="alice", source="t")
        self.assertIsNone(author_mismatch(claim, "Alice"))
        self.assertIsNone(author_mismatch(claim, ""))
        self.assertIsNotNone(author_mismatch(claim, "mallory"))

    def test_stale_mr(self) -> None:
        now = datetime.now(timezone.utc)
        fresh = _mr(1, "prendre #1")
        old = _mr(
            2,
            "prendre #2",
            updated_at=(now - timedelta(days=15)).isoformat(),
        )
        self.assertFalse(is_stale_mr(fresh, now=now, days=14))
        self.assertTrue(is_stale_mr(old, now=now, days=14))
        self.assertFalse(is_stale_mr({"updated_at": "garbage"}, now=now, days=14))

    def test_bot_fingerprint_stable(self) -> None:
        self.assertEqual(bot_fingerprint("abc"), bot_fingerprint("abc"))
        self.assertNotEqual(bot_fingerprint("abc"), bot_fingerprint("abd"))


if __name__ == "__main__":
    unittest.main()
