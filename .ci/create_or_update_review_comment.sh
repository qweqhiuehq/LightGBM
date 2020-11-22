#!/bin/bash
#
# [description]
#     Create or update reply with a given body to the given original review comment.
#
# [usage]
#     set_commit_status.sh <PR_NUMBER> <COMMENT_ID> <MODE> <BODY>
#
# NAME: Name of status.
#       Status with existing name overwrites a previous one.
#
# STATUS: Status to be set.
#         Can be "error", "failure", "pending" or "success".
#
# SHA: SHA of a commit to set a status on.

set -e

if [ -z "$GITHUB_ACTIONS" ]; then
  echo "Must be run inside GitHub Actions CI"
  exit -1
fi

if [ $# -ne 4 ]; then
  echo "Usage: $0 <PR_NUMBER> <COMMENT_ID> <MODE> <BODY>"
  exit -1
fi

pr_number=$1
comment_id=$2
mode=$3
body=$4

if [[ $mode == "create" ]]; then
  echo "Usage: $0 <PR_NUMBER> <COMMENT_ID> <MODE> <BODY>"
  exit -1
elif [[ $mode == "append" ]]; then
else
  echo "Unknown value of <MODE> argument: $mode. Can be 'create' or 'append'"
  exit -1
fi

data=$(jq -n \
  --arg state $status \
  --arg url "${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
  --arg name "$name" \
  '{"state":$state,"target_url":$url,"context":$name}')

curl -sL \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $SECRETS_WORKFLOW" \
  -d "$data" \
  "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/statuses/$sha"
