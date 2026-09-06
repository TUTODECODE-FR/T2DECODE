#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
"""Unit tests for volunteer claim parser + anti-collision (no network)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))

from volunteer_claim_apply import (  # noqa: E402
    Claim,
    IssueSnapshot,
    collision_message,
    desired_labels,
    discover_claim_files,
    parse_claim_file_username,
    parse_prendre_branch,
    parse_prendre_title,
    resolve_claims,
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


if __name__ == "__main__":
    unittest.main()
