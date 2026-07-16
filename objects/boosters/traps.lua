-- Trap booster packs: the ONLY source of Trap consumables (see objects/consumables/traps.lua
-- and layers/traps.lua's ban-source, which hides these two packs entirely unless the "traps"
-- layer is active). Art is the vanilla Spectral pack wrapper recoloured to the enforced Trap
-- palette (lib/colours.lua) via scripts/recolour -- temp art, not commissioned.
SMODS.Atlas({
	key = "trap_pack",
	path = "trap_pack.png",
	px = 71,
	py = 95,
})

-- Normal: 1 choose from 3 (matches vanilla Arcana/Celestial normal sizing).
SMODS.Booster({
	key = "trap_normal",
	kind = "Trap",
	group_key = "k_trap_pack",
	atlas = "trap_pack",
	pos = { x = 0, y = 0 },
	config = { extra = 3, choose = 1 },
	cost = 4,
	mp_include = function(self)
		return MP.is_layer_active("traps")
	end,
	create_card = function(self, card, i)
		return {
			set = "Trap",
			area = G.pack_cards,
			skip_materialize = true,
			soulable = true,
			key_append = "trp",
		}
	end,
})

-- Jumbo: 1 choose from 5 (matches vanilla Arcana/Celestial jumbo sizing). No mega variant.
SMODS.Booster({
	key = "trap_jumbo",
	kind = "Trap",
	group_key = "k_trap_pack",
	atlas = "trap_pack",
	pos = { x = 1, y = 0 },
	config = { extra = 5, choose = 1 },
	cost = 6,
	mp_include = function(self)
		return MP.is_layer_active("traps")
	end,
	create_card = function(self, card, i)
		return {
			set = "Trap",
			area = G.pack_cards,
			skip_materialize = true,
			soulable = true,
			key_append = "trp",
		}
	end,
})
