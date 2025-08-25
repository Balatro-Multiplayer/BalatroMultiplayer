SMODS.Challenge({
	key = "balancing_act",
	rules = {
		custom = {
			{ id = "mp_score_instability" },
			{ id = "mp_score_instability_EXAMPLE" }, -- ?????????????????????
			{ id = "mp_score_instability_LOC1" },
			{ id = "mp_score_instability_LOC2" },
			{ id = "mp_ante_scaling", value = 0.25 }, -- this would be in modifiers table if it actually worked
		},
	},
	unlocked = function(self)
		return true
	end,
})

-- put hook here ig
local bte_ref = Back.trigger_effect
function Back:trigger_effect(args)
	if G.GAME.modifiers.mp_score_instability and args.context == "final_scoring_step" then -- me when i copy plasma deck
		local diff = args.chips - args.mult
		if diff > 0 then
			diff = math.min(diff, args.mult - 1)
		elseif diff < 0 then
			diff = math.max(diff, -args.chips)
		end
		args.chips = args.chips + diff
		args.mult = args.mult - diff
		update_hand_text({ delay = 0 }, { mult = args.mult, chips = args.chips })

		G.E_MANAGER:add_event(Event({
			func = function()
				local text = localize("k_destabilized")
				play_sound("timpani", 0.5 / 1.5, 0.4)
				play_sound("timpani", 0.5, 0.5)
				play_sound("timpani", 0.5 * 1.5, 0.6)
				play_sound("tarot1", 1.5)
				ease_colour(G.C.UI_CHIPS, G.C.PERISHABLE)
				ease_colour(G.C.UI_MULT, G.C.ETERNAL)
				attention_text({
					scale = 1.4,
					text = text,
					hold = 2,
					align = "cm",
					offset = { x = 0, y = -2.7 },
					major = G.play,
				})
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					blockable = false,
					blocking = false,
					delay = 4.3,
					func = function()
						ease_colour(G.C.UI_CHIPS, G.C.BLUE, 2)
						ease_colour(G.C.UI_MULT, G.C.RED, 2)
						return true
					end,
				}))
				G.E_MANAGER:add_event(Event({
					trigger = "after",
					blockable = false,
					blocking = false,
					no_delete = true,
					delay = 6.3,
					func = function()
						G.C.UI_CHIPS[1], G.C.UI_CHIPS[2], G.C.UI_CHIPS[3], G.C.UI_CHIPS[4] =
							G.C.BLUE[1], G.C.BLUE[2], G.C.BLUE[3], G.C.BLUE[4]
						G.C.UI_MULT[1], G.C.UI_MULT[2], G.C.UI_MULT[3], G.C.UI_MULT[4] =
							G.C.RED[1], G.C.RED[2], G.C.RED[3], G.C.RED[4]
						return true
					end,
				}))
				return true
			end,
		}))
		delay(0.6)
		return args.chips, args.mult
	end
	return bte_ref(self, args)
end
