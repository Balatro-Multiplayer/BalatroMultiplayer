-- Manhunt Hunter/Runner "blinds": pure reskin sprite sources for the ONE actually-
-- played PvP boss blind (bl_mp_nemesis, objects/blinds/nemesis.lua) -- see
-- PVP.UTILS.get_nemesis_key() (lib/ui.lua), which paints one of these atlases onto
-- bl_mp_nemesis depending on role. Bare SMODS.Blind (not MPAPI.Blind: these are
-- never actually played, so they need none of MPAPI.Blind's sync-bus/phantom
-- plumbing), never in_pool, discovered so the collection screen doesn't nag about
-- them. Art from /home/virtualized/Projects/Fiverr/Nightmare-Manhunt (same author's
-- earlier Manhunt mod).
SMODS.Atlas({
	key = "manhunt_hunter_blind_chip",
	path = "manhunt_hunter_blind_row.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

SMODS.Atlas({
	key = "manhunt_runner_blind_chip",
	path = "manhunt_runner_blind_row.png",
	atlas_table = "ANIMATION_ATLAS",
	frames = 21,
	px = 34,
	py = 34,
})

SMODS.Blind({
	key = "manhunt_hunter",
	dollars = 5,
	mult = 1,
	boss_colour = G.C.RED,
	boss = { min = 1, max = 10 },
	atlas = "manhunt_hunter_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,
})

SMODS.Blind({
	key = "manhunt_runner",
	dollars = 5,
	mult = 1,
	boss_colour = G.C.BLUE,
	boss = { min = 1, max = 10 },
	atlas = "manhunt_runner_blind_chip",
	discovered = true,
	in_pool = function(self)
		return false
	end,
})
