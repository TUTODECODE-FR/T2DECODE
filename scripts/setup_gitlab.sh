#!/usr/bin/env bash
# scripts/setup_gitlab.sh
# Configure GitLab branch protections and Merge Request settings via API

set -e

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <GITLAB_TOKEN> <PROJECT_ID_OR_PATH>"
  echo "Example: $0 glpat-xxxxxx tutodecode-org%2FT2DECODE"
  exit 1
fi

GITLAB_TOKEN="$1"
PROJECT_ID="$2"
GITLAB_API="https://gitlab.com/api/v4"

echo "Applying GitLab protections for project: $PROJECT_ID..."

# 1. Protect 'main' branch
echo "Protecting 'main' branch (No direct push, maintainers can merge)..."
curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --url "$GITLAB_API/projects/$PROJECT_ID/protected_branches?name=main&push_access_level=0&merge_access_level=40" \
     || echo "Branch might already be protected, updating..."
     
curl --request PATCH --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --url "$GITLAB_API/projects/$PROJECT_ID/protected_branches/main?push_access_level=0&merge_access_level=40"

# 2. Require Pipeline to succeed before merge & resolve discussions
echo "Updating Merge Request settings..."
curl --request PUT --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{
       "only_allow_merge_if_pipeline_succeeds": true,
       "only_allow_merge_if_all_discussions_are_resolved": true,
       "printing_merge_request_link_enabled": true,
       "remove_source_branch_after_merge": true
     }' \
     --url "$GITLAB_API/projects/$PROJECT_ID"

# 3. Require at least 1 approval
echo "Setting MR approval rules (Requires Premium/Ultimate, may fail on Free)..."
curl --request POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --header "Content-Type: application/json" \
     --data '{
       "name": "Require 1 approval",
       "approvals_required": 1,
       "rule_type": "regular"
     }' \
     --url "$GITLAB_API/projects/$PROJECT_ID/approval_rules" || true

echo ""
echo "✅ GitLab Protections and MR settings configured successfully!"
