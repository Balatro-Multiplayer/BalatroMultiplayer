#!/usr/bin/env bash
#
# run_scenario.sh — launch Balatro (Lovely, macOS) with one in-game scenario,
# wait for it to quit, and report its MP_SCENARIO lines from the Lovely log.
#
#   bash scripts/run_scenario.sh custom_wall
#   bash scripts/run_scenario.sh chaos_run
#
# Scenarios live in tests/scenarios/<name>.lua. Screenshots land in
# .context/scenarios/<name>/. Exit 0 only if the run printed DONE with fail=0.
# The Mods/BalatroMultiplayer symlink must point at this checkout, and the Mac
# must be unlocked: LÖVE blocks in present() while the display is asleep or
# behind the lock screen, so the run never gets past the loading screen.
#
set -euo pipefail

NAME="${1:?usage: run_scenario.sh <scenario>}"
TIMEOUT="${SCENARIO_TIMEOUT:-120}"
GAME_DIR="${BALATRO_DIR:-$HOME/Library/Application Support/Steam/steamapps/common/Balatro}"
LOG_DIR="$HOME/Library/Application Support/Balatro/Mods/lovely/log"

if pgrep -f "Balatro.app/Contents/MacOS/love" >/dev/null; then
  echo "!! Balatro is already running; close it first" >&2
  exit 2
fi

newest_log() { ls -t "$LOG_DIR" 2>/dev/null | head -1 || true; }

before="$(newest_log)"
# caffeinate must not inherit stdout: a background child holding the pipe keeps
# the caller (e.g. an agent's shell tool) waiting until it exits.
caffeinate -u -t "$TIMEOUT" >/dev/null 2>&1 &
caf=$!
trap 'kill "$caf" 2>/dev/null || true' EXIT

MP_SCENARIO="$NAME" MP_SCENARIO_QUIT=1 bash "$GAME_DIR/run_lovely_macos.sh" >/dev/null 2>&1 &
pid=$!

for _ in $(seq "$TIMEOUT"); do
  kill -0 "$pid" 2>/dev/null || break
  sleep 1
done
if kill -0 "$pid" 2>/dev/null; then
  echo "!! timed out after ${TIMEOUT}s; killing" >&2
  # the game ignores SIGTERM while stuck in present()
  pkill -9 -f "Balatro.app/Contents/MacOS/love" || true
fi

log="$(newest_log)"
if [ "$log" = "$before" ]; then
  echo "!! no new Lovely log was written" >&2
  exit 1
fi

lines="$(grep -o 'MP_SCENARIO .*' "$LOG_DIR/$log" || true)"
echo "$lines"
echo "log: $LOG_DIR/$log"

echo "$lines" | grep -q '^MP_SCENARIO DONE pass=[0-9]* fail=0[[:space:]]*$'
