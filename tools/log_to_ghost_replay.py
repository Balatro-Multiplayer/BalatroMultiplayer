#!/usr/bin/env python3
"""Parse a Lovely log file and generate ghost replay JSON(s).

Handles multiple games within a single log file — each startGame/stopGame
cycle produces a separate replay.  Output defaults to JSON written into
replays/; use --lua for Lua table output to stdout.

Usage:
    python3 tools/log_to_ghost_replay.py <logfile>              # writes to replays/
    python3 tools/log_to_ghost_replay.py <logfile> --lua        # output Lua table to stdout
"""

import json
import os
import re
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------


@dataclass
class HandScore:
    """A single hand played during a PvP round."""

    score: str
    hands_left: int
    side: str  # "player" or "enemy"


@dataclass
class AnteSnapshot:
    ante: int
    player_score: str = "0"
    enemy_score: str = "0"
    player_lives: int = 4
    enemy_lives: int = 4
    result: Optional[str] = None  # "win" or "loss"
    hands: list = field(default_factory=list)  # list[HandScore]


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
    lobby_code: Optional[str] = None
    ante_snapshots: dict = field(default_factory=dict)
    winner: Optional[str] = None
    final_ante: int = 1
    current_ante: int = 0
    player_lives: int = 4
    enemy_lives: int = 4

    # PvP round tracking (transient)
    pvp_player_score: str = "0"
    pvp_enemy_score: str = "0"
    pvp_hands: list = field(default_factory=list)
    in_pvp: bool = False

    # End-game data
    player_jokers: list = field(default_factory=list)
    nemesis_jokers: list = field(default_factory=list)
    player_stats: dict = field(default_factory=dict)
    nemesis_stats: dict = field(default_factory=dict)

    # Per-ante shop spending
    shop_spending: dict = field(default_factory=dict)

    # Non-PvP round failures
    failed_rounds: list = field(default_factory=list)

    # Timing
    game_start_ts: Optional[str] = None
    game_end_ts: Optional[str] = None

    # Card activity log
    cards_bought: list = field(default_factory=list)
    cards_sold: list = field(default_factory=list)
    cards_used: list = field(default_factory=list)


# ---------------------------------------------------------------------------
# Parsers
# ---------------------------------------------------------------------------

_TS_RE = re.compile(r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})")


def parse_timestamp(line: str) -> Optional[str]:
    """Extract ISO-ish timestamp from a log line."""
    m = _TS_RE.search(line)
    return m.group(1) if m else None


def parse_client_sent_json(line: str) -> Optional[dict]:
    """Extract JSON from 'Client sent message: {...}' lines."""
    m = re.search(r"Client sent message: (\{.*\})\s*$", line)
    if m:
        try:
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            return None
    return None


def parse_client_sent_kv(line: str) -> Optional[dict]:
    """Extract key:value pairs from 'Client sent message: action:foo,key:val' lines."""
    m = re.search(r"Client sent message: (action:\w+.*?)\s*$", line)
    if not m:
        return None
    raw = m.group(1)
    pairs = {}
    for part in raw.split(","):
        if ":" in part:
            k, v = part.split(":", 1)
            pairs[k.strip()] = v.strip()
    return pairs


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
        try:
            if "." in val:
                val = float(val)
            else:
                val = int(val)
        except ValueError:
            if val == "true":
                val = True
            elif val == "false":
                val = False
        pairs[key] = val
    return action, pairs


def parse_joker_list(raw: str) -> list:
    """Parse a ';'-separated joker string like ';j_foo-none-none-none;j_bar-...'
    into a list of joker key strings."""
    jokers = []
    for entry in raw.split(";"):
        entry = entry.strip()
        if not entry:
            continue
        # Format: j_key-edition-sticker1-sticker2
        parts = entry.split("-", 1)
        jokers.append(parts[0] if parts else entry)
    return jokers


def parse_joker_list_full(raw: str) -> list:
    """Parse joker string preserving edition/sticker info as dicts."""
    jokers = []
    for entry in raw.split(";"):
        entry = entry.strip()
        if not entry:
            continue
        parts = entry.split("-")
        joker = {"key": parts[0]}
        if len(parts) >= 2 and parts[1] != "none":
            joker["edition"] = parts[1]
        if len(parts) >= 3 and parts[2] != "none":
            joker["sticker1"] = parts[2]
        if len(parts) >= 4 and parts[3] != "none":
            joker["sticker2"] = parts[3]
        jokers.append(joker)
    return jokers


# ---------------------------------------------------------------------------
# Multi-game log processing
# ---------------------------------------------------------------------------


def process_log(filepath: str) -> list:
    """Process a log file and return a list of GameRecords (one per game)."""
    games = []
    game = GameRecord()
    last_lobby_options = None
    in_game = False

    with open(filepath, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    for line in lines:
        if "MULTIPLAYER" not in line:
            continue

        ts = parse_timestamp(line)

        # --- Direct log messages (not Client sent/got) ---
        if "Sending end game jokers:" in line:
            m = re.search(r"Sending end game jokers:\s*(.*?)\s*$", line)
            if m:
                game.player_jokers = parse_joker_list_full(m.group(1))
            continue

        if "Received end game jokers:" in line:
            m = re.search(r"Received end game jokers:\s*(.*?)\s*$", line)
            if m:
                game.nemesis_jokers = parse_joker_list_full(m.group(1))
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
                hands_left = sent.get("handsLeft", 0)
                if game.in_pvp:
                    game.pvp_player_score = str(score)
                    game.pvp_hands.append(
                        HandScore(
                            score=str(score),
                            hands_left=hands_left,
                            side="player",
                        )
                    )

            elif action == "setLocation":
                loc = sent.get("location", "")
                if "bl_mp_nemesis" in loc:
                    game.in_pvp = True

            elif action == "failRound":
                game.failed_rounds.append(game.current_ante)

            elif action == "spentLastShop":
                amount = sent.get("amount", 0)
                game.shop_spending[game.current_ante] = (
                    game.shop_spending.get(game.current_ante, 0) + amount
                )

            elif action == "nemesisEndGameStats":
                # Player's own stats sent to the nemesis
                game.player_stats = {
                    k: v for k, v in sent.items() if k != "action"
                }

            elif action == "startGame":
                # Record game start timestamp
                if ts:
                    game.game_start_ts = ts

            continue

        # --- Sent messages (key:value format — card activity) ---
        sent_kv = parse_client_sent_kv(line)
        if sent_kv:
            action = sent_kv.get("action")
            if action == "boughtCardFromShop":
                card = sent_kv.get("card", "")
                cost = sent_kv.get("cost", "0")
                game.cards_bought.append(
                    {"card": card, "cost": int(cost), "ante": game.current_ante}
                )
            elif action == "soldCard":
                card = sent_kv.get("card", "")
                game.cards_sold.append(
                    {"card": card, "ante": game.current_ante}
                )
            elif action == "usedCard":
                card = sent_kv.get("card", "")
                game.cards_used.append(
                    {"card": card, "ante": game.current_ante}
                )
            continue

        # --- Received messages (key-value) ---
        parsed = parse_client_got_kv(line)
        if not parsed:
            continue
        action, kv = parsed

        if action == "joinedLobby":
            if "code" in kv:
                game.lobby_code = str(kv["code"])

        elif action == "lobbyInfo":
            if "isHost" in kv:
                game.is_host = kv["isHost"]
            if game.is_host is True and "guest" in kv:
                game.nemesis_name = str(kv["guest"])
            elif game.is_host is False and "host" in kv:
                game.nemesis_name = str(kv["host"])

        elif action == "startGame":
            in_game = True
            if ts:
                game.game_start_ts = game.game_start_ts or ts
            # Apply last lobby options
            if last_lobby_options:
                game.ruleset = last_lobby_options.get("ruleset")
                game.gamemode = last_lobby_options.get("gamemode")
                game.deck = last_lobby_options.get("back", "Red Deck")
                game.stake = last_lobby_options.get("stake", 1)
                game.starting_lives = last_lobby_options.get(
                    "starting_lives", 4
                )
                game.player_lives = game.starting_lives
                game.enemy_lives = game.starting_lives

        elif action == "playerInfo":
            if "lives" in kv:
                game.player_lives = kv["lives"]

        elif action == "enemyInfo":
            if "lives" in kv:
                game.enemy_lives = kv["lives"]
            if "score" in kv:
                score_str = str(kv["score"])
                if game.in_pvp:
                    game.pvp_enemy_score = score_str
                    # Track enemy hand progressions
                    hands_left = kv.get("handsLeft", 0)
                    game.pvp_hands.append(
                        HandScore(
                            score=score_str,
                            hands_left=hands_left,
                            side="enemy",
                        )
                    )

        elif action == "enemyLocation":
            loc = kv.get("location", "")
            if "bl_mp_nemesis" in str(loc):
                game.in_pvp = True

        elif action == "endPvP":
            lost = kv.get("lost", False)
            result = "loss" if lost else "win"

            # Clean up hand progression: drop initial score=0 entries,
            # deduplicate same-score same-side updates (life-loss broadcasts),
            # and skip late re-broadcasts of a side's final score
            cleaned_hands = []
            seen_final = {}  # side -> score at hands_left=0
            for h in game.pvp_hands:
                if h.score == "0" and h.hands_left >= 4:
                    continue
                if cleaned_hands and (
                    cleaned_hands[-1].score == h.score
                    and cleaned_hands[-1].side == h.side
                ):
                    continue
                # Skip if this side already posted a final score
                if h.side in seen_final and h.score == seen_final[h.side]:
                    continue
                if h.hands_left == 0:
                    seen_final[h.side] = h.score
                cleaned_hands.append(h)

            snap = AnteSnapshot(
                ante=game.current_ante,
                player_score=game.pvp_player_score,
                enemy_score=game.pvp_enemy_score,
                player_lives=game.player_lives,
                enemy_lives=game.enemy_lives,
                result=result,
                hands=cleaned_hands,
            )
            game.ante_snapshots[game.current_ante] = snap

            # Reset PvP tracking
            game.in_pvp = False
            game.pvp_player_score = "0"
            game.pvp_enemy_score = "0"
            game.pvp_hands = []

        elif action == "winGame":
            game.winner = "player"

        elif action == "loseGame":
            game.winner = "nemesis"

        elif action == "nemesisEndGameStats":
            # Nemesis stats received from the server
            game.nemesis_stats = {k: v for k, v in kv.items() if k != "action"}

        elif action == "stopGame":
            if "seed" in kv:
                game.seed = str(kv["seed"])
            if ts:
                game.game_end_ts = ts
            # Finalize this game record and start a fresh one for the next game
            if in_game:
                games.append(game)
            in_game = False
            # Carry over player_name and preserve lobby state for next game
            prev_name = game.player_name
            game = GameRecord()
            game.player_name = prev_name
            last_lobby_options = None

    # If the log ends mid-game (no stopGame), still capture it
    if in_game and game.winner:
        games.append(game)

    return games


# ---------------------------------------------------------------------------
# Output formatters
# ---------------------------------------------------------------------------


def _format_duration(start: str, end: str) -> Optional[str]:
    """Compute duration string from two timestamp strings."""
    try:
        fmt = "%Y-%m-%d %H:%M:%S"
        t0 = datetime.strptime(start, fmt)
        t1 = datetime.strptime(end, fmt)
        delta = t1 - t0
        secs = int(delta.total_seconds())
        if secs < 0:
            return None
        mins, s = divmod(secs, 60)
        return f"{mins}m{s:02d}s"
    except (ValueError, TypeError):
        return None


def _hands_to_list(hands: list) -> list:
    """Convert HandScore objects to serializable dicts."""
    return [
        {"score": h.score, "hands_left": h.hands_left, "side": h.side}
        for h in hands
    ]


def to_json(game: GameRecord) -> str:
    """Convert a GameRecord to JSON."""
    snapshots = {}
    for ante, snap in sorted(game.ante_snapshots.items()):
        snap_dict = {
            "player_score": snap.player_score,
            "enemy_score": snap.enemy_score,
            "player_lives": snap.player_lives,
            "enemy_lives": snap.enemy_lives,
            "result": snap.result,
        }
        if snap.hands:
            snap_dict["hands"] = _hands_to_list(snap.hands)
        snapshots[str(ante)] = snap_dict

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
    if game.lobby_code:
        obj["lobby_code"] = game.lobby_code

    # Duration
    if game.game_start_ts and game.game_end_ts:
        dur = _format_duration(game.game_start_ts, game.game_end_ts)
        if dur:
            obj["duration"] = dur

    # End-game jokers
    if game.player_jokers:
        obj["player_jokers"] = game.player_jokers
    if game.nemesis_jokers:
        obj["nemesis_jokers"] = game.nemesis_jokers

    # End-game stats
    if game.player_stats:
        obj["player_stats"] = game.player_stats
    if game.nemesis_stats:
        obj["nemesis_stats"] = game.nemesis_stats

    # Shop spending per ante
    if game.shop_spending:
        obj["shop_spending"] = {
            str(k): v for k, v in sorted(game.shop_spending.items())
        }

    # Non-PvP round failures
    if game.failed_rounds:
        obj["failed_rounds"] = game.failed_rounds

    # Card activity
    if game.cards_bought:
        obj["cards_bought"] = game.cards_bought
    if game.cards_sold:
        obj["cards_sold"] = game.cards_sold
    if game.cards_used:
        obj["cards_used"] = game.cards_used

    return _compact_json(obj)


def _compact_json(obj, indent=2) -> str:
    """JSON with indent, but small objects/arrays collapsed to one line.

    Any value that serialises to <= *threshold* chars is kept on a single line,
    so arrays-of-small-dicts (hands, jokers, card activity) stay readable
    without burning vertical space.
    """
    threshold = 120

    def _fmt(value, level):
        if isinstance(value, dict):
            if not value:
                return "{}"
            # Try compact first
            compact = json.dumps(value, separators=(", ", ": "))
            if len(compact) <= threshold and "\n" not in compact:
                return compact
            # Expanded
            pad = " " * (indent * (level + 1))
            end_pad = " " * (indent * level)
            items = []
            for k, v in value.items():
                items.append(f"{pad}{json.dumps(k)}: {_fmt(v, level + 1)}")
            return "{\n" + ",\n".join(items) + "\n" + end_pad + "}"
        elif isinstance(value, list):
            if not value:
                return "[]"
            compact = json.dumps(value, separators=(", ", ": "))
            if len(compact) <= threshold and "\n" not in compact:
                return compact
            pad = " " * (indent * (level + 1))
            end_pad = " " * (indent * level)
            items = [f"{pad}{_fmt(v, level + 1)}" for v in value]
            return "[\n" + ",\n".join(items) + "\n" + end_pad + "]"
        else:
            return json.dumps(value)

    return _fmt(obj, 0)


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
        lines.append(
            f'{indent}{indent}{indent}["enemy_score"] = "{snap.enemy_score}",'
        )
        lines.append(
            f'{indent}{indent}{indent}["enemy_lives"] = {snap.enemy_lives},'
        )
        lines.append(
            f'{indent}{indent}{indent}["player_score"] = "{snap.player_score}",'
        )
        lines.append(
            f'{indent}{indent}{indent}["player_lives"] = {snap.player_lives},'
        )
        lines.append(f"{indent}{indent}}},")

    lines.append(f"{indent}}},")
    lines.append(f'{indent}["winner"] = "{game.winner or "unknown"}",')
    lines.append(f'{indent}["timestamp"] = {int(time.time())},')
    lines.append(
        f'{indent}["ruleset"] = "{game.ruleset or "ruleset_mp_blitz"}",'
    )
    lines.append(f'{indent}["seed"] = "{game.seed or "UNKNOWN"}",')
    lines.append(f'{indent}["deck"] = "{game.deck or "Red Deck"}",')
    lines.append(f'{indent}["stake"] = {game.stake or 1},')
    if game.player_name:
        lines.append(f'{indent}["player_name"] = "{game.player_name}",')
    if game.nemesis_name:
        lines.append(f'{indent}["nemesis_name"] = "{game.nemesis_name}",')
    lines.append("}")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def print_summary(game: GameRecord, idx: int = 0, total: int = 1):
    """Print a human-readable summary of a parsed game to stderr."""
    header = f"# Game {idx + 1}/{total}" if total > 1 else "# Parsed game"
    print(header, file=sys.stderr)
    print(f"#   Seed: {game.seed}", file=sys.stderr)
    print(f"#   Lobby: {game.lobby_code}", file=sys.stderr)
    print(f"#   Ruleset: {game.ruleset}", file=sys.stderr)
    print(f"#   Gamemode: {game.gamemode}", file=sys.stderr)
    print(f"#   Deck: {game.deck} (stake {game.stake})", file=sys.stderr)
    print(f"#   Player: {game.player_name}", file=sys.stderr)
    print(f"#   Nemesis: {game.nemesis_name}", file=sys.stderr)
    print(f"#   Winner: {game.winner}", file=sys.stderr)
    print(f"#   Final ante: {game.final_ante}", file=sys.stderr)

    if game.game_start_ts and game.game_end_ts:
        dur = _format_duration(game.game_start_ts, game.game_end_ts)
        if dur:
            print(f"#   Duration: {dur}", file=sys.stderr)

    print(
        f"#   PvP snapshots: {len(game.ante_snapshots)} antes", file=sys.stderr
    )
    for ante in sorted(game.ante_snapshots.keys()):
        s = game.ante_snapshots[ante]
        n_hands = len(s.hands)
        hand_info = f" ({n_hands} hand updates)" if n_hands else ""
        print(
            f"#     Ante {ante}: {s.result} | "
            f"player={s.player_score} ({s.player_lives}hp) vs "
            f"enemy={s.enemy_score} ({s.enemy_lives}hp){hand_info}",
            file=sys.stderr,
        )

    if game.failed_rounds:
        print(
            f"#   Failed non-PvP rounds at antes: {game.failed_rounds}",
            file=sys.stderr,
        )

    if game.player_jokers:
        jkeys = [j["key"] for j in game.player_jokers]
        print(f"#   Player jokers: {', '.join(jkeys)}", file=sys.stderr)
    if game.nemesis_jokers:
        jkeys = [j["key"] for j in game.nemesis_jokers]
        print(f"#   Nemesis jokers: {', '.join(jkeys)}", file=sys.stderr)

    if game.player_stats:
        print(f"#   Player stats: {game.player_stats}", file=sys.stderr)
    if game.nemesis_stats:
        print(f"#   Nemesis stats: {game.nemesis_stats}", file=sys.stderr)

    if game.shop_spending:
        total_spent = sum(game.shop_spending.values())
        print(f"#   Total shop spending: {total_spent}", file=sys.stderr)

    print(file=sys.stderr)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    filepath = sys.argv[1]
    output_format = "json"
    if "--lua" in sys.argv:
        output_format = "lua"

    games = process_log(filepath)

    if not games:
        print(f"# No complete games found in {filepath}", file=sys.stderr)
        sys.exit(1)

    for idx, game in enumerate(games):
        print_summary(game, idx, len(games))

    if output_format == "lua":
        for game in games:
            print(to_lua_table(game))
    else:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        replays_dir = os.path.join(script_dir, "..", "replays")
        os.makedirs(replays_dir, exist_ok=True)

        for idx, game in enumerate(games):
            seed = game.seed or "unknown"
            player = (game.player_name or "unknown").replace("~", "-")
            nemesis = (game.nemesis_name or "unknown").replace("~", "-")
            # Add index suffix when multiple games share the same names
            suffix = f"_{idx + 1}" if len(games) > 1 else ""
            filename = f"{seed}_{player}_vs_{nemesis}{suffix}.json"
            out_path = os.path.join(replays_dir, filename)

            with open(out_path, "w") as f:
                f.write(to_json(game))
                f.write("\n")

            print(f"Wrote {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
