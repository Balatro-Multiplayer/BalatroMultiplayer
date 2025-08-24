MP.SANDBOX = {}

MP.Ruleset({
	key = "sandbox",
	standard = true,
	multiplayer_content = true,
	banned_jokers = {
		"j_cloud_9",
		"j_bloodstone",
		"j_lucky_cat",
		"j_stencil",
		"j_constellation",
		"j_chaos",
		"j_mail",
		"j_misprint",
		"j_castle",
		"j_runner",
		"j_loyalty_card",
		"j_faceless",
		"j_photograph",
		"j_cloud_9",
		"j_square",
	},
	banned_consumables = {
		"c_justice",
	},
	banned_vouchers = {},
	banned_enhancements = {},
	banned_tags = { "tag_rare" },
	banned_blinds = {},

	reworked_jokers = {
		"j_mp_hanging_chad",
		"j_mp_lucky_cat_sandbox",
		"j_mp_stencil_sandbox",
		"j_mp_constellation_sandbox",
		"j_mp_chaos_sandbox",
		"j_mp_mail_sandbox",
		"j_mp_misprint_sandbox",
		"j_mp_castle_sandbox",
		"j_mp_runner_sandbox",
		"j_mp_loyalty_card_sandbox",
		"j_mp_faceless_sandbox",
		"j_mp_photograph_sandbox",
		"j_mp_cloud_9_sandbox",
		"j_mp_square_sandbox",
	},
	reworked_consumables = {},
	reworked_vouchers = {},
	reworked_enhancements = {
		-- "m_glass",
	},
	reworked_blinds = {},
	reworked_tags = { "tag_mp_sandbox_rare" },

	create_info_menu = function()
		return {
			{
				n = G.UIT.R,
				config = {
					align = "tm",
				},
				nodes = {
					MP.UI.BackgroundGrouping(localize("k_has_multiplayer_content"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_yes"),
								scale = 0.8,
								colour = G.C.GREEN,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_lobby_options"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
					{
						n = G.UIT.C,
						config = {
							minw = 0.1,
							minh = 0.1,
						},
					},
					MP.UI.BackgroundGrouping(localize("k_forces_gamemode"), {
						{
							n = G.UIT.T,
							config = {
								text = localize("k_no"),
								scale = 0.8,
								colour = G.C.RED,
							},
						},
					}, { col = true, text_scale = 0.6 }),
				},
			},
			{
				n = G.UIT.R,
				config = {
					minw = 0.05,
					minh = 0.05,
				},
			},
			{
				n = G.UIT.R,
				config = {
					align = "cl",
					padding = 0.1,
				},
				nodes = {
					{
						n = G.UIT.T,
						config = {
							text = localize("k_sandbox_description"),
							scale = 0.6,
							colour = G.C.UI.TEXT_LIGHT,
						},
					},
				},
			},
		}
	end,

	forced_lobby_options = true,

	force_lobby_options = function(self)
		MP.LOBBY.config.preview_disabled = true
		MP.LOBBY.config.different_seeds = false
		return true
	end,
}):inject()

-- MP.ReworkCenter({
-- 	key = "j_bloodstone",
-- 	ruleset = "sandbox",
-- 	config = { extra = {} },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_reserved_parking",
-- 	ruleset = "sandbox",
-- 	config = { extra = {} },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_egg",
-- 	ruleset = "sandbox",
-- 	config = { extra = {} },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_turtle_bean",
-- 	ruleset = "sandbox",
-- 	config = { extra = { rounds = 5 } },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.rounds } }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_juggler",
-- 	ruleset = "sandbox",
-- 	config = { extra = {} },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_hit_the_road",
-- 	ruleset = "sandbox",
-- 	config = { extra = { xmult_gain = 0.5, xmult = 1 } },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.xmult_gain, card.ability.extra.xmult } }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_red_card",
-- 	ruleset = "sandbox",
-- 	config = { extra = 5 },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })
-- )

-- MP.ReworkCenter({
-- 	key = "j_business",
-- 	ruleset = "sandbox",
-- 	config = { extra = 4 },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- 	-- TODO add con!!
-- })

-- MP.ReworkCenter({
-- 	key = "j_ride_the_bus",
-- 	ruleset = "sandbox",
-- 	config = { extra = 5 },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_golden",
-- 	ruleset = "sandbox",
-- 	config = { extra = 15 },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_scary_face",
-- 	ruleset = "sandbox",
-- 	config = { extra = 100 },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- 	-- TODO calc could prob do only what it normally does before / after...?
-- })

-- MP.ReworkCenter({
-- 	key = "j_throwback",
-- 	ruleset = "sandbox",
-- 	config = { extra = { xmult = 0.75 } },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

-- MP.ReworkCenter({
-- 	key = "j_gros_michel",
-- 	ruleset = "sandbox",
-- 	config = { extra = {} },
-- 	loc_vars = function(self, info_queue, card)
-- 		return { key = self.key .. "_mp_sandbox", vars = {} }
-- 	end,
-- })

SMODS.Atlas({
	key = "sandbox_rare",
	path = "tag_rare.png",
	px = 32,
	py = 32,
})

-- Tag: 1 in 2 chance to generate a rare joker in shop
SMODS.Tag({
	key = "sandbox_rare",
	atlas = "sandbox_rare",
	object_type = "Tag",
	dependencies = {
		items = {},
	},
	in_pool = function(self)
		return MP.LOBBY.config.ruleset == "ruleset_mp_sandbox" and MP.LOBBY.code
	end,
	name = "Rare Tag",
	discovered = true,
	order = 2,
	min_ante = 2, -- less degeneracy
	no_collection = true,
	config = {
		type = "store_joker_create",
		odds = 2,
	},
	requires = "j_blueprint",
	loc_vars = function(self)
		return { vars = { G.GAME.probabilities.normal or 1, self.config.odds } }
	end,
	apply = function(self, tag, context)
		if context.type == "store_joker_create" then
			local card = nil
			-- 1 in 2 chance to proc
			if pseudorandom("tagroll") < G.GAME.probabilities.normal / tag.config.odds then
				-- count owned rare jokers to prevent duplicates
				local rares_owned = { 0 }
				for k, v in ipairs(G.jokers.cards) do
					if v.config.center.rarity == 3 and not rares_owned[v.config.center.key] then
						rares_owned[1] = rares_owned[1] + 1
						rares_owned[v.config.center.key] = true
					end
				end

				-- only proc if unowned rares exist
				-- funny edge case that i've never seen happen, but if localthunk saw it i will obey
				if #G.P_JOKER_RARITY_POOLS[3] > rares_owned[1] then
					card = create_card("Joker", context.area, nil, 1, nil, nil, nil, "rta")
					create_shop_card_ui(card, "Joker", context.area)
					card.states.visible = false
					tag:yep("+", G.C.RED, function()
						card:start_materialize()
						card.ability.couponed = true -- free card
						card:set_cost()
						return true
					end)
				else
					tag:nope() -- all rares owned
				end
			else
				tag:nope() -- failed roll
			end
			tag.triggered = true
			return card
		end
	end,
})

-- Standard pack card creation for sandbox ruleset
-- Skips glass enhancement (excluded from enhancement pool)
-- 40% chance (0.6 threshold) for any enhancement to be applied (like vanilla)
-- function sandbox_create_card(self, card, i)
-- 	local enhancement_pool = {}

-- 	-- Skip glass
-- 	for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
-- 		if v.key ~= "m_glass" then
-- 			enhancement_pool[#enhancement_pool + 1] = v.key
-- 		end
-- 	end

-- 	local ante_rng = MP.ante_based()
-- 	local roll = pseudorandom(pseudoseed("stdc1" .. ante_rng))
-- 	local enhancement = roll > 0.6 and pseudorandom_element(enhancement_pool, pseudoseed("stdc2" .. ante_rng)) or nil

-- 	local s_append = ""
-- 	local b_append = ante_rng .. s_append

-- 	local _edition = poll_edition("standard_edition" .. b_append, 2, true)
-- 	local _seal = SMODS.poll_seal({ mod = 10, key = "stdseal" .. ante_rng })

-- 	return {
-- 		set = "Base",
-- 		edition = _edition,
-- 		seal = _seal,
-- 		enhancement = enhancement,
-- 		area = G.pack_cards,
-- 		skip_materialize = true,
-- 		soulable = true,
-- 		key_append = "sta" .. s_append,
-- 	}
-- end

-- for k, v in ipairs(G.P_CENTER_POOLS.Booster) do
-- 	if v.kind and v.kind == "Standard" then
-- 		MP.ReworkCenter({
-- 			key = v.key,
-- 			ruleset = "sandbox",
-- 			silent = true,
-- 			create_card = sandbox_create_card,
-- 		})
-- 	end
-- end
