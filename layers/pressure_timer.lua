-- Pressure-timer layer: makes the PvP timer apply pressure throughout the round
-- (not just during PvP boss). Calculate-button costs timer time. Timer accelerates
-- 2x while the nemesis is playing. Base timer scaled by 5/3 so feel-time roughly
-- matches the longer effective rounds.
MP.Layer("pressure_timer", {
    preview_calculate_delay = 1.5,
    preview_calculate_cost = 3.5,
    timer_speedup_multiplier = 2,
    timer_base_multiplier = 5 / 3,
})
