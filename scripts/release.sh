#!/usr/bin/env bash
#
# release.sh — build the Multiplayer mod, in one of two modes:
#
#   --dev       Playtest/dev build. Source is the WORKING TREE (uncommitted edits
#               included). Your real .env is baked in so
#               the build talks to whatever server/port your .env points at and
#               keeps the "-DEV" version (which triggers the in-game dev warning).
#
#   --release   Shippable build. Source is still the WORKING TREE for now
#               (see TODO below to switch to a clean git tag/ref), but:
#                 - .env is NOT shipped (build falls back to config.lua)
#                 - version is auto-stripped to a clean release string
#                   (drops ~preN and -DEV, so no dev-warning overlay)
#                 - config.lua server port is forced to production
#                 - core.lua debug defaults (mem_debug) are turned off
#
# Output: dist/Multiplayer-v<version>/      (clean unzipped folder)
#         dist/Multiplayer-v<version>.zip   (zipped, ready to ship)
#
set -euo pipefail

# --- production server (used by --release to sanitize config.lua) ------------
PROD_SERVER_URL="balatro.virtualized.dev"
PROD_SERVER_PORT=8788

# --- mode (required, no default — defaulting would risk leaking your .env) ---
MODE="${1:-}"
case "$MODE" in
  --dev)     MODE=dev ;;
  --release) MODE=release ;;
  *)
    echo "usage: $(basename "$0") --dev | --release" >&2
    exit 2
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Portable in-place edit (BSD/macOS + GNU sed differ; perl is consistent).
inplace() { perl -0pi -e "$1" "$2"; }

# --- version (from manifest), with release sanitization ---------------------
VERSION="$(grep -m1 '"version"' Multiplayer.json \
  | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"

if [ "$MODE" = release ]; then
  # Strip the pre-release/dev tail: "0.4.0~pre2-DEV" -> "0.4.0".
  VERSION="${VERSION%%~*}"              # drop everything from the first '~'
  VERSION="${VERSION%-[Dd][Ee][Vv]}"   # drop a trailing '-DEV' if no '~' was present
  if printf '%s' "$VERSION" | grep -qi 'dev'; then
    echo "!! refusing to make a release: version still looks like a dev build ('$VERSION')" >&2
    exit 1
  fi
fi

SAFE_VERSION="$(printf '%s' "$VERSION" | tr -c 'A-Za-z0-9._-' '_')"
NAME="Multiplayer-v${SAFE_VERSION}"

DIST="${ROOT}/dist"
STAGE="${DIST}/${NAME}"
ZIP="${DIST}/${NAME}.zip"

echo "==> building ${NAME}  (mode: ${MODE}, version: ${VERSION})"

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

# --- copy working tree, strip noise -----------------------------------------
# TODO(release): build from a clean git ref instead of the working tree, e.g.
#   git archive --format=tar <tag> | ( cd "$STAGE" && tar -xf - )
# then skip the rsync below. For now both modes use the working tree.
#
# -a archive. In --dev we also pass -L to follow symlinks (turns the .env
# symlink into its real contents); --release excludes .env entirely instead.
RSYNC_FLAGS=(-a)
ENV_EXCLUDE=()
if [ "$MODE" = dev ]; then
  RSYNC_FLAGS+=(-L)
else
  ENV_EXCLUDE+=(--exclude='/.env')
fi

rsync "${RSYNC_FLAGS[@]}" \
  ${ENV_EXCLUDE[@]+"${ENV_EXCLUDE[@]}"} \
  --exclude='/dist/' \
  --exclude='.git' \
  --exclude='/.github/' \
  --exclude='.gitignore' \
  --exclude='.gitattributes' \
  --exclude='.DS_Store' \
  --exclude='/.context/' \
  --exclude='/.claude/' \
  --exclude='.vscode/' \
  --exclude='.idea/' \
  --exclude='.vs/' \
  --exclude='.luarc.json' \
  --exclude='.lovelyignore' \
  --exclude='/agents.md' \
  --exclude='CLAUDE.md' \
  --exclude='CLAUDE.local.md' \
  --exclude='/CONTRIBUTING.md' \
  --exclude='stylua.toml' \
  --exclude='/tests/' \
  --exclude='/scripts/' \
  ./ "$STAGE/"

find "$STAGE" -name '.DS_Store' -delete

# --- release-only: sanitize the staged copy ---------------------------------
if [ "$MODE" = release ]; then
  # Clean version into the shipped manifest (no ~preN / -DEV -> no dev warning).
  inplace "s/(\"version\"\\s*:\\s*\")[^\"]+\"/\${1}${VERSION}\"/" "$STAGE/Multiplayer.json"
  # Point config.lua at the production server (working tree may hold a dev port).
  inplace "s/(\\[\"server_url\"\\]\\s*=\\s*\")[^\"]*\"/\${1}${PROD_SERVER_URL}\"/" "$STAGE/config.lua"
  inplace "s/(\\[\"server_port\"\\]\\s*=\\s*)\\d+/\${1}${PROD_SERVER_PORT}/"       "$STAGE/config.lua"
fi

# --- sanity: make sure the bits that MUST (and must NOT) ship are present ----
for required in Multiplayer.json core.lua; do
  if [ ! -e "${STAGE}/${required}" ]; then
    echo "!! WARNING: expected '${required}' missing from build" >&2
  fi
done

if [ "$MODE" = dev ]; then
  [ -e "${STAGE}/.env" ] || echo "!! WARNING: dev build but '.env' missing" >&2
else
  [ -e "${STAGE}/.env" ] && echo "!! WARNING: release build is shipping a '.env' — it should not" >&2
  [ -e "${STAGE}/.env.example" ] || echo "!! WARNING: release build missing '.env.example'" >&2
fi

# --- zip it -----------------------------------------------------------------
# Zip from INSIDE the stage so the mod files land at the archive root (no outer
# "Multiplayer-vX/" wrapper). BMM and balatromp.com expect Multiplayer.json at
# the zip root — see .github/RELEASE_CHECKLIST.md ("recompress from the files
# instead of the outer folder").
( cd "$STAGE" && zip -rqX "../${NAME}.zip" . )

echo "==> folder: ${STAGE}"
echo "==> zip:    ${ZIP}"
echo "==> done."
