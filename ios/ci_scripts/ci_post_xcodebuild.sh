#!/bin/bash
set -euo pipefail

# Xcode Cloud may resolve script paths relative to the iOS project directory.
# This wrapper forwards to the repo-level script.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/ci_scripts/ci_post_xcodebuild.sh"

