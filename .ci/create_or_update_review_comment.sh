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
  comment_id=$(curl -sL \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $SECRETS_WORKFLOW" \
    "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/$pr_number/comments" | \
    jq --raw-output --arg comment_id $comment_id '.[] | select(.id|tostring == $comment_id) | if has("in_reply_to_id") then .in_reply_to_id else .id end')
  data=$(jq -n \
    --argjson body "\"$body\"" \
    '{"body":$body}')
  reply_id=$(curl -sL \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $SECRETS_WORKFLOW" \
    -d "$data" \
    "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/$pr_number/comments/$comment_id/replies" | \
    jq --raw-output '.id')
  echo "::set-output name=reply_id::$reply_id"
elif [[ $mode == "append" ]]; then
  old_comment_body=$(curl -sL \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $SECRETS_WORKFLOW" \
    "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/comments/$comment_id" | \
    jq --raw-output '.body')
  data=$(jq -n --raw-input \
    --arg body "$old_comment_body\r\n$body" \
    '{"body":$body}')
  curl -sL \
    -X PATCH \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $SECRETS_WORKFLOW" \
    -d "$data" \
    "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/comments/$comment_id"
else
  echo "Unknown value of <MODE> argument: $mode. Can be 'create' or 'append'"
  exit -1
fi
