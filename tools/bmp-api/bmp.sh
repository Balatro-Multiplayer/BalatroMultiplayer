#!/usr/bin/env bash
# BMP API helper — reads api_key from .env, passes through to curl.
#
# Usage:
#   ./bmp.sh GET /cocktails
#   ./bmp.sh POST /cocktails '{"id":"abc","name":"Old Fashioned"}'
#   ./bmp.sh PATCH /cocktails/abc '{"name":"New Name"}'
#   ./bmp.sh DELETE /cocktails/abc
#   ./bmp.sh POST /cocktails/abc/decks/deck1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env not found at $ENV_FILE" >&2
  exit 1
fi

API_KEY="$(grep '^api_key=' "$ENV_FILE" | cut -d'=' -f2-)"
BASE_URL="https://bmp.casjb.co.uk"

if [[ -z "$API_KEY" ]]; then
  echo "Error: api_key not found in .env" >&2
  exit 1
fi

METHOD="${1:?Usage: bmp.sh METHOD /path [json-body]}"
PATH_SEGMENT="${2:?Usage: bmp.sh METHOD /path [json-body]}"
BODY="${3:-}"

CURL_ARGS=(
  -s -w '\n%{http_code}\n'
  -X "$METHOD"
  -H "x-api-key: $API_KEY"
  -H "Content-Type: application/json"
)

if [[ -n "$BODY" ]]; then
  CURL_ARGS+=(-d "$BODY")
fi

RESPONSE="$(curl "${CURL_ARGS[@]}" "${BASE_URL}${PATH_SEGMENT}")"
HTTP_CODE="$(echo "$RESPONSE" | tail -1)"
BODY_OUT="$(echo "$RESPONSE" | sed '$d')"

if [[ -n "$BODY_OUT" ]]; then
  # Pretty-print JSON if jq is available
  if command -v jq &>/dev/null; then
    echo "$BODY_OUT" | jq . 2>/dev/null || echo "$BODY_OUT"
  else
    echo "$BODY_OUT"
  fi
fi

echo "HTTP $HTTP_CODE"
