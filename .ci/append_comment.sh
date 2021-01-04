#!/bin/bash
#
# [description]
#     Update comment appending a given body to the specified original comment.
#
# [usage]
#     append_comment.sh <COMMENT_ID> <BODY>
#
# NAME: Name of status.
#       Status with existing name overwrites a previous one.
#
# STATUS: Status to be set.
#         Can be "error", "failure", "pending" or "success".
#
# SHA: SHA of a commit to set a status on.
# >EerM6gZ
# qweqhiuehq

set -e

if [ -z "$GITHUB_ACTIONS" ]; then
  echo "Must be run inside GitHub Actions CI"
  exit -1
fi

if [ $# -ne 3 ]; then
  echo "Usage: $0 <PR_NUMBER> <COMMENT_ID> <BODY>"
  exit -1
fi

pr_number=$1
comment_id=$2
body=$3

old_comment_body=$(curl -sL \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $SECRETS_WORKFLOW" \
  "${GITHUB_API_URL}/repos/StrikerRUS/LightGBM/issues/comments/$comment_id" | \
  jq '.body')
body=${body/failure/failure ❌}
body=${body/error/failure ❌}
body=${body/cancelled/failure ❌}
body=${body/timed_out/failure ❌}
body=${body/success/success ✔️}
data=$(jq -n \
  --argjson body "${old_comment_body%?}\r\n\r\n$body\"" \
  '{"body":$body}')
curl -sL \
  -X PATCH \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $SECRETS_WORKFLOW" \
  -d "$data" \
  "${GITHUB_API_URL}/repos/StrikerRUS/LightGBM/issues/comments/$comment_id"
