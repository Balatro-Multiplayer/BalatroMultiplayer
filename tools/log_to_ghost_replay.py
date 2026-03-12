#!/usr/bin/env python3
"""Parse a Lovely log file and extract ghost replay data.

Produces a Lua table fragment matching the ghost_replays entry format
in Multiplayer.jkr, suitable for pasting into the config or feeding
into the ghost replay system.

Usage:
    python3 tools/log_to_ghost_replay.py <logfile>
    python3 tools/log_to_ghost_replay.py <logfile> --lua    # output as Lua table (default)
    python3 tools/log_to_ghost_replay.py <logfile> --json   # output as JSON
"""

import json
import re
import sys
import time
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class AnteSnapshot:
    ante: int
    player_score: str = "0"
    enemy_score: str = "0"
    player_lives: int = 4
    enemy_lives: int = 4
    result: Optional[str] = None  # "win" or "loss"


@dataclass
class GameRecord:
    seed: Optional[str] = None
    ruleset: Optional[str] = None
    gamemode: Optional[str] = None
    deck: Optional[str] = None
    stake: Optional[int] = None
    player_name: Optional[str] = None
    nemesis_name: Optional[str] = None
    starting_lives: int = 4
    is_host: Optional[bool] = None
    ante_snapshots: dict = field(default_factory=dict)
    winner: Optional[str] = None
    final_ante: int = 1
    current_ante: int = 0
    player_lives: int = 4
    enemy_lives: int = 4
    # Track the latest scores during a PvP round
    pvp_player_score: str = "0"
    pvp_enemy_score: str = "0"
    in_pvp: bool = False


# --- Parsers for specific log message types ---


def parse_client_sent_json(line: str) -> Optional[dict]:
    """Extract JSON from 'Client sent message: {...}' lines."""
    m = re.search(r"Client sent message: (\{.*\})\s*$", line)
    if m:
        try:
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            return None
    return None


def parse_client_got_kv(line: str) -> Optional[tuple]:
    """Extract action and key-value pairs from 'Client got <action> message: (k: v) ...' lines."""
    m = re.search(r"Client got (\w+) message:\s*(.*?)\s*$", line)
    if not m:
        return None
    action = m.group(1)
    kv_str = m.group(2)
    pairs = {}
    for km in re.finditer(r"\((\w+):\s*([^)]*)\)", kv_str):
        key = km.group(1)
        val = km.group(2).strip()
        # Try to convert to number
        try:
            if "." in val:
                val = float(val)
            else:
                val = int(val)
        except ValueError:
            # Keep as string, handle booleans
            if val == "true":
                val = True
            elif val == "false":
                val = False
        pairs[key] = val
    return action, pairs


def parse_lobby_options_json(line: str) -> Optional[dict]:
    """Extract lobby options from a lobbyOptions sent message."""
    data = parse_client_sent_json(line)
    if data and data.get("action") == "lobbyOptions":
        return data
    return None


def process_log(filepath: str) -> GameRecord:
    """Process a log file and extract ghost replay data."""
    game = GameRecord()
    last_lobby_options = None

    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    for line in lines:
        if "MULTIPLAYER" not in line:
            continue

        # --- Sent messages (JSON) ---
        sent = parse_client_sent_json(line)
        if sent:
            action = sent.get("action")

            if action == "username":
                game.player_name = sent.get("username")

            elif action == "lobbyOptions":
                last_lobby_options = sent

            elif action == "setAnte":
                ante = sent.get("ante", 0)
                game.current_ante = ante
                if ante > game.final_ante:
                    game.final_ante = ante

            elif action == "playHand":
                score = sent.get("score", "0")
                if game.in_pvp:
                    game.pvp_player_score = str(score)

            elif action == "setLocation":
                loc = sent.get("location", "")
                if "bl_mp_nemesis" in loc:
                    game.in_pvp = True

            continue

        # --- Received messages (key-value) ---
        parsed = parse_client_got_kv(line)
        if not parsed:
            continue
        action, kv = parsed

        if action == "lobbyInfo":
            # Determine host/guest status and nemesis name
            if "isHost" in kv:
                game.is_host = kv["isHost"]
            if game.is_host is True and "guest" in kv:
                game.nemesis_name = str(kv["guest"])
            elif game.is_host is False and "host" in kv:
                game.nemesis_name = str(kv["host"])

        elif action == "startGame":
            # Apply last lobby options
            if last_lobby_options:
                game.ruleset = last_lobby_options.get("ruleset")
                game.gamemode = last_lobby_options.get("gamemode")
                game.deck = last_lobby_options.get("back", "Red Deck")
                game.stake = last_lobby_options.get("stake", 1)
                game.starting_lives = last_lobby_options.get("starting_lives", 4)
                game.player_lives = game.starting_lives
                game.enemy_lives = game.starting_lives

        elif action == "playerInfo":
            if "lives" in kv:
                game.player_lives = kv["lives"]

        elif action == "enemyInfo":
            if "lives" in kv:
                game.enemy_lives = kv["lives"]
            if "score" in kv:
                game.pvp_enemy_score = str(kv["score"])

        elif action == "enemyLocation":
            loc = kv.get("location", "")
            if "bl_mp_nemesis" in str(loc):
                game.in_pvp = True

        elif action == "endPvP":
            lost = kv.get("lost", False)
            result = "loss" if lost else "win"

            snap = AnteSnapshot(
                ante=game.current_ante,
                player_score=game.pvp_player_score,
                enemy_score=game.pvp_enemy_score,
                player_lives=game.player_lives,
                enemy_lives=game.enemy_lives,
                result=result,
            )
            game.ante_snapshots[game.current_ante] = snap

            # Reset PvP tracking
            game.in_pvp = False
            game.pvp_player_score = "0"
            game.pvp_enemy_score = "0"

        elif action == "winGame":
            game.winner = "player"

        elif action == "loseGame":
            game.winner = "nemesis"

        elif action == "stopGame":
            if "seed" in kv:
                game.seed = str(kv["seed"])

    # Also check sent messages for setLocation to detect PvP entry
    # (already handled above in the sent message section via enemyLocation)

    return game


def to_lua_table(game: GameRecord) -> str:
    """Convert a GameRecord to a Lua table string matching ghost_replays format."""
    indent = "\t"

    lines = ["{"]
    lines.append(
        f'{indent}["gamemode"] = "{game.gamemode or "gamemode_mp_attrition"}",'
    )
    lines.append(f'{indent}["final_ante"] = {game.final_ante},')
    lines.append(f'{indent}["ante_snapshots"] = {{')

    for ante in sorted(game.ante_snapshots.keys()):
        snap = game.ante_snapshots[ante]
        lines.append(f"{indent}{indent}[{ante}] = {{")
        lines.append(f'{indent}{indent}{indent}["result"] = "{snap.result}",')
        lines.append(f'{indent}{indent}{indent}["enemy_score"] = "{snap.enemy_score}",')
        lines.append(f'{indent}{indent}{indent}["enemy_lives"] = {snap.enemy_lives},')
        lines.append(
            f'{indent}{indent}{indent}["player_score"] = "{snap.player_score}",'
        )
        lines.append(f'{indent}{indent}{indent}["player_lives"] = {snap.player_lives},')
        lines.append(f"{indent}{indent}}},")

    lines.append(f"{indent}}},")
    lines.append(f'{indent}["winner"] = "{game.winner or "unknown"}",')
    lines.append(f'{indent}["timestamp"] = {int(time.time())},')
    lines.append(f'{indent}["ruleset"] = "{game.ruleset or "ruleset_mp_blitz"}",')
    lines.append(f'{indent}["seed"] = "{game.seed or "UNKNOWN"}",')
    lines.append(f'{indent}["deck"] = "{game.deck or "Red Deck"}",')
    lines.append(f'{indent}["stake"] = {game.stake or 1},')
    if game.player_name:
        lines.append(f'{indent}["player_name"] = "{game.player_name}",')
    if game.nemesis_name:
        lines.append(f'{indent}["nemesis_name"] = "{game.nemesis_name}",')
    lines.append("}")

    return "\n".join(lines)


def to_json(game: GameRecord) -> str:
    """Convert a GameRecord to JSON."""
    snapshots = {}
    for ante, snap in sorted(game.ante_snapshots.items()):
        snapshots[str(ante)] = {
            "result": snap.result,
            "enemy_score": snap.enemy_score,
            "enemy_lives": snap.enemy_lives,
            "player_score": snap.player_score,
            "player_lives": snap.player_lives,
        }

    obj = {
        "gamemode": game.gamemode or "gamemode_mp_attrition",
        "final_ante": game.final_ante,
        "ante_snapshots": snapshots,
        "winner": game.winner or "unknown",
        "timestamp": int(time.time()),
        "ruleset": game.ruleset or "ruleset_mp_blitz",
        "seed": game.seed or "UNKNOWN",
        "deck": game.deck or "Red Deck",
        "stake": game.stake or 1,
    }
    if game.player_name:
        obj["player_name"] = game.player_name
    if game.nemesis_name:
        obj["nemesis_name"] = game.nemesis_name

    return json.dumps(obj, indent=2)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    filepath = sys.argv[1]
    output_format = "lua"
    if "--json" in sys.argv:
        output_format = "json"

    game = process_log(filepath)

    # Print summary
    print(f"# Parsed game from log: {filepath}", file=sys.stderr)
    print(f"#   Seed: {game.seed}", file=sys.stderr)
    print(f"#   Ruleset: {game.ruleset}", file=sys.stderr)
    print(f"#   Gamemode: {game.gamemode}", file=sys.stderr)
    print(f"#   Deck: {game.deck} (stake {game.stake})", file=sys.stderr)
    print(f"#   Player: {game.player_name}", file=sys.stderr)
    print(f"#   Nemesis: {game.nemesis_name}", file=sys.stderr)
    print(f"#   Winner: {game.winner}", file=sys.stderr)
    print(f"#   Final ante: {game.final_ante}", file=sys.stderr)
    print(f"#   PvP snapshots: {len(game.ante_snapshots)} antes", file=sys.stderr)
    for ante in sorted(game.ante_snapshots.keys()):
        s = game.ante_snapshots[ante]
        print(
            f"#     Ante {ante}: {s.result} | player={s.player_score} ({s.player_lives}hp) vs enemy={s.enemy_score} ({s.enemy_lives}hp)",
            file=sys.stderr,
        )
    print(file=sys.stderr)

    if output_format == "json":
        print(to_json(game))
    else:
        print(to_lua_table(game))


if __name__ == "__main__":
    main()
