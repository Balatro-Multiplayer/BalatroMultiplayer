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
#               (TODO: switch to a clean git tag/ref + GitHub runner), but:
#                 - .env is NOT shipped (build falls back to config.lua)
#                 - version is auto-stripped to a clean release string
#                   (drops ~preN and -DEV)
#                 - config.lua server port is forced to production
#                 - core.lua debug defaults (mem_debug) are turned off
#
# Output: dist/Multiplayer-v<version>/      (clean unzipped folder, both modes)
#         dist/Multiplayer-v<version>.zip   (--dev: versioned playtest zip)
#         dist/BalatroMultiplayer.zip       (--release: literal name BMM and
#                                            balatromp.com require)
#
set -euo pipefail

# --- production server (used by --release to sanitize config.lua) ------------
PROD_SERVER_URL="balatro.virtualized.dev"
PROD_SERVER_PORT=8788

# --- mode (required) ---
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

# --- version (from manifest) ---------------------
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

# Release artifacts MUST be named exactly "BalatroMultiplayer.zip" — BMM and
# balatromp.com look up that literal filename for every release (see
# .github/RELEASE_CHECKLIST.md). Dev builds stay versioned so playtest zips
# don't clobber each other.
if [ "$MODE" = release ]; then
  ZIP_NAME="BalatroMultiplayer"
else
  ZIP_NAME="$NAME"
fi

DIST="${ROOT}/dist"
STAGE="${DIST}/${NAME}"
ZIP="${DIST}/${ZIP_NAME}.zip"

echo "==> building ${NAME}  (mode: ${MODE}, version: ${VERSION})"

rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

# --- enumerate the files that should ship -----------------------------------
# The file list comes from git, not from a raw filesystem walk, so the build
# only ever contains things that actually belong to the repo

# local dev folders, editor/tooling junk, scratch files, 
# and anything matched by .gitignore are excluded
#
#   --dev:     tracked files + new (untracked, non-ignored) files
#   --release: tracked files only — a clean, repo-faithful set
#
# -a archive. In --dev we also pass -L to follow symlinks (some maintainers
# symlink their .env to its real contents); --release omits .env entirely.
RSYNC_FLAGS=(-a)
GIT_LS=(git ls-files -z)
if [ "$MODE" = dev ]; then
  RSYNC_FLAGS+=(-L)
  GIT_LS+=(--cached --others --exclude-standard)
else
  GIT_LS+=(--cached)
fi

# Build the NUL-delimited file list, then pipe it straight into rsync 
# .env is gitignored on purpose (git never lists it), so
# append it by hand for dev builds 
{
  "${GIT_LS[@]}" -- \
    ':(exclude).github' \
    ':(exclude).gitignore' \
    ':(exclude)stylua.toml' \
    ':(exclude)agents.md' \
    ':(exclude)CONTRIBUTING.md' \
    ':(exclude)tests' \
    ':(exclude)scripts' \
    ':(exclude).claude' 
  if [ "$MODE" = dev ] && [ -e .env ]; then
    printf '%s\0' .env
  fi
} | rsync "${RSYNC_FLAGS[@]}" --from0 --files-from=- ./ "$STAGE/"

# we love macOS here
find "$STAGE" -name '.DS_Store' -delete

# --- sanitize the release copy ---------------------------------
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
# from INSIDE the stage so the mod files land at the archive root (no outer
# "Multiplayer-vX/" wrapper). BMM and balatromp.com expect Multiplayer.json at
# the zip root — see .github/RELEASE_CHECKLIST.md
( cd "$STAGE" && zip -rqX "../${ZIP_NAME}.zip" . )

echo "==> folder: ${STAGE}"
echo "==> zip:    ${ZIP}"
echo "==> done."
