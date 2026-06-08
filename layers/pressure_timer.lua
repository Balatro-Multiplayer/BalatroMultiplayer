-- Pressure-timer layer: the timer ticks down starting on each ante. 
-- Calculate costs timer time. Timering your
-- opponent (press while ahead) drains their clock at 2x.
-- Base timer doubled (timer_base_multiplier = 2) so feel-time
-- roughly matches the longer effective rounds.
MP.Layer("pressure_timer", {
    preview_calculate_delay = 1.5,
    preview_calculate_cost = 3.5,
    timer_speedup_multiplier = 2,
    timer_base_multiplier = 2,
})

MP.Layer("pressure_timer_plus", {
    timer_hand_played_increment_seconds = 15
})