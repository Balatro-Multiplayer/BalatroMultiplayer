function MP.UI.update_blind_HUD()
	if MP.LOBBY.code then
		G.HUD_blind.alignment.offset.y = -10
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 0.3,
			blockable = false,
			func = function()
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = MP.GAME.enemy
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = "score_text"
				G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.func = "multiplayer_blind_chip_UI_scale"
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text =
					localize("k_enemy_score")
				G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text =
					localize("k_enemy_hands")
				G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string =
					{ { ref_table = MP.GAME.enemy, ref_value = "hands" } }
				G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
				G.HUD_blind.alignment.offset.y = 0
				if G.GAME.blind.config.blind.key == "bl_mp_nemesis" then -- this was just the first place i thought of to implement this sprite swapping, change if inappropriate
					G.GAME.blind.children.animatedSprite.atlas = G.ANIMATION_ATLAS["mp_player_blind_col"]
					local nemesis_blind_col = MP.UTILS.get_nemesis_key()
					G.GAME.blind.children.animatedSprite:set_sprite_pos(G.P_BLINDS[nemesis_blind_col].pos)
				end
				return true
			end,
		}))
	end
end

function MP.UI.reset_blind_HUD()
	if MP.LOBBY.code then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string =
			{ { ref_table = G.GAME.blind, ref_value = "loc_name" } }
		G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:update_text()
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = G.GAME.blind
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = "chip_text"
		G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text =
			localize("ph_blind_score_at_least")
		G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text =
			localize("ph_blind_reward")
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string =
			{ { ref_table = G.GAME.current_round, ref_value = "dollars_to_be_earned" } }
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
	end
end

-- Contains function overrides (monkey-patches) for blind-related functionality
-- Overrides functions like get_blind_main_colour, Blind:change_colour, Blind:set_blind, etc.

local get_blind_main_colourref = get_blind_main_colour
function get_blind_main_colour(type) -- handles ui colour stuff
	local nemesis = G.GAME.round_resets.blind_choices[type] == "bl_mp_nemesis" or type == "bl_mp_nemesis"
	if nemesis then type = MP.UTILS.get_nemesis_key() end
	return get_blind_main_colourref(type)
end

local blind_change_colourref = Blind.change_colour
function Blind:change_colour(blind_col) -- ensures that small/big blinds have proper colouration
	local small = false
	if self.config.blind.key == "bl_mp_nemesis" then
		local blind_key = MP.UTILS.get_nemesis_key()
		if blind_key == "bl_small" or blind_key == "bl_big" then small = true end
	end
	local boss = self.boss
	if small then self.boss = false end
	blind_change_colourref(self, blind_col)
	self.boss = boss
end

local blind_set_blindref = Blind.set_blind
function Blind:set_blind(blind, reset, silent) -- hacking in proper spirals, far from good but whatever
	blind_set_blindref(self, blind, reset, silent)
	if (blind and blind.key == "bl_mp_nemesis") or (self and self.name and self.name == "bl_mp_nemesis") then -- this shouldn't break and this fix shouldn't work
		local boss = true
		local showdown = false
		local blind_key = MP.UTILS.get_nemesis_key()
		if blind_key == "bl_small" or blind_key == "bl_big" then boss = false end
		if blind_key == "bl_final_heart" then -- should be made generic
			showdown = true
		end
		G.ARGS.spin.real = (G.SETTINGS.reduced_motion and 0 or 1) * (boss and (showdown and 0.5 or 0.25) or 0)
	end
end

local ease_background_colour_blindref = ease_background_colour_blind
function ease_background_colour_blind(state, blind_override) -- handles background
	local blindname = (
		(blind_override or (G.GAME.blind and G.GAME.blind.name ~= "" and G.GAME.blind.name)) or "Small Blind"
	)
	local blindname = (blindname == "" and "Small Blind" or blindname)
	if blindname == "bl_mp_nemesis" then
		blind_override = MP.UTILS.get_nemesis_key()
		for k, v in pairs(G.P_BLINDS) do
			if blind_override == k then blind_override = v.name end
		end
	end
	return ease_background_colour_blindref(state, blind_override)
end

local add_round_eval_rowref = add_round_eval_row
function add_round_eval_row(config) -- if i could post a skull emoji i would, wtf is this (cashout screen)
	if config.name == "blind1" and G.GAME.blind.config.blind.key == "bl_mp_nemesis" then
		G.GAME.blind.chip_text = MP.INSANE_INT.to_string(MP.GAME.enemy.score)

		G.P_BLINDS["bl_mp_nemesis"].atlas = "mp_player_blind_col"
		G.GAME.blind.pos = G.P_BLINDS[MP.UTILS.get_nemesis_key()].pos -- this one is getting reset so no need to bother
		add_round_eval_rowref(config)
		G.E_MANAGER:add_event(Event({
			trigger = "before",
			delay = 0.0,
			func = function()
				G.P_BLINDS["bl_mp_nemesis"].atlas = "mp_player_blind_chip" -- lmao
				return true
			end,
		}))
	else
		add_round_eval_rowref(config)
	end
end

local blind_defeat_ref = Blind.defeat
function Blind:defeat(silent)
	blind_defeat_ref(self, silent)
	if MP.LOBBY.code and MP.UI.reset_blind_HUD then MP.UI.reset_blind_HUD() end
end

local blind_disable_ref = Blind.disable
function Blind:disable()
	if MP.is_pvp_boss() and not (G.GAME.blind and G.GAME.blind.name == "Verdant Leaf") then -- hackfix to make verdant work properly
		return
	end
	blind_disable_ref(self)
end

G.FUNCS.multiplayer_blind_chip_UI_scale = function(e)
	local new_score_text = MP.INSANE_INT.to_string(MP.GAME.enemy.score)
	if G.GAME.blind and MP.GAME.enemy.score and MP.GAME.enemy.score_text ~= new_score_text then
		if not MP.INSANE_INT.greater_than(MP.GAME.enemy.score, MP.INSANE_INT.create(0, G.E_SWITCH_POINT, 0)) then
			e.config.scale = scale_number(MP.GAME.enemy.score.coeffiocient, 0.7, 100000)
		end
		MP.GAME.enemy.score_text = new_score_text
	end
end

function MP.UI.juice_up_pvp_hud()
	if MP.is_pvp_boss() then
		G.HUD_blind:get_UIE_by_ID("HUD_blind_count"):juice_up()
		G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned"):juice_up()
	end
end
