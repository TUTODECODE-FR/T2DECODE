#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 TUTODECODE Association <contact@tutodecode.org>
"""Self-service volunteer « prendre #<iid> » claims — validate / bot / apply.

Claim convention
----------------
- Branch : ``volunteer/prendre-<iid>``
- Marker : ``volunteer/claims/<iid>.md`` containing the GitLab username
- MR title : ``prendre #<iid>`` (exact prefix match)

Lock model (claim takes effect at MR *open*, not at merge)
----------------------------------------------------------
An **open** claim MR *is* the lock on the ticket :

- ``validate`` (MR pipeline) : pure format/scope checks always; live checks
  (issue exists & free, no older open claim MR for the same ticket, one
  active claim per person) whenever the GitLab API is readable (public
  project → anonymous read works, no secret needed). Green pipeline =
  ticket locked by this MR. Red = taken / invalid, with a clear message.
- ``bot`` (scheduled pipeline on ``main``, maintainer token) : authoritative
  re-validation of every open claim MR, assigns the issue right away
  (assignee + label ``en-cours``), merges valid green MRs without any
  human action, comments on invalid ones, auto-closes stale claims
  (no activity for ``STALE_DAYS`` days) and frees tickets whose claim MR
  was closed unmerged.
- ``apply`` (push on ``main``) : idempotent post-merge assignment fallback.

Security
--------
MR pipelines never see a write token (a malicious MR could exfiltrate it).
All write operations live in ``bot``/``apply`` which only run on the
protected ``main`` branch (schedules, manual runs, pushes).

Auth (first non-empty wins)
---------------------------
``PROJECT_ACCESS_TOKEN`` / ``GITLAB_TOKEN`` / ``CI_JOB_TOKEN`` / anonymous
(anonymous is enough for read-only checks on a public project).

Env (GitLab CI)
---------------
``CI_API_V4_URL``, ``CI_PROJECT_ID`` (or ``VOLUNTEER_PROJECT`` to force the
canonical project, e.g. from fork pipelines), ``CI_MERGE_REQUEST_TITLE``,
``CI_MERGE_REQUEST_IID``, ``CI_MERGE_REQUEST_SOURCE_BRANCH_NAME``,
``CI_MERGE_REQUEST_TARGET_BRANCH_NAME``, ``CI_COMMIT_MESSAGE``,
``CI_COMMIT_TITLE``, ``GITLAB_USER_LOGIN``, ``CI_COMMIT_REF_NAME``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
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
LABEL_BENEVOLAT = "benevolat"
STALE_DAYS = int(os.environ.get("VOLUNTEER_STALE_DAYS", "14"))
BOT_MARKER = "<!-- volunteer-claim-bot"

# Files a claim MR is allowed to touch. Anything else → pipeline rouge.
ALLOWED_PATH_RES = [
    re.compile(r"^volunteer/claims/\d+\.md$"),
    re.compile(r"^VOLUNTEER_BOARD\.md$"),
    re.compile(r"^CONTRIBUTORS\.md$"),
]


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


class ApiError(RuntimeError):
    """GitLab API error carrying the HTTP status code."""

    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status


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


def is_allowed_claim_path(path: str) -> bool:
    """True if a claim MR may touch this repo path."""
    p = path.strip().lstrip("./")
    return any(rx.match(p) for rx in ALLOWED_PATH_RES)


def scope_violations(paths: list[str]) -> list[str]:
    """Changed paths that a claim MR is NOT allowed to touch."""
    return [p for p in paths if p.strip() and not is_allowed_claim_path(p)]


def claim_iid_from_mr(mr: dict[str, Any]) -> int | None:
    """Ticket iid hinted by an MR (title first, then source branch)."""
    return parse_prendre_title(str(mr.get("title") or "")) or parse_prendre_branch(
        str(mr.get("source_branch") or "")
    )


def mr_author(mr: dict[str, Any]) -> str:
    author = mr.get("author") or {}
    return str(author.get("username") or "")


def lock_holder(mrs: list[dict[str, Any]], iid: int) -> dict[str, Any] | None:
    """The open MR that holds the lock on ticket ``iid`` (lowest MR iid wins)."""
    candidates = [mr for mr in mrs if claim_iid_from_mr(mr) == iid]
    if not candidates:
        return None
    return min(candidates, key=lambda mr: int(mr.get("iid") or 0))


def other_active_claims(
    mrs: list[dict[str, Any]], username: str, *, exclude_mr_iid: int | None
) -> list[dict[str, Any]]:
    """Open claim MRs by ``username`` other than ``exclude_mr_iid``."""
    out = []
    for mr in mrs:
        if exclude_mr_iid is not None and int(mr.get("iid") or 0) == exclude_mr_iid:
            continue
        if claim_iid_from_mr(mr) is None:
            continue
        if mr_author(mr).lower() == username.lower():
            out.append(mr)
    return out


def author_mismatch(claim: Claim, author: str) -> str | None:
    """Error message if the marker username is not the MR author."""
    if not author:
        return None
    if claim.username.lower() != author.lower():
        return (
            f"Le marqueur indique @{claim.username} mais l'auteur de la MR est "
            f"@{author}. On ne peut claimer que pour soi-même."
        )
    return None


def parse_gitlab_ts(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def is_stale_mr(mr: dict[str, Any], *, now: datetime, days: int = STALE_DAYS) -> bool:
    """True if the MR had no activity for ``days`` days."""
    ts = parse_gitlab_ts(str(mr.get("updated_at") or ""))
    if ts is None:
        return False
    return (now - ts).days >= days


def bot_fingerprint(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


# ---------------------------------------------------------------------------
# Local claim files & git helpers
# ---------------------------------------------------------------------------


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


def git_changed_files(base_ref: str = "origin/main") -> list[str]:
    """Files changed vs base_ref (best-effort, empty if git unavailable)."""
    for spec in (f"{base_ref}...HEAD", "HEAD~1..HEAD"):
        try:
            out = subprocess.check_output(
                ["git", "diff", "--name-only", spec],
                stderr=subprocess.DEVNULL,
                text=True,
            )
            return [l.strip() for l in out.splitlines() if l.strip()]
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    return []


def iids_from_git_diff(base_ref: str = "origin/main") -> set[int]:
    """Return claim iids added/modified vs base_ref (best-effort)."""
    iids: set[int] = set()
    for line in git_changed_files(base_ref):
        m = CLAIM_FILE_RE.search(line)
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


def claimable_errors(claim: Claim, issue: IssueSnapshot) -> list[str]:
    """Hard errors making a ticket non-claimable (unit-tested)."""
    errors: list[str] = []
    if issue.state == "closed":
        errors.append(f"Le ticket #{claim.iid} est fermé — rien à prendre.")
        return errors
    conflict = collision_message(claim, issue)
    if conflict:
        errors.append(conflict)
    has_en_cours = any(l.lower() == LABEL_EN_COURS for l in issue.labels)
    if has_en_cours and (issue.primary_assignee or "").lower() != claim.username.lower():
        errors.append(
            f"Le ticket #{claim.iid} porte déjà le label `{LABEL_EN_COURS}` — "
            "il est probablement pris."
        )
    return errors


def claimable_warnings(claim: Claim, issue: IssueSnapshot) -> list[str]:
    """Soft warnings (non-blocking) for a claim."""
    warnings: list[str] = []
    if not any(l.lower() == LABEL_BENEVOLAT for l in issue.labels):
        warnings.append(
            f"#{claim.iid} n'a pas le label `{LABEL_BENEVOLAT}` — "
            "vérifiez que c'est bien un ticket bénévole."
        )
    if not any(l.lower() == LABEL_LIBRE for l in issue.labels):
        warnings.append(
            f"#{claim.iid} n'a pas le label `{LABEL_LIBRE}` (optionnel) — "
            "claim accepté car aucun assignee."
        )
    return warnings


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
        if not self.token:
            pass  # anonymous read (public project)
        elif self.job_token:
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
        raw: bool = False,
    ) -> Any:
        qs = f"?{urllib.parse.urlencode(query)}" if query else ""
        url = f"{self.api_v4}/projects/{urllib.parse.quote(str(self.project_id), safe='')}{path}{qs}"
        body = json.dumps(data).encode() if data is not None else None
        req = urllib.request.Request(url, data=body, method=method, headers=self._headers())
        try:
            with urllib.request.urlopen(req, timeout=30) as res:
                text = res.read().decode()
                if raw:
                    return text
                return json.loads(text) if text else None
        except urllib.error.HTTPError as e:
            detail = e.read().decode()[:400]
            raise ApiError(
                e.code, f"GitLab API {method} {path} → HTTP {e.code}: {detail}"
            ) from e

    # -- issues -----------------------------------------------------------

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

    def list_issues(self, query: dict[str, str]) -> list[dict[str, Any]]:
        data = self.request("GET", "/issues", query=query)
        return data if isinstance(data, list) else []

    def issues_assigned_to(self, username: str) -> list[dict[str, Any]]:
        return self.list_issues(
            {"assignee_username": username, "state": "opened", "per_page": "100"}
        )

    def free_issue(self, issue: IssueSnapshot) -> None:
        """Unassign + drop `en-cours` + restore `libre` (abandoned claim)."""
        labels = [l for l in issue.labels if l.lower() != LABEL_EN_COURS]
        if not any(l.lower() == LABEL_LIBRE for l in labels):
            labels.append(LABEL_LIBRE)
        self.request(
            "PUT",
            f"/issues/{issue.iid}",
            data={"assignee_ids": [], "labels": ",".join(labels)},
        )

    # -- merge requests ---------------------------------------------------

    def list_open_claim_mrs(self) -> list[dict[str, Any]]:
        """All open MRs that look like claims (title or branch convention)."""
        mrs: list[dict[str, Any]] = []
        for page in range(1, 6):
            data = self.request(
                "GET",
                "/merge_requests",
                query={"state": "opened", "per_page": "100", "page": str(page)},
            )
            if not isinstance(data, list) or not data:
                break
            mrs.extend(mr for mr in data if isinstance(mr, dict))
            if len(data) < 100:
                break
        return [mr for mr in mrs if claim_iid_from_mr(mr) is not None]

    def list_closed_claim_mrs(self) -> list[dict[str, Any]]:
        data = self.request(
            "GET",
            "/merge_requests",
            query={"state": "closed", "per_page": "100", "order_by": "updated_at"},
        )
        if not isinstance(data, list):
            return []
        return [mr for mr in data if isinstance(mr, dict) and claim_iid_from_mr(mr)]

    def get_mr(self, iid: int) -> dict[str, Any]:
        data = self.request("GET", f"/merge_requests/{iid}")
        return data if isinstance(data, dict) else {}

    def get_mr_diff_paths(self, iid: int) -> list[str]:
        data = self.request(
            "GET", f"/merge_requests/{iid}/diffs", query={"per_page": "100"}
        )
        paths: list[str] = []
        if isinstance(data, list):
            for d in data:
                if isinstance(d, dict):
                    for key in ("new_path", "old_path"):
                        p = str(d.get(key) or "")
                        if p and p not in paths:
                            paths.append(p)
        return paths

    def get_mr_notes(self, iid: int) -> list[dict[str, Any]]:
        data = self.request(
            "GET", f"/merge_requests/{iid}/notes", query={"per_page": "100"}
        )
        return data if isinstance(data, list) else []

    def create_mr_note(self, iid: int, body: str) -> None:
        self.request("POST", f"/merge_requests/{iid}/notes", data={"body": body})

    def approve_mr(self, iid: int) -> None:
        self.request("POST", f"/merge_requests/{iid}/approve")

    def merge_mr(
        self,
        iid: int,
        *,
        when_pipeline_succeeds: bool = False,
        remove_source_branch: bool = False,
    ) -> None:
        data: dict[str, Any] = {}
        if when_pipeline_succeeds:
            data["merge_when_pipeline_succeeds"] = True
        if remove_source_branch:
            data["should_remove_source_branch"] = True
        self.request("PUT", f"/merge_requests/{iid}/merge", data=data)

    def create_mr_pipeline(self, iid: int) -> None:
        self.request("POST", f"/merge_requests/{iid}/pipelines")

    def close_mr(self, iid: int) -> None:
        self.request("PUT", f"/merge_requests/{iid}", data={"state_event": "close"})

    # -- repository files ---------------------------------------------------

    def get_raw_file(self, path: str, ref: str) -> str | None:
        quoted = urllib.parse.quote(path, safe="")
        try:
            return self.request(
                "GET", f"/repository/files/{quoted}/raw", query={"ref": ref}, raw=True
            )
        except ApiError as e:
            if e.status == 404:
                return None
            raise

    # -- users / assignment -------------------------------------------------

    def _lookup_user_id_global(self, username: str) -> int | None:
        url = f"{self.api_v4}/users?" + urllib.parse.urlencode({"username": username})
        req = urllib.request.Request(url, method="GET", headers=self._headers())
        try:
            with urllib.request.urlopen(req, timeout=30) as res:
                data = json.loads(res.read().decode() or "[]")
        except urllib.error.HTTPError:
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


def build_client(*, allow_anonymous: bool = False) -> GitlabClient | None:
    token, is_job = resolve_token()
    api = os.environ.get("CI_API_V4_URL", "").strip() or "https://gitlab.com/api/v4"
    project = (
        os.environ.get("VOLUNTEER_PROJECT", "").strip()
        or os.environ.get("CI_PROJECT_ID", "").strip()
        or os.environ.get("GITLAB_PROJECT", "").strip()
    )
    if not project:
        return None
    if not token and not allow_anonymous:
        return None
    return GitlabClient(api, project, token, job_token=is_job)


# ---------------------------------------------------------------------------
# Shared validation helpers
# ---------------------------------------------------------------------------


def live_claim_errors(
    client: GitlabClient,
    claim: Claim,
    *,
    my_mr_iid: int | None,
    open_mrs: list[dict[str, Any]] | None = None,
) -> tuple[list[str], list[str]]:
    """Authoritative live checks. Returns (errors, warnings).

    - ticket exists & is claimable (open, no other assignee, not en-cours)
    - no *other* open claim MR locks the ticket (oldest MR wins)
    - one active claim per person (other open claim MR or assigned ticket)
    """
    errors: list[str] = []
    warnings: list[str] = []

    try:
        issue = client.get_issue(claim.iid)
    except ApiError as e:
        if e.status == 404:
            errors.append(
                f"Le ticket #{claim.iid} n'existe pas. Vérifiez le numéro "
                "(issues GitLab du projet, label `benevolat`)."
            )
        else:
            errors.append(f"#{claim.iid}: {e}")
        return errors, warnings

    errors.extend(claimable_errors(claim, issue))
    warnings.extend(claimable_warnings(claim, issue))

    mrs = open_mrs if open_mrs is not None else client.list_open_claim_mrs()
    others = [mr for mr in mrs if my_mr_iid is None or int(mr.get("iid") or 0) != my_mr_iid]

    holder = lock_holder(others, claim.iid)
    if holder is not None:
        who = mr_author(holder)
        if who.lower() == claim.username.lower():
            errors.append(
                f"Vous avez déjà une MR de claim ouverte pour #{claim.iid} : "
                f"!{holder.get('iid')}. Fermez-la d'abord (ou réutilisez-la)."
            )
        else:
            errors.append(
                f"Ticket #{claim.iid} déjà pris par @{who} "
                f"(MR !{holder.get('iid')}). Choisissez un autre ticket `libre`."
            )

    active = other_active_claims(others, claim.username, exclude_mr_iid=None)
    if active:
        first = active[0]
        errors.append(
            f"Une seule claim active à la fois : vous avez déjà "
            f"!{first.get('iid')} (ticket #{claim_iid_from_mr(first)}). "
            "Terminez-la ou fermez-la avant d'en prendre une autre."
        )

    try:
        assigned = client.issues_assigned_to(claim.username)
    except ApiError:
        assigned = []
    busy = [
        i
        for i in assigned
        if int(i.get("iid") or 0) != claim.iid
        and any(str(l).lower() == LABEL_EN_COURS for l in (i.get("labels") or []))
    ]
    if busy:
        errors.append(
            f"Le ticket #{busy[0].get('iid')} vous est déjà assigné "
            f"(`{LABEL_EN_COURS}`) — une seule tâche en cours à la fois."
        )

    return errors, warnings


# ---------------------------------------------------------------------------
# Mode: validate (MR pipeline — no secret, read-only)
# ---------------------------------------------------------------------------


def run_validate(args: argparse.Namespace) -> int:
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

    target = os.environ.get("CI_MERGE_REQUEST_TARGET_BRANCH_NAME", "main")
    diff_iids = iids_from_git_diff(f"origin/{target}")
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

    if not claims:
        print("No volunteer claims detected — nothing to do.")
        return 0

    if len(claims) > 1:
        ids = ", ".join(f"#{c.iid}" for c in claims)
        print(
            f"❌ Une MR de claim = une seule tâche (détecté : {ids}). "
            "Ouvrez une MR par ticket.",
            file=sys.stderr,
        )
        return 1

    claim = claims[0]
    print(f"Claim détectée : ticket #{claim.iid} → @{claim.username} ({claim.source})")

    # 1. Marker file is mandatory (it is the durable record merged into main)
    if not claim.source.endswith(".md"):
        print(
            f"❌ Fichier marqueur `volunteer/claims/{claim.iid}.md` introuvable. "
            "Ajoutez-le avec une ligne `username: votre-pseudo` "
            "(voir le modèle de MR « Prendre »).",
            file=sys.stderr,
        )
        return 1

    # 2. Scope: a claim MR must touch volunteer files only
    changed = git_changed_files(f"origin/{target}")
    if changed:
        bad = scope_violations(changed)
        if bad:
            print(
                "❌ Une MR de claim ne doit toucher QUE les fichiers bénévoles "
                "(volunteer/claims/<iid>.md, VOLUNTEER_BOARD.md, CONTRIBUTORS.md).",
                file=sys.stderr,
            )
            for p in bad:
                print(f"   ⛔ {p}", file=sys.stderr)
            print(
                "   → Toute MR qui touche du code passe par la relecture "
                "mainteneur classique.",
                file=sys.stderr,
            )
            return 1
        print(f"✅ Périmètre OK ({len(changed)} fichier(s), zone bénévole uniquement)")
    else:
        print("⚠️  Diff local indisponible — périmètre vérifié par le bot.")

    # 3. Live checks (read-only API; anonymous OK on a public project)
    client = build_client(allow_anonymous=True)
    if client is None:
        print("⚠️  Projet GitLab inconnu — checks live sautés (le bot revalide).")
        return 0

    my_mr_iid = int(os.environ.get("CI_MERGE_REQUEST_IID") or 0) or None
    try:
        errors, warnings = live_claim_errors(client, claim, my_mr_iid=my_mr_iid)
    except ApiError as e:
        if e.status in (401, 403):
            print(
                f"⚠️  API illisible ({e.status}) — checks live sautés, "
                "le bot planifié revalide et merge."
            )
            return 0
        print(f"❌ API GitLab: {e}", file=sys.stderr)
        return 1

    # Authoritative author check via API (GITLAB_USER_LOGIN is the pipeline
    # triggerer, not necessarily the MR author → not reliable here).
    if my_mr_iid is not None:
        try:
            mr = client.get_mr(my_mr_iid)
            mismatch = author_mismatch(claim, mr_author(mr))
            if mismatch:
                errors.append(mismatch)
        except ApiError as e:
            if e.status not in (401, 403, 404):
                raise

    for w in warnings:
        print(f"⚠️  {w}")
    if errors:
        for e in errors:
            print(f"❌ {e}", file=sys.stderr)
        print(
            "\n💡 Le ticket reste verrouillé tant qu'une MR de claim valide est "
            "ouverte. Choisissez un autre ticket ou contactez un mainteneur.",
            file=sys.stderr,
        )
        return 1

    print(
        f"✅ Ticket #{claim.iid} libre — cette MR le VERROUILLE pour "
        f"@{claim.username} dès maintenant. Le bot assigne l'issue et merge "
        "automatiquement (aucune action mainteneur requise)."
    )
    return 0


# ---------------------------------------------------------------------------
# Mode: apply (push on main — idempotent post-merge assignment)
# ---------------------------------------------------------------------------


def run_apply(args: argparse.Namespace) -> int:
    mr_title = os.environ.get("CI_MERGE_REQUEST_TITLE")
    commit_msg = os.environ.get("CI_COMMIT_MESSAGE") or os.environ.get("CI_COMMIT_TITLE")
    branch = (
        os.environ.get("CI_MERGE_REQUEST_SOURCE_BRANCH_NAME")
        or os.environ.get("CI_COMMIT_REF_NAME")
    )
    fallback_user = (os.environ.get("GITLAB_USER_LOGIN") or "").strip()

    diff_iids = iids_from_git_diff("origin/main")
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

    if not claims:
        print("No volunteer claims in this push — nothing to apply.")
        return 0

    print(f"Claims detected (apply):")
    for c in claims:
        print(f"  - #{c.iid} → @{c.username} ({c.source})")

    client = build_client()
    if client is None:
        print(
            "⏭️  No PROJECT_ACCESS_TOKEN/GITLAB_TOKEN/CI_JOB_TOKEN or CI_PROJECT_ID — "
            "skip apply (keeps pipeline green)."
        )
        return 0

    errors = 0
    for claim in claims:
        try:
            issue = client.get_issue(claim.iid)
        except (RuntimeError, ApiError) as e:
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

        try:
            msg = client.apply_claim(claim, issue, dry_run=args.dry_run)
            print(msg)
        except (RuntimeError, ApiError) as e:
            print(f"❌ apply #{claim.iid}: {e}", file=sys.stderr)
            errors += 1

    return 1 if errors else 0


# ---------------------------------------------------------------------------
# Mode: bot (scheduled on main — authoritative, holds the write token)
# ---------------------------------------------------------------------------


def _bot_comment_once(client: GitlabClient, mr_iid: int, body: str, *, dry_run: bool) -> None:
    """Post an MR note, skipping if the same fingerprint was already posted."""
    fp = bot_fingerprint(body)
    tagged = f"{BOT_MARKER} {fp} -->\n{body}"
    try:
        notes = client.get_mr_notes(mr_iid)
    except ApiError:
        notes = []
    for n in notes:
        if fp in str(n.get("body") or ""):
            print(f"  💬 commentaire déjà posté sur !{mr_iid} — skip")
            return
    if dry_run:
        print(f"  💬 [dry-run] commentaire sur !{mr_iid}:\n{body}")
        return
    client.create_mr_note(mr_iid, tagged)
    print(f"  💬 commentaire posté sur !{mr_iid}")


def _bot_claim_from_mr(client: GitlabClient, mr: dict[str, Any]) -> tuple[Claim | None, list[str]]:
    """Rebuild the claim from an MR via the API (marker file in source branch)."""
    reasons: list[str] = []
    iid = claim_iid_from_mr(mr)
    if iid is None:
        return None, ["Titre/branche non conforme (`prendre #<iid>` attendu)."]
    author = mr_author(mr)
    ref = str(mr.get("source_branch") or "")
    sha = str(mr.get("sha") or "")
    content = client.get_raw_file(f"volunteer/claims/{iid}.md", sha or ref)
    if content is None:
        reasons.append(
            f"Fichier marqueur `volunteer/claims/{iid}.md` introuvable "
            "dans la branche source."
        )
        return None, reasons
    username = parse_claim_file_username(content)
    if not username:
        reasons.append(
            f"Le marqueur `volunteer/claims/{iid}.md` ne contient pas de "
            "pseudo GitLab (`username: …`)."
        )
        return None, reasons
    claim = Claim(iid=iid, username=username, source=f"mr!{mr.get('iid')}")
    mismatch = author_mismatch(claim, author)
    if mismatch:
        reasons.append(mismatch)
    return (claim if not reasons else None), reasons


def _bot_validate_mr(
    client: GitlabClient,
    mr: dict[str, Any],
    open_mrs: list[dict[str, Any]],
) -> tuple[Claim | None, IssueSnapshot | None, list[str]]:
    """Full authoritative validation of one open claim MR."""
    reasons: list[str] = []
    mr_iid = int(mr.get("iid") or 0)

    claim, parse_reasons = _bot_claim_from_mr(client, mr)
    reasons.extend(parse_reasons)

    # Scope: volunteer files only
    try:
        paths = client.get_mr_diff_paths(mr_iid)
    except ApiError as e:
        paths = []
        reasons.append(f"Diff illisible ({e.status}) — revalidation au prochain passage.")
    bad = scope_violations(paths)
    if bad:
        reasons.append(
            "La MR touche des fichiers hors zone bénévole : "
            + ", ".join(f"`{p}`" for p in bad)
            + ". Une MR de claim ne doit modifier que `volunteer/claims/<iid>.md`"
            " (éventuellement VOLUNTEER_BOARD.md / CONTRIBUTORS.md)."
        )

    issue: IssueSnapshot | None = None
    if claim is not None:
        errors, warnings = live_claim_errors(
            client, claim, my_mr_iid=mr_iid, open_mrs=open_mrs
        )
        reasons.extend(errors)
        reasons.extend(f"(info) {w}" for w in warnings if "benevolat" in w)
        if not errors:
            try:
                issue = client.get_issue(claim.iid)
            except ApiError:
                issue = None

    return claim, issue, reasons


def _bot_merge_mr(
    client: GitlabClient,
    mr: dict[str, Any],
    *,
    dry_run: bool,
) -> str:
    """Approve + merge (or schedule MWPS) a valid claim MR. Returns a status."""
    mr_iid = int(mr.get("iid") or 0)
    full = client.get_mr(mr_iid)
    if full.get("draft"):
        return "draft (fusion différée — sortez la MR du mode draft)"
    if full.get("has_conflicts"):
        _bot_comment_once(
            client,
            mr_iid,
            "⚠️ Cette MR de claim a des **conflits** avec `main`. "
            "Faites un rebase pour que le bot puisse la merger.",
            dry_run=dry_run,
        )
        return "conflits — rebase demandé"

    pipeline = full.get("head_pipeline") or {}
    pstatus = str(pipeline.get("status") or "")
    same_project = str(full.get("source_project_id")) == str(client.project_id)

    if dry_run:
        return f"[dry-run] merge !{mr_iid} (pipeline={pstatus or 'aucune'})"

    try:
        client.approve_mr(mr_iid)
    except ApiError:
        pass  # approval optional (CODEOWNERS ne couvre pas la zone bénévole)

    try:
        if pstatus == "success":
            client.merge_mr(mr_iid, remove_source_branch=same_project)
            return "✅ mergée"
        if pstatus in ("running", "pending", "created", "waiting_for_resource", "preparing"):
            client.merge_mr(
                mr_iid,
                when_pipeline_succeeds=True,
                remove_source_branch=same_project,
            )
            return "⏳ merge programmé (MWPS) — fusion au vert de la pipeline"
        if pstatus in ("failed", "canceled"):
            _bot_comment_once(
                client,
                mr_iid,
                "❌ La pipeline de cette MR est en échec. Corrigez (format du "
                "marqueur, DCO `Signed-off-by`, périmètre fichiers) puis "
                "relancez la pipeline : le bot mergera automatiquement.",
                dry_run=dry_run,
            )
            return "pipeline rouge — commentaire posté"
        # No pipeline yet (ex. fork sans pipeline) → en créer une puis MWPS
        try:
            client.create_mr_pipeline(mr_iid)
            client.merge_mr(
                mr_iid,
                when_pipeline_succeeds=True,
                remove_source_branch=same_project,
            )
            return "⏳ pipeline créée + MWPS"
        except ApiError as e:
            return f"⚠️ pas de pipeline et création impossible ({e.status})"
    except ApiError as e:
        return f"⚠️ merge impossible (HTTP {e.status}) — nouvel essai au prochain passage"


def run_bot(args: argparse.Namespace) -> int:
    dry_run = args.dry_run or os.environ.get("VOLUNTEER_BOT_DRY_RUN", "") == "1"
    client = build_client()
    if client is None or not client.token:
        print(
            "❌ volunteer_claim_bot nécessite PROJECT_ACCESS_TOKEN (maintainer, "
            "scope api) + CI_PROJECT_ID. Lancez-le depuis une pipeline planifiée "
            "sur main (variable protégée).",
            file=sys.stderr,
        )
        return 1
    if dry_run:
        print("🔎 MODE DRY-RUN — aucune écriture.\n")

    now = datetime.now(timezone.utc)
    open_mrs = client.list_open_claim_mrs()
    print(f"🔍 {len(open_mrs)} MR(s) de claim ouverte(s)")

    failures = 0
    for mr in open_mrs:
        mr_iid = int(mr.get("iid") or 0)
        iid = claim_iid_from_mr(mr)
        print(f"\n── MR !{mr_iid} → ticket #{iid} (@{mr_author(mr)})")

        # Reaper: stale claim MR → close → frees the ticket
        if is_stale_mr(mr, now=now):
            body = (
                f"⏰ Cette claim est inactive depuis {STALE_DAYS} jours : elle est "
                "fermée automatiquement et le ticket redevient `libre`. "
                "Rouvrez une nouvelle MR `prendre #N` si vous voulez le reprendre."
            )
            _bot_comment_once(client, mr_iid, body, dry_run=dry_run)
            if dry_run:
                print(f"  🧹 [dry-run] fermeture MR !{mr_iid} (stale)")
            else:
                try:
                    client.close_mr(mr_iid)
                    print(f"  🧹 MR !{mr_iid} fermée (inactive {STALE_DAYS}j) → ticket libéré")
                except ApiError as e:
                    print(f"  ❌ fermeture impossible: {e}", file=sys.stderr)
                    failures += 1
            continue

        try:
            claim, issue, reasons = _bot_validate_mr(client, mr, open_mrs)
        except ApiError as e:
            print(f"  ❌ validation impossible: {e}", file=sys.stderr)
            failures += 1
            continue

        if reasons:
            print("  ❌ invalide:")
            for r in reasons:
                print(f"     - {r}")
            body = (
                "🤖 **Claim non validée** par le bot bénévole :\n\n"
                + "\n".join(f"- {r}" for r in reasons)
                + "\n\nCorrigez puis poussez (la pipeline se relance), ou fermez "
                "cette MR. Tant qu'une MR de claim valide est ouverte, le ticket "
                "est verrouillé pour son auteur."
            )
            _bot_comment_once(client, mr_iid, body, dry_run=dry_run)
            continue

        assert claim is not None and issue is not None

        # 1. Lock visible tout de suite : assigne l'issue immédiatement
        try:
            print("  " + client.apply_claim(claim, issue, dry_run=dry_run))
        except (RuntimeError, ApiError) as e:
            print(f"  ❌ assignation: {e}", file=sys.stderr)
            failures += 1
            continue

        # 2. Merge automatique (ou MWPS) — aucune action mainteneur
        try:
            status = _bot_merge_mr(client, mr, dry_run=dry_run)
            print(f"  {status}")
        except ApiError as e:
            print(f"  ❌ merge: {e}", file=sys.stderr)
            failures += 1

    # Libération des tickets dont la MR de claim a été fermée sans merge
    print("\n── Tickets orphelins (claim fermée sans merge)")
    try:
        closed = client.list_closed_claim_mrs()
    except ApiError:
        closed = []
    open_iids = {claim_iid_from_mr(mr) for mr in open_mrs}
    done_iids: set[int] = set()
    for mr in closed:
        iid = claim_iid_from_mr(mr)
        if iid is None or iid in open_iids or iid in done_iids:
            continue
        done_iids.add(iid)
        try:
            if client.get_raw_file(f"volunteer/claims/{iid}.md", "main") is not None:
                continue  # claim mergée → travail en cours, ne pas toucher
            issue = client.get_issue(iid)
        except ApiError:
            continue
        has_en_cours = any(l.lower() == LABEL_EN_COURS for l in issue.labels)
        if issue.state == "opened" and (issue.assignees or has_en_cours):
            who = issue.primary_assignee or "?"
            if dry_run:
                print(f"  🔓 [dry-run] #{iid} libéré (était @{who})")
                continue
            try:
                client.free_issue(issue)
                print(f"  🔓 ticket #{iid} libéré (claim fermée, était @{who})")
            except ApiError as e:
                print(f"  ❌ libération #{iid}: {e}", file=sys.stderr)
                failures += 1

    print("\n✅ Bot terminé." if not failures else f"\n⚠️ Bot terminé avec {failures} erreur(s).")
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=("validate", "apply", "bot"),
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

    if args.mode == "apply":
        return run_apply(args)
    if args.mode == "bot":
        return run_bot(args)
    return run_validate(args)


if __name__ == "__main__":
    raise SystemExit(main())
