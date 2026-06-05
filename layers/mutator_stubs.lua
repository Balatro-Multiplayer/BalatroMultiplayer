-- Stubbed mutator layers (yellow knobs — registered but inert).
--
-- These need real hooks, not just data. They're registered so they exist in the
-- layer system and can be composed/selected, but they currently do nothing.
-- Each note records the intended behavior and the seam it'll hook.

-- PvP REWARD DRAFT ⭐
-- Beat a PvP blind -> pick 1 of N rewards (joker / tarot / $ / voucher).
-- Local-only effect (opponent's deck isn't simulated locally), so MP-safe; seed
-- the offered choices off (lobby seed + ante + player) for reproducible fairness.
-- Seam: the endPvP / PvP-blind-win path in networking + ui/game.
MP.Layer("pvp_reward_draft", {})

-- RUBBER-BAND
-- Losing a life grants an escalating buff (comeback mechanic for casual lobbies).
-- Seam: the life-loss path (action_set_lives / ease_lives).
MP.Layer("rubber_band", {})

-- SCORE TAX
-- Every hand you play nudges your opponent's target up slightly. Pure pressure.
-- Seam: rides the existing playHand / enemy-score sync.
MP.Layer("score_tax", {})
