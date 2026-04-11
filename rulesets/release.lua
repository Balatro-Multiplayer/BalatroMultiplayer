-- reverts gameplay-related changes in the game to the 1.0.0 release version
--[[
MP.Ruleset({
	key = "release",
	multiplayer_content = false,
	banned_jokers = {},
	banned_consumables = {},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = {},
	banned_blinds = {},
	reworked_jokers = {},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {},
	reworked_tags = {},
	reworked_blinds = {},
	create_info_menu = function()
		return MP.UI.CreateRulesetInfoMenu({
			multiplayer_content = false,
			forced_lobby_options = false,
			description_key = "k_release_description",
		})
	end,
}):inject()

SMODS.Atlas({
	key = "release_jokers",
	path = "release_jokers.png",
	px = 71,
	py = 95,
})

MP.ReworkCenter("j_greedy_joker", {
	rulesets = "release",
	config = {extra = {s_mult = 4, suit = 'Diamonds'}},
})

MP.ReworkCenter("j_lusty_joker", {
	rulesets = "release",
	config = {extra = {s_mult = 4, suit = 'Hearts'}},
})

MP.ReworkCenter("j_wrathful_joker", {
	rulesets = "release",
	config = {extra = {s_mult = 4, suit = 'Spades'}},
})

MP.ReworkCenter("j_gluttenous_joker", {
	rulesets = "release",
	config = {extra = {s_mult = 4, suit = 'Clubs'}},
})

MP.ReworkCenter("j_mad", {
	rulesets = "release",
	config = {t_mult = 20, type = 'Four of a Kind'},
	atlas = "mp_release_jokers",
})

MP.ReworkCenter("j_clever", {
	rulesets = "release",
	config = {t_chips = 150, type = 'Four of a Kind'},
	atlas = "mp_release_jokers",
})

MP.ReworkCenter("j_banner", {
	rulesets = "release",
	config = {extra = 40},
})

MP.ReworkCenter("j_8_ball", {
	rulesets = "release",
	loc_key = "j_mp_8ball_release",
	config = {extra = 2},
	atlas = "mp_release_jokers",
	loc_vars = function(self, info_queue, card)
		return {
			vars = { card.ability.extra },
		}
	end,
	calculate = function(self, card, context)
		if context.individual then -- stops regular 8ball calculates... eh
			return nil, true
		end
		if context.joker_main then
			if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
				local eights = 0
				for i = 1, #context.full_hand do
					if context.full_hand[i]:get_id() == 8 then eights = eights + 1 end
				end
				if eights >= card.ability.extra then
					G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
					G.E_MANAGER:add_event(Event({
						trigger = 'before',
						delay = 0.0,
						func = (function()
							local card = create_card('Planet',G.consumeables, nil, nil, nil, nil, nil, '8ba')
							card:add_to_deck()
							G.consumeables:emplace(card)
							G.GAME.consumeable_buffer = 0
							return true
						end)
					}))
					return {
						message = localize('k_plus_planet'),
						colour = G.C.SECONDARY_SET.Planet,
						card = card
					}
				end
			end
		end
	end
})

MP.ReworkCenter("j_fibonacci", {
	rulesets = "release",
	cost = 7,
})

MP.ReworkCenter("j_steel_joker", {
	rulesets = "release",
	config = {extra = 0.25},
})

MP.ReworkCenter("j_gros_michel", {
	rulesets = "release",
	config = {extra = {odds = 4, mult = 15}},
})

MP.ReworkCenter("j_odd_todd", {
	rulesets = "release",
	config = {extra = 30},
})

MP.ReworkCenter("j_runner", {
	rulesets = "release",
	config = {extra = {chips = 20, chip_mod = 10}},
})

MP.ReworkCenter("j_sixth_sense", {
	rulesets = "release",
	rarity = 3,
})

MP.ReworkCenter("j_hiker", {
	rulesets = "release",
	config = {extra = 4},
})

MP.ReworkCenter("j_todo_list", {
	rulesets = "release",
	loc_key = "j_mp_todo_list_release",
	config = {extra = {dollars = 5, poker_hand = 'High Card'}},
	calculate = function(self, card, context)
		if context.end_of_round then -- stops to-do list from changing
			return nil, true
		end
		if context.before then
			if context.scoring_name == card.ability.to_do_poker_hand then
				-- bad hand selection system (thanks thunk) but who really gaf
				G.E_MANAGER:add_event(Event({
					func = function()
						local _poker_hands = {}
						for k, v in pairs(G.GAME.hands) do
							if v.visible and k ~= card.ability.to_do_poker_hand then _poker_hands[#_poker_hands+1] = k end
						end
						card.ability.to_do_poker_hand = pseudorandom_element(_poker_hands, pseudoseed('to_do'))
						return true
					end
				}))
				G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
				G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
				return {
					dollars = card.ability.extra.dollars
				}
			end
			return nil, true
		end
	end
})

MP.ReworkCenter("j_madness", {
	rulesets = "release",
	loc_key = "j_mp_madness_release",
	calculate = function(self, card, context)
		if context.setting_blind and not context.blueprint then
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
			local destructable_jokers = {}
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] ~= card and not G.jokers.cards[i].ability.eternal and not G.jokers.cards[i].getting_sliced then destructable_jokers[#destructable_jokers+1] = G.jokers.cards[i] end
			end
			local joker_to_destroy = #destructable_jokers > 0 and pseudorandom_element(destructable_jokers, pseudoseed('madness')) or nil

			if joker_to_destroy and not (context.blueprint_card or card).getting_sliced then 
				joker_to_destroy.getting_sliced = true
				G.E_MANAGER:add_event(Event({func = function()
					(context.blueprint_card or card):juice_up(0.8, 0.8)
					joker_to_destroy:start_dissolve({G.C.RED}, nil, 1.6)
				return true end }))
			end
			if not (context.blueprint_card or card).getting_sliced then
				card_eval_status_text((context.blueprint_card or card), 'extra', nil, nil, nil, {message = localize{type = 'variable', key = 'a_xmult', vars = {card.ability.x_mult}}})
			end
			return nil, true
		end
	end
})

MP.ReworkCenter("j_square", {
	rulesets = "release",
	config = {extra = {chips = 16, chip_mod = 4}},
	cost = 5,
	atlas = "mp_release_jokers",
})

-- prevent size changing shenanigans due to altered sprite
local card_set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
	if center == G.P_CENTERS["j_square"] and center.atlas == "mp_release_jokers" then
		center.name = "Square Joker OVERRIDE"
	end
	local ret = card_set_ability_ref(self, center, initial, delay_sprites)
	if center == G.P_CENTERS["j_square"] and center.atlas == "mp_release_jokers" then
		self.ability.name = "Square Joker"
		center.name = "Square Joker"
	end
	return ret
end

MP.ReworkCenter("j_seance", {
	rulesets = "release",
	rarity = 3,
	cost = 7,
})

MP.ReworkCenter("j_riff_raff", {
	rulesets = "release",
	cost = 4,
})

MP.ReworkCenter("j_vampire", {
	rulesets = "release",
	loc_key = "j_mp_vampire_release",
	config = {extra = 0.2, Xmult = 1},
	calculate = function(self, card, context)
		-- this one is copied from vremade instead of vanilla
		if context.before and not context.blueprint then
			local enhanced = {}
			for _, scored_card in ipairs(context.full_hand) do
				if next(SMODS.get_enhancements(scored_card)) and not scored_card.debuff and not scored_card.vampired then
					enhanced[#enhanced + 1] = scored_card
					scored_card.vampired = true
					scored_card:set_ability('c_base', nil, true)
					G.E_MANAGER:add_event(Event({
						func = function()
							scored_card:juice_up()
							scored_card.vampired = nil
							return true
						end
					}))
				end
			end
			if #enhanced > 0 then
				card.ability.Xmult = card.ability.Xmult + card.ability.extra * #enhanced
				return {
					message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.Xmult } },
					colour = G.C.MULT
				}
			end
			return nil, true
		end
	end,
})

MP.ReworkCenter("j_vagabond", {
	rulesets = "release",
	rarity = 2,
	config = {extra = 3},
	cost = 6,
})

MP.ReworkCenter("j_cloud_9", {
	rulesets = "release",
	cost = 6,
})

MP.ReworkCenter("j_midas_mask", {
	rulesets = "release",
	loc_key = "j_mp_midas_mask_release",
	cost = 6,
	calculate = function(self, card, context)
		-- this one is ALSO copied from vremade instead of vanilla
		if context.before and not context.blueprint then
			local faces = 0
			for _, scored_card in ipairs(context.full_hand) do
				if scored_card:is_face() then
					faces = faces + 1
					scored_card:set_ability('m_gold', nil, true)
					G.E_MANAGER:add_event(Event({
						func = function()
							scored_card:juice_up()
							return true
						end
					}))
				end
			end
			if faces > 0 then
				return {
					message = localize('k_gold'),
					colour = G.C.MONEY
				}
			end
			return nil, true
		end
	end,
})

MP.ReworkCenter("j_luchador", {
	rulesets = "release",
	eternal_compat = true, -- ok
})

MP.ReworkCenter("j_reserved_parking", {
	rulesets = "release",
	rarity = 2,
})

MP.ReworkCenter("j_mail", {
	rulesets = "release",
	config = {extra = 3},
})

MP.ReworkCenter("j_lucky_cat", {
	rulesets = "release",
	config = {Xmult = 1, extra = 0.2},
})

MP.ReworkCenter("j_trading", {
	rulesets = "release",
	cost = 5,
})

MP.ReworkCenter("j_smiley", {
	rulesets = "release",
	config = {extra = 4},
})

MP.ReworkCenter("j_campfire", {
	rulesets = "release",
	config = {extra = 0.5},
})

MP.ReworkCenter("j_ticket", {
	rulesets = "release",
	config = {extra = 3},
})

MP.ReworkCenter("j_swashbuckler", {
	rulesets = "release",
	loc_key = "j_mp_swashbuckler_release",
	config = {mult = 1, release = true},
})

local card_update_ref = Card.update
function Card:update(dt)
	card_update_ref(self, dt)
	if G.STAGE == G.STAGES.RUN then
		if self.ability.name == "Swashbuckler" and self.ability.release then
			local sell_cost = 0
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == self or (self.area and (self.area ~= G.jokers)) then break end
				sell_cost = sell_cost + G.jokers.cards[i].sell_cost
			end
			self.ability.mult = sell_cost
		end
	end
end

MP.ReworkCenter("j_hanging_chad", {
	rulesets = "release",
	loc_key = "j_mp_hanging_chad_release",
	config = {extra = 1},
})

MP.ReworkCenter("j_bloodstone", {
	rulesets = "release",
	config = {extra = {odds = 3, Xmult = 2}},
})

MP.ReworkCenter("j_onyx_agate", {
	rulesets = "release",
	config = {extra = 8},
})

MP.ReworkCenter("j_glass", {
	rulesets = "release",
	config = {extra = 0.5, Xmult = 1},
})

MP.ReworkCenter("j_flower_pot", {
	rulesets = "release",
	loc_key = "j_mp_flower_pot_release",
	calculate = function(self, card, context)
		if context.joker_main then
			local suits = {
				['Hearts'] = 0,
				['Diamonds'] = 0,
				['Spades'] = 0,
				['Clubs'] = 0
			}
			for i = 1, #context.scoring_hand do
				if context.scoring_hand[i].ability.name ~= 'Wild Card' then
					if context.scoring_hand[i]:is_suit('Hearts') and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
					elseif context.scoring_hand[i]:is_suit('Diamonds') and suits["Diamonds"] == 0  then suits["Diamonds"] = suits["Diamonds"] + 1
					elseif context.scoring_hand[i]:is_suit('Spades') and suits["Spades"] == 0  then suits["Spades"] = suits["Spades"] + 1
					elseif context.scoring_hand[i]:is_suit('Clubs') and suits["Clubs"] == 0  then suits["Clubs"] = suits["Clubs"] + 1 end
				end
			end
			for i = 1, #context.scoring_hand do
				if context.scoring_hand[i].ability.name == 'Wild Card' then
					if context.scoring_hand[i]:is_suit('Hearts') and suits["Hearts"] == 0 then suits["Hearts"] = suits["Hearts"] + 1
					elseif context.scoring_hand[i]:is_suit('Diamonds') and suits["Diamonds"] == 0  then suits["Diamonds"] = suits["Diamonds"] + 1
					elseif context.scoring_hand[i]:is_suit('Spades') and suits["Spades"] == 0  then suits["Spades"] = suits["Spades"] + 1
					elseif context.scoring_hand[i]:is_suit('Clubs') and suits["Clubs"] == 0  then suits["Clubs"] = suits["Clubs"] + 1 end
				end
			end
			if suits["Hearts"] > 0 and
			suits["Diamonds"] > 0 and
			suits["Spades"] > 0 and
			suits["Clubs"] > 0 then
				return {
					message = localize{type='variable',key='a_xmult',vars={card.ability.extra}},
					Xmult_mod = card.ability.extra
				}
			end
			return nil, true
		end
	end,
})

MP.ReworkCenter("j_wee", {
	rulesets = "release",
	config = {extra = {chips = 10, chip_mod = 8}},
})

MP.ReworkCenter("j_stuntman", {
	rulesets = "release",
	rarity = 2,
	config = {extra = {h_size = 2, chip_mod = 300}},
	cost = 6,
})

MP.ReworkCenter("j_invisible", {
	rulesets = "release",
	config = {extra = 3},
	cost = 10,
})

MP.ReworkCenter("j_burnt", {
	rulesets = "release",
	rarity = 2,
	cost = 6,
})

MP.ReworkCenter("j_yorick", {
	rulesets = "release",
	loc_key = "j_mp_yorick_release",
	config = {extra = {xmult = 5, discards = 23}},
	calculate = function(self, card, context)
		if context.discard then
			if card.ability.yorick_discards > 0 and not card.ability.yorick_tallied and not context.blueprint then
				card.ability.yorick_tallied = true
				G.E_MANAGER:add_event(Event({
					func = function()
						card.ability.yorick_tallied = nil
						card.ability.yorick_discards = card.ability.yorick_discards - 1
						if card.ability.yorick_discards == 0 then
							card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize('k_active_ex'),colour = G.C.FILTER, delay = 0.45})
						else
							card_eval_status_text(card, 'extra', nil, nil, nil, {message = localize{type='variable',key='a_remaining',vars={card.ability.yorick_discards}},colour = G.C.FILTER, delay = 0.45})
						end
						return true
					end
				}))
			end
			return nil, true
		end
		if context.joker_main then
			if card.ability.yorick_discards <= 0 then
				return {
					xmult = card.ability.extra.xmult
				}
			end
			return nil, true
		end
	end,
})

MP.ReworkCenter("c_magician", {
	rulesets = "release",
	loc_key = "c_mp_magician_release",
	config = {mod_conv = "m_lucky", max_highlighted = 1},
	-- don't understand why we need to redefine loc_vars here
	loc_vars = function(self, info_queue, card)
		info_queue[#info_queue+1] = G.P_CENTERS[self.config.mod_conv]
		return {
			vars = { self.config.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = self.config.mod_conv} },
		}
	end,
})

MP.ReworkCenter("tag_uncommon", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_uncommon_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_create' then
			local card = create_card('Joker', context.area, nil, 0.9, nil, nil, nil, 'uta')
			create_shop_card_ui(card, 'Joker', context.area)
			card.states.visible = false
			tag:yep('+', G.C.GREEN,function() 
				card:start_materialize()
				return true
			end)
			tag.triggered = true
			return card
		end
	end,
})

MP.ReworkCenter("tag_rare", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_rare_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_create' then
			local card = nil
			local rares_in_posession = {0}
			for k, v in ipairs(G.jokers.cards) do
				if v.config.center.rarity == 3 and not rares_in_posession[v.config.center.key] then
					rares_in_posession[1] = rares_in_posession[1] + 1 
					rares_in_posession[v.config.center.key] = true
				end
			end

			if #G.P_JOKER_RARITY_POOLS[3] > rares_in_posession[1] then 
				card = create_card('Joker', context.area, nil, 1, nil, nil, nil, 'rta')
				create_shop_card_ui(card, 'Joker', context.area)
				card.states.visible = false
				tag:yep('+', G.C.RED,function() 
					card:start_materialize()
					return true
				end)
			else
				tag:nope()
			end
			tag.triggered = true
			return card
		end
	end,
})

MP.ReworkCenter("tag_negative", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_negative_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_modify' and not context.card.edition and not context.card.temp_edition and context.card.ability.set == 'Joker' then
			local lock = tag.ID
			G.CONTROLLER.locks[lock] = true
			context.card.temp_edition = true
			tag:yep('+', G.C.DARK_EDITION,function() 
				context.card.temp_edition = nil
				context.card:set_edition({negative = true}, true)
				G.CONTROLLER.locks[lock] = nil
				return true
			end)
			tag.triggered = true
			return true
		end
	end,
})

MP.ReworkCenter("tag_foil", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_foil_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_modify' and not context.card.edition and not context.card.temp_edition and context.card.ability.set == 'Joker' then
			local lock = tag.ID
			G.CONTROLLER.locks[lock] = true
			context.card.temp_edition = true
			tag:yep('+', G.C.DARK_EDITION,function() 
				context.card.temp_edition = nil
				context.card:set_edition({foil = true}, true)
				G.CONTROLLER.locks[lock] = nil
				return true
			end)
			tag.triggered = true
			return true
		end
	end,
})

MP.ReworkCenter("tag_holo", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_holo_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_modify' and not context.card.edition and not context.card.temp_edition and context.card.ability.set == 'Joker' then
			local lock = tag.ID
			G.CONTROLLER.locks[lock] = true
			context.card.temp_edition = true
			tag:yep('+', G.C.DARK_EDITION,function() 
				context.card.temp_edition = nil
				context.card:set_edition({holo = true}, true)
				G.CONTROLLER.locks[lock] = nil
				return true
			end)
			tag.triggered = true
			return true
		end
	end,
})

MP.ReworkCenter("tag_polychrome", {
	rulesets = "release",
	center_table = "P_TAGS",
	loc_key = "tag_mp_poly_release",
	apply = function(self, tag, context)
		if context.type == 'store_joker_modify' and not context.card.edition and not context.card.temp_edition and context.card.ability.set == 'Joker' then
			local lock = tag.ID
			G.CONTROLLER.locks[lock] = true
			context.card.temp_edition = true
			tag:yep('+', G.C.DARK_EDITION,function() 
				context.card.temp_edition = nil
				context.card:set_edition({polychrome = true}, true)
				G.CONTROLLER.locks[lock] = nil
				return true
			end)
			tag.triggered = true
			return true
		end
	end,
})

-- i don't like having to do this
-- no idea if this breaks anything
for k, v in ipairs({
	"tag_uncommon",
	"tag_rare",
	"tag_negative",
	"tag_foil",
	"tag_holo",
	"tag_polychrome",
}) do
	SMODS.Tags[v] = G.P_TAGS[v]
end

MP.ReworkCenter("tag_investment", {
	rulesets = "release",
	center_table = "P_TAGS",
	config = {type = 'eval', dollars = 15},
})

MP.ReworkCenter("Blue", {
	rulesets = "release",
	center_table = "P_SEALS",
	release = true,
	loc_key = "mp_blue_seal_release",
})

local card_get_end_of_round_effect_ref = Card.get_end_of_round_effect
function Card:get_end_of_round_effect(context)
	if self.seal == "Blue" and G.P_SEALS["Blue"].release then
		self.seal = "Not Blue Lmao"
	end
	local ret = card_get_end_of_round_effect_ref(self, context)
	if self.seal == "Not Blue Lmao" then
		if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
			local card_type = 'Planet'
			G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
			G.E_MANAGER:add_event(Event({
				trigger = 'before',
				delay = 0.0,
				func = (function()
					local card = create_card(card_type,G.consumeables, nil, nil, nil, nil, nil, 'blusl')
					card:add_to_deck()
					G.consumeables:emplace(card)
					G.GAME.consumeable_buffer = 0
					return true
				end)
			}))
			card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_plus_planet'), colour = G.C.SECONDARY_SET.Planet})
			ret.effect = true
		end
		self.seal = "Blue"
	end
	return ret
end

MP.ReworkCenter("Straight", {
	rulesets = "release",
	center_table = SMODS.PokerHands,
	l_mult = 2,
})

-- no behaviour change, just so it shows the sticker
MP.ReworkCenter("c_saturn", {
	rulesets = "release"
})

MP.ReworkCenter("Straight Flush", {
	rulesets = "release",
	center_table = SMODS.PokerHands,
	l_mult = 3,
})

MP.ReworkCenter("c_neptune", {
	rulesets = "release",
})

MP.ReworkCenter("Flush House", {
	rulesets = "release",
	center_table = SMODS.PokerHands,
	l_mult = 3,
})

MP.ReworkCenter("c_ceres", {
	rulesets = "release",
})

MP.ReworkCenter("Flush Five", {
	rulesets = "release",
	center_table = SMODS.PokerHands,
	l_chips = 40,
})

MP.ReworkCenter("c_eris", {
	rulesets = "release",
})

MP.ReworkCenter("stake_green", {
	rulesets = "release",
	center_table = "P_STAKES",
	modifiers = function()
		G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
		G.GAME.mp_release_scaling = "green"
	end,
})

MP.ReworkCenter("stake_purple", {
	rulesets = "release",
	center_table = "P_STAKES",
	modifiers = function()
		G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
		G.GAME.mp_release_scaling = "purple"
	end,
})

local get_blind_amount_ref = get_blind_amount
function get_blind_amount(ante)
	if G.GAME.mp_release_scaling then
		-- if green then
		local amounts = {
			300,  1000, 3200,  9000,  18000,  32000,  56000,  90000
		}
		if G.GAME.mp_release_scaling == "purple" then
			amounts = {
				300,  1200, 3600,  10000,  25000,  50000,  90000,  180000
			}
		end
		if ante < 1 then return 100 end
		if ante <= 8 then return amounts[ante] end
		local a, b, c, d = amounts[8],1.6,ante-8, 1 + 0.2*(ante-8)
		local amount = math.floor(a*(b+(0.75*c)^d)^c)
		amount = amount - amount%(10^math.floor(math.log10(amount)-1))
		return amount
	end
	return get_blind_amount_ref(ante)
end

MP.ReworkCenter("stake_orange", {
	rulesets = "release",
	center_table = "P_STAKES",
	loc_key = "stake_mp_orange_release",
	modifiers = function()
		G.GAME.modifiers.booster_ante_scaling = true
	end,
})

MP.ReworkCenter("stake_gold", {
	rulesets = "release",
	center_table = "P_STAKES",
	loc_key = "stake_mp_gold_release",
	modifiers = function()
		G.GAME.starting_params.hand_size = G.GAME.starting_params.hand_size - 1
	end,
})

-- there's an incredibly obscure crash directly caused by adding any sort of function or recursive table to the blind center, so this will crash the game even if the ruleset isn't loaded. i cba to figure out why at this point
MP.ReworkCenter("bl_arm", {
	rulesets = "release",
	center_table = "P_BLINDS",
	debuff_hand = function(self, cards, hand, handname, check)
		if G.GAME.hands[handname].level > 0 then
			G.GAME.blind.triggered = true
			if not check then
				level_up_hand(G.GAME.blind.children.animatedSprite, handname, nil, -1)
				G.GAME.blind:wiggle()
			end
		end
	end,
})
]]
