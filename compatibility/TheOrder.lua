-- Credit to @MathIsFun_ for creating TheOrder, which this integration is a copy of
-- Patches card creation to not be ante-based and use a single pool for every type/rarity
local cc = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if MP.INTEGRATIONS.TheOrder then
        local a = G.GAME.round_resets.ante
        G.GAME.round_resets.ante = 0
        local c = cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
        G.GAME.round_resets.ante = a
        return c
    end
    return cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
end

-- Patch Idol, Rebate, Ancient and Castle queues
-- There's surely a better way to do this
local idol = reset_idol_card
function reset_idol_card()
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = idol()
		G.GAME.round_resets.ante = a
		return ret
	end
	return idol()
end
local mail = reset_mail_card
function reset_mail_card()
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = mail()
		G.GAME.round_resets.ante = a
		return ret
	end
	return mail()
end
local ancient = reset_ancient_card
function reset_ancient_card()
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = ancient()
		G.GAME.round_resets.ante = a
		return ret
	end
	return ancient()
end
local castle = reset_castle_card
function reset_castle_card()
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = castle()
		G.GAME.round_resets.ante = a
		return ret
	end
	return castle()
end



-- Take ownership of standard pack card creation
-- This is irritating
SMODS.Booster:take_ownership_by_kind('Standard', {
	create_card = function(self, card, i)
		local b_append = MP.ante_based()..MP.get_booster_append(card)
		
		local _edition = poll_edition('standard_edition'..b_append, 2, true)
		local _seal = SMODS.poll_seal({mod = 10, key = 'stdseal'..b_append})
		
		return {set = (pseudorandom(pseudoseed('stdset'..b_append)) > 0.6) and "Enhanced" or "Base", edition = _edition, seal = _seal, area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "sta"..b_append}
	end,
})

-- Rest of the packs since we're dealing with pack queues now
SMODS.Booster:take_ownership_by_kind('Arcana', {
	create_card = function(self, card, i)
		local s_append = MP.get_booster_append(card)
		
		local _card
		if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 then
			_card = {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar2"..s_append}
		else
			_card = {set = "Tarot", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar1"..s_append}
		end
		return _card
	end,
})
SMODS.Booster:take_ownership_by_kind('Celestial', {
	create_card = function(self, card, i)
		local s_append = MP.get_booster_append(card)
		
		local _card
		if G.GAME.used_vouchers.v_telescope and i == 1 then
			local _planet, _hand, _tally = nil, nil, 0
			for k, v in ipairs(G.handlist) do
				if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
					_hand = v
					_tally = G.GAME.hands[v].played
				end
			end
			if _hand then
				for k, v in pairs(G.P_CENTER_POOLS.Planet) do
					if v.config.hand_type == _hand then
						_planet = v.key
					end
				end
			end
			_card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key = _planet, key_append = "pl1"..s_append}
		else
			_card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "pl1"..s_append}
		end
		return _card
	end,
})
SMODS.Booster:take_ownership_by_kind('Spectral', {
	create_card = function(self, card, i)
		local s_append = MP.get_booster_append(card)
		return {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "spe"..s_append}
	end,
})
SMODS.Booster:take_ownership_by_kind('Buffoon', {
	create_card = function(self, card, i)
		local s_append = MP.get_booster_append(card)
		return {set = "Joker", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "buf"..s_append}
	end,
})

-- Patch seal queues
local pollseal = SMODS.poll_seal
function SMODS.poll_seal(args)
	if MP.INTEGRATIONS.TheOrder then
		local a = G.GAME.round_resets.ante
		G.GAME.round_resets.ante = 0
		local ret = pollseal(args)
		G.GAME.round_resets.ante = a
		return ret
	end
	return pollseal(args)
end

-- Helper function to make code more readable - deal with ante
function MP.ante_based()
	if MP.INTEGRATIONS.TheOrder then
		return 0
	end
	return G.GAME.round_resets.ante
end

-- Helper function to make code more readable - deal with packs
-- Note that soul queue is based on type and not packs, so you probably won't miss out on soul if you avoid early mega arcanas or something
function MP.get_booster_append(booster)
	if MP.INTEGRATIONS.TheOrder then
		if booster.ability.extra > 3.5 then	-- midpoint, i don't feel like string matching
			if (booster.config.center.config.choose or 1) > 1.5 then
				return 'mega'	-- if we want jumbos to have same queue as megas, change this or 'jumb' to be the same
			else
				return 'jumb'
			end
		end
		return 'norm'
	end
	return ''
end