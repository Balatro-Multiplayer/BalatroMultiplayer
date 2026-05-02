SMODS.Back({
	key = "indigo",
	config = {},
	atlas = "mp_decks",
	pos = { x = 1, y = 0 },
	mp_credits = { art = { "aura!" }, code = { "Toneblock" } },
	apply = function(self)
		G.GAME.modifiers.mp_indigo = true
		G.GAME.modifiers.booster_choice_mod = (G.GAME.modifiers.booster_choice_mod or 0) + 1
		G.GAME.banned_keys["j_red_card"] = true
	end,
})

local function check_joker_space(card)
	if card.config.center.set == "Joker" and card.edition and card.edition.negative then return true end
	local c = 0
	local un_c = G.jokers.config.card_limit
	for i, v in ipairs(G.jokers.cards) do
		if v.edition and v.edition.type == "negative" then
			un_c = un_c - 1
		elseif v.ability.eternal then
			c = c + 1
		else
			break
		end
	end
	return c < un_c
end

local function is_usable(card)
	local center = card.config.center
	local key = center.key
	if center.set == "Enhanced" or center.set == "Default" or center.set == "Planet" then
		return true
	elseif center.set == "Joker" then
		return check_joker_space(card)
	elseif center.set == "Tarot" then
		if key == "c_fool" then
			return G.GAME.last_tarot_planet and G.GAME.last_tarot_planet ~= "c_fool"
		elseif key == "c_judgement" then
			return check_joker_space(card)
		elseif key == "c_wheel_of_fortune" then
			if card.eligible_strength_jokers and next(card.eligible_strength_jokers) then return true end
			return false
		elseif card.ability.consumeable.max_highlighted then
			if #G.hand.cards >= (card.ability.consumeable.min_highlighted or 1) then return true end
			return false
		else
			return true
		end
	elseif center.set == "Spectral" then
		if
			key == "c_familiar"
			or key == "c_grim"
			or key == "c_incantation"
			or key == "c_immolate"
			or key == "c_sigil"
			or key == "c_ouija"
		then
			if #G.hand.cards > 1 then -- vanilla bug?
				return true
			end
			return false
		elseif key == "c_aura" then
			local bool = false
			for i, v in ipairs(G.hand.cards) do
				if not v.edition then
					bool = true
					break
				end
			end
			return bool
		elseif key == "c_ectoplasm" or key == "c_hex" then
			if card.eligible_editionless_jokers and next(card.eligible_editionless_jokers) then return true end
			return false
		elseif key == "c_wraith" or key == "c_soul" then
			return check_joker_space(card)
		elseif key == "c_ankh" then
			if G.jokers.cards[1] then return check_joker_space(card) end
			return false
		elseif card.ability.consumeable.max_highlighted then
			if #G.hand.cards >= (card.ability.consumeable.min_highlighted or 1) then return true end
			return false
		else
			return true
		end
	end
	return true -- hopefully no mod compat doesn't kill a run (it will)
end

local can_skip_ref = G.FUNCS.can_skip_booster
G.FUNCS.can_skip_booster = function(e)
	if G.GAME.modifiers.mp_indigo then
		local softlock = true
		for i, v in ipairs(G.pack_cards.cards) do
			if is_usable(v) then
				softlock = false
				break
			end
		end
		if not softlock then
			e.config.colour = G.C.UI.BACKGROUND_INACTIVE
			e.config.button = nil
			return
		end
	end
	return can_skip_ref(e)
end
