#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
"""Apply or validate volunteer « prendre #<iid> » claims.

Convention
----------
- Branch : ``volunteer/prendre-<iid>``
- Marker : ``volunteer/claims/<iid>.md`` containing the GitLab username
- MR title : ``prendre #<iid>`` (exact prefix match)

Modes
-----
- ``validate`` (MR pipeline) : fail if the target issue is already assigned
  to a *different* user (anti-collision). No mutation.
- ``apply`` (main after merge) : assign the issue to the claim author, add
  label ``en-cours``, remove ``libre`` if present. Idempotent.

Auth (first non-empty wins)
---------------------------
``PROJECT_ACCESS_TOKEN`` / ``GITLAB_TOKEN`` / ``CI_JOB_TOKEN``

Env (GitLab CI)
---------------
``CI_API_V4_URL``, ``CI_PROJECT_ID``, ``CI_MERGE_REQUEST_TITLE``,
``CI_COMMIT_MESSAGE``, ``CI_COMMIT_TITLE``, ``GITLAB_USER_LOGIN``,
``CI_COMMIT_REF_NAME``, ``CI_MERGE_REQUEST_SOURCE_BRANCH_NAME``
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

CLAIMS_DIR = Path("volunteer/claims")
TITLE_RE = re.compile(r"(?i)^\s*prendre\s+#(\d+)\b")
BRANCH_RE = re.compile(r"(?i)(?:^|/)volunteer/prendre-(\d+)(?:$|/)")
CLAIM_FILE_RE = re.compile(r"(?i)(?:^|/)volunteer/claims/(\d+)\.md$")
USERNAME_LINE_RE = re.compile(
    r"(?i)^(?:username\s*[:=]\s*|@)?([a-zA-Z0-9._-]{2,100})\s*$"
)
LABEL_EN_COURS = "en-cours"
LABEL_LIBRE = "libre"


@dataclass(frozen=True)
class Claim:
    iid: int
    username: str
    source: str  # file path, title, or branch


@dataclass
class IssueSnapshot:
    iid: int
    assignees: list[str]
    labels: list[str]
    state: str

    @property
    def primary_assignee(self) -> str | None:
        return self.assignees[0] if self.assignees else None


# ---------------------------------------------------------------------------
# Pure parsers (unit-tested)
# ---------------------------------------------------------------------------


def parse_prendre_title(title: str | None) -> int | None:
    if not title:
        return None
    m = TITLE_RE.match(title.strip())
    return int(m.group(1)) if m else None


def parse_prendre_branch(ref: str | None) -> int | None:
    if not ref:
        return None
    m = BRANCH_RE.search(ref.strip())
    return int(m.group(1)) if m else None


def parse_claim_file_username(content: str) -> str | None:
    """Extract GitLab username from a claim marker file."""
    for raw in content.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = USERNAME_LINE_RE.match(line)
        if m:
            return m.group(1)
        # "GitLab: alice" / "assignee: alice"
        m2 = re.match(
            r"(?i)^(?:gitlab|assignee|user)\s*[:=]\s*@?([a-zA-Z0-9._-]{2,100})\s*$",
            line,
        )
        if m2:
            return m2.group(1)
    return None


def claim_path_for_iid(iid: int, root: Path | None = None) -> Path:
    base = root or Path(".")
    return base / CLAIMS_DIR / f"{iid}.md"


def discover_claim_files(
    root: Path | None = None,
    *,
    only_iids: set[int] | None = None,
) -> list[Claim]:
    base = root or Path(".")
    claims_root = base / CLAIMS_DIR
    if not claims_root.is_dir():
        return []
    found: list[Claim] = []
    for path in sorted(claims_root.glob("*.md")):
        if path.name.startswith("."):
            continue
        stem = path.stem
        if not stem.isdigit():
            continue
        iid = int(stem)
        if only_iids is not None and iid not in only_iids:
            continue
        text = path.read_text(encoding="utf-8")
        user = parse_claim_file_username(text)
        if not user:
            raise ValueError(
                f"Claim file {path} has no GitLab username "
                "(expected a line like `alice` or `username: alice`)."
            )
        found.append(Claim(iid=iid, username=user, source=str(path)))
    return found


def iids_from_git_diff(base_ref: str = "origin/main") -> set[int]:
    """Return claim iids added/modified vs base_ref (best-effort)."""
    iids: set[int] = set()
    try:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        try:
            out = subprocess.check_output(
                ["git", "diff", "--name-only", "HEAD~1", "HEAD"],
                stderr=subprocess.DEVNULL,
                text=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError):
            return iids
    for line in out.splitlines():
        m = CLAIM_FILE_RE.search(line.strip())
        if m:
            iids.add(int(m.group(1)))
    return iids


def resolve_claims(
    *,
    mr_title: str | None = None,
    commit_message: str | None = None,
    branch: str | None = None,
    root: Path | None = None,
    prefer_diff_iids: set[int] | None = None,
    fallback_username: str | None = None,
) -> list[Claim]:
    """Build the list of claims to validate/apply.

    Prefer marker files. Title/branch can hint the iid when the file is new.
    """
    hinted: set[int] = set()
    for text in (mr_title, commit_message):
        iid = parse_prendre_title(text or "")
        if iid is not None:
            hinted.add(iid)
        # Also scan commit body lines for prendre #N
        if text:
            for line in text.splitlines():
                iid2 = parse_prendre_title(line)
                if iid2 is not None:
                    hinted.add(iid2)
    branch_iid = parse_prendre_branch(branch)
    if branch_iid is not None:
        hinted.add(branch_iid)
    if prefer_diff_iids:
        hinted |= prefer_diff_iids

    only = hinted or None
    # Without a hint (title/branch/diff), do not scan the whole claims/ tree
    # (would re-apply every historical claim on unrelated main pushes).
    if only is None:
        return []
    claims = discover_claim_files(root, only_iids=only)

    # Title-only claim (empty MR) — use fallback username if provided
    if not claims and hinted and fallback_username:
        for iid in sorted(hinted):
            claims.append(
                Claim(
                    iid=iid,
                    username=fallback_username.lstrip("@"),
                    source="title/branch",
                )
            )
    return claims


def collision_message(claim: Claim, issue: IssueSnapshot) -> str | None:
    """Return an error message if claim collides; None if OK / idempotent."""
    current = issue.primary_assignee
    if current is None:
        return None
    if current.lower() == claim.username.lower():
        return None
    return (
        f"Anti-collision: issue #{claim.iid} is already assigned to @{current}; "
        f"claim wants @{claim.username}."
    )


def desired_labels(existing: list[str]) -> list[str]:
    labels = [l for l in existing if l.lower() != LABEL_LIBRE]
    if not any(l.lower() == LABEL_EN_COURS for l in labels):
        labels.append(LABEL_EN_COURS)
    return labels


# ---------------------------------------------------------------------------
# GitLab API
# ---------------------------------------------------------------------------


class GitlabClient:
    def __init__(self, api_v4: str, project_id: str, token: str, *, job_token: bool):
        self.api_v4 = api_v4.rstrip("/")
        self.project_id = project_id
        self.token = token
        self.job_token = job_token

    def _headers(self) -> dict[str, str]:
        h = {"Accept": "application/json", "Content-Type": "application/json"}
        if self.job_token:
            h["JOB-TOKEN"] = self.token
        else:
            h["PRIVATE-TOKEN"] = self.token
        return h

    def request(
        self,
        method: str,
        path: str,
        *,
        data: dict[str, Any] | None = None,
        query: dict[str, str] | None = None,
    ) -> Any:
        qs = f"?{urllib.parse.urlencode(query)}" if query else ""
        url = f"{self.api_v4}/projects/{urllib.parse.quote(str(self.project_id), safe='')}{path}{qs}"
        body = json.dumps(data).encode() if data is not None else None
        req = urllib.request.Request(url, data=body, method=method, headers=self._headers())
        try:
            with urllib.request.urlopen(req, timeout=30) as res:
                raw = res.read().decode()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:400]
            raise RuntimeError(f"GitLab API {method} {path} → HTTP {e.code}: {detail}") from e

    def get_issue(self, iid: int) -> IssueSnapshot:
        data = self.request("GET", f"/issues/{iid}")
        if not isinstance(data, dict):
            raise RuntimeError(f"Unexpected issue payload for #{iid}")
        assignees: list[str] = []
        for a in data.get("assignees") or []:
            if isinstance(a, dict) and a.get("username"):
                assignees.append(str(a["username"]))
        labels = [str(x) for x in (data.get("labels") or [])]
        return IssueSnapshot(
            iid=iid,
            assignees=assignees,
            labels=labels,
            state=str(data.get("state") or "opened"),
        )

    def lookup_user_id(self, username: str) -> int | None:
        data = self.request(
            "GET",
            "/users",
            query={"username": username},
        )
        # Project users endpoint differs — try members search via global users
        # /projects/:id/users?search=
        if isinstance(data, list) and data:
            # Wrong path above for project-scoped client — use absolute helper
            pass
        # Dedicated call outside project prefix:
        return self._lookup_user_id_global(username)

    def _lookup_user_id_global(self, username: str) -> int | None:
        url = (
            f"{self.api_v4}/users?"
            + urllib.parse.urlencode({"username": username})
        )
        req = urllib.request.Request(url, method="GET", headers=self._headers())
        try:
            with urllib.request.urlopen(req, timeout=30) as res:
                data = json.loads(res.read().decode() or "[]")
        except urllib.error.HTTPError:
            # Fallback: project members search
            try:
                data = self.request(
                    "GET",
                    "/users",
                    query={"search": username},
                )
            except RuntimeError:
                return None
        if isinstance(data, list):
            for u in data:
                if isinstance(u, dict) and str(u.get("username", "")).lower() == username.lower():
                    return int(u["id"])
        return None

    def apply_claim(self, claim: Claim, issue: IssueSnapshot, *, dry_run: bool) -> str:
        user_id = self._lookup_user_id_global(claim.username)
        if user_id is None:
            raise RuntimeError(
                f"Cannot resolve GitLab user @{claim.username} (needed to assign #{claim.iid})."
            )
        new_labels = desired_labels(issue.labels)
        payload: dict[str, Any] = {
            "assignee_ids": [user_id],
            "labels": ",".join(new_labels),
        }
        # Idempotent short-circuit
        if (
            issue.primary_assignee
            and issue.primary_assignee.lower() == claim.username.lower()
            and any(l.lower() == LABEL_EN_COURS for l in issue.labels)
            and not any(l.lower() == LABEL_LIBRE for l in issue.labels)
        ):
            return f"skip  #{claim.iid} already assigned to @{claim.username} (en-cours)"
        if dry_run:
            return (
                f"dry   #{claim.iid} → @{claim.username} "
                f"labels={new_labels} (from {claim.source})"
            )
        self.request("PUT", f"/issues/{claim.iid}", data=payload)
        return f"ok    #{claim.iid} assigned to @{claim.username} (en-cours)"


def resolve_token() -> tuple[str, bool]:
    for key in ("PROJECT_ACCESS_TOKEN", "GITLAB_TOKEN"):
        val = os.environ.get(key, "").strip()
        if val:
            return val, False
    job = os.environ.get("CI_JOB_TOKEN", "").strip()
    if job:
        return job, True
    return "", False


def build_client() -> GitlabClient | None:
    token, is_job = resolve_token()
    api = os.environ.get("CI_API_V4_URL", "").strip() or "https://gitlab.com/api/v4"
    project = os.environ.get("CI_PROJECT_ID", "").strip()
    if not project:
        project = os.environ.get("GITLAB_PROJECT", "").strip()
    if not token or not project:
        return None
    return GitlabClient(api, project, token, job_token=is_job)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=("validate", "apply"),
        default=os.environ.get("VOLUNTEER_CLAIM_MODE", "validate"),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path("."),
        help="Repository root (default: cwd)",
    )
    args = parser.parse_args(argv)

    mr_title = os.environ.get("CI_MERGE_REQUEST_TITLE")
    commit_msg = os.environ.get("CI_COMMIT_MESSAGE") or os.environ.get("CI_COMMIT_TITLE")
    branch = (
        os.environ.get("CI_MERGE_REQUEST_SOURCE_BRANCH_NAME")
        or os.environ.get("CI_COMMIT_REF_NAME")
    )
    fallback_user = (
        os.environ.get("GITLAB_USER_LOGIN")
        or os.environ.get("CI_COMMIT_AUTHOR")
        or ""
    ).strip()
    # CI_COMMIT_AUTHOR is often "Name <email>" — strip to login if possible
    if "<" in fallback_user:
        fallback_user = os.environ.get("GITLAB_USER_LOGIN", "").strip()

    diff_iids = iids_from_git_diff()
    try:
        claims = resolve_claims(
            mr_title=mr_title,
            commit_message=commit_msg,
            branch=branch,
            root=args.root,
            prefer_diff_iids=diff_iids or None,
            fallback_username=fallback_user or None,
        )
    except ValueError as e:
        print(f"❌ {e}", file=sys.stderr)
        return 1

    # Apply mode: never re-process the whole claims/ tree on unrelated main pushes.
    if args.mode == "apply" and not claims:
        # resolve_claims with empty hints + all files would need a guard inside —
        # we only discover when hinted/diff; if none, stop.
        print("No volunteer claims in this push — nothing to apply.")
        return 0

    if not claims:
        print("No volunteer claims detected — nothing to do.")
        return 0

    print(f"Claims detected ({args.mode}):")
    for c in claims:
        print(f"  - #{c.iid} → @{c.username} ({c.source})")

    client = build_client()
    if client is None:
        if args.mode == "validate":
            # Offline / no token: still validate local claim file format
            print(
                "⚠️  No GitLab token/project — local format OK; "
                "skipping live assignee collision check."
            )
            return 0
        print(
            "⏭️  No PROJECT_ACCESS_TOKEN/GITLAB_TOKEN/CI_JOB_TOKEN or CI_PROJECT_ID — "
            "skip apply (keeps pipeline green)."
        )
        return 0

    errors = 0
    for claim in claims:
        try:
            issue = client.get_issue(claim.iid)
        except RuntimeError as e:
            print(f"❌ #{claim.iid}: {e}", file=sys.stderr)
            errors += 1
            continue

        if issue.state == "closed":
            print(f"⚠️  #{claim.iid} is closed — skip.")
            continue

        conflict = collision_message(claim, issue)
        if conflict:
            print(f"❌ {conflict}", file=sys.stderr)
            errors += 1
            continue

        if args.mode == "validate":
            print(f"✅ #{claim.iid} free (or already @{claim.username}) — OK")
            continue

        try:
            msg = client.apply_claim(claim, issue, dry_run=args.dry_run)
            print(msg)
        except RuntimeError as e:
            print(f"❌ apply #{claim.iid}: {e}", file=sys.stderr)
            errors += 1

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
