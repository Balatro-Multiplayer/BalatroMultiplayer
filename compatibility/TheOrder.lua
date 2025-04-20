-- Credit to @MathIsFun_ for creating TheOrder, which this integration is a copy of
-- Patches card creation to not be ante-based and use a single pool for every type/rarity
local cc = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    if MP.INTEGRATIONS.TheOrder then
        local a = G.GAME.round_resets.ante
        G.GAME.round_resets.ante = 0
        local c = cc(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, _rarity)
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
end



-- Take ownership of standard pack card creation
-- This is irritating
SMODS.Booster:take_ownership_by_kind('Standard', {
	create_card = function(self, card, i)
		local _edition = poll_edition('standard_edition'..MP.ante_based(), 2, true)
		local _seal = SMODS.poll_seal({mod = 10})
		return {set = (pseudorandom(pseudoseed('stdset'..MP.ante_based())) > 0.6) and "Enhanced" or "Base", edition = _edition, seal = _seal, area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "sta"}
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

-- Helper function to make code more readable
function MP.ante_based()
	if MP.INTEGRATIONS.TheOrder then
		return 0
	end
	return G.GAME.round_resets.ante
end