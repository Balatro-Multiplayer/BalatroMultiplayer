function oracle_apply_dollar_cap(mod, current_dollars, max_dollars)
	return math.min(max_dollars - current_dollars, mod)
end

function oracle_should_show_max(mod, current_dollars, max_dollars)
	return mod == 0 and current_dollars >= max_dollars
end

function oracle_show_max_alert(dollar_UI)
	attention_text({
		text = "MAX",
		scale = 0.8,
		hold = 0.7,
		cover = dollar_UI.parent,
		cover_colour = G.C.RED,
		align = "cm",
	})
	play_sound("timpani", 0.9, 0.7)
	play_sound("timpani", 1.2, 0.7)
end

SMODS.Back({
	key = "oracle",
	config = { vouchers = { "v_clearance_sale" }, consumables = { "c_medium" } },
	atlas = "mp_decks",
	pos = { x = 1, y = 1 },
	apply = function(self)
		G.GAME.modifiers.oracle_max = 50
	end,
	mp_credits = { art = { "aura!", "Ganpan140" }, code = { "Toneblock" } },
})
