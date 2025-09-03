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

-- billionth create card hook ever
local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
	if G.GAME.modifiers.oracle_max then
		local lmod = (G.GAME.dollar_buffer or 0) > 0 and mod or 0 -- this whole thing is really uncomfortable but seems to work
		local dollars = G.GAME.dollars + ((G.GAME.dollar_buffer or 0) - lmod)
		if mod >= 0 and dollars >= G.GAME.modifiers.oracle_max then -- recreate the function for max anim
			local function _mod()
				local dollar_UI = G.HUD:get_UIE_by_ID("dollar_text_UI")
				dollar_UI.config.object:update()
				G.HUD:recalculate()
				attention_text({
					text = "MAX",
					scale = 0.8,
					hold = 0.7,
					cover = dollar_UI.parent,
					cover_colour = G.C.RED,
					align = "cm",
				})
				play_sound("timpani", 0.9, 0.7) -- timpani spam makes good sfx
				play_sound("timpani", 1.2, 0.7)
			end
			if instant then
				_mod()
			else
				G.E_MANAGER:add_event(Event({
					trigger = "immediate",
					func = function()
						_mod()
						return true
					end,
				}))
			end
			return
		else
			mod = math.min(mod, G.GAME.modifiers.oracle_max - dollars)
		end
	end
	return ease_dollars_ref(mod, instant)
end
