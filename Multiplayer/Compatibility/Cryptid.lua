if SMODS.Mods["Cryptid"] and SMODS.Mods["Cryptid"].can_load then
	sendDebugMessage("Cryptid compatibility detected", "MULTIPLAYER")
	G.MULTIPLAYER.DECK.ban_card("j_cry_fleshpanopticon")
	G.MULTIPLAYER.DECK.ban_card("j_cry_candy_sticks")
	G.MULTIPLAYER.DECK.ban_card("j_cry_redeo")
	G.MULTIPLAYER.DECK.ban_card("v_cry_asteroglyph")
	G.MULTIPLAYER.DECK.ban_card("c_cry_semicolon")
	G.MULTIPLAYER.DECK.ban_card("c_cry_crash")
	G.MULTIPLAYER.DECK.ban_card("c_cry_revert")
end

local defeat_ref = Blind.defeat
function Blind:defeat(silent)
	if self.config.blind.key == nil then
		self.config.blind.key = "bl_nil"
	end
	defeat_ref(self, silent)
end

function save_run()
	if G.F_NO_SAVING == true then
		-- Fake culled_table for Cryptid
		G.culled_table = recursive_table_cull({
			cardAreas = cardAreas,
			tags = tags,
			GAME = G.GAME,
			STATE = G.STATE,
			ACTION = G.action or nil,
			BLIND = G.GAME.blind:save(),
			BACK = G.GAME.selected_back:save(),
			VERSION = G.VERSION,
		})
		return
	end

	local cardAreas = {}
	for k, v in pairs(G) do
		if (type(v) == "table") and v.is and v:is(CardArea) then
			local cardAreaSer = v:save()
			if cardAreaSer then
				cardAreas[k] = cardAreaSer
			end
		end
	end

	local tags = {}
	for k, v in ipairs(G.GAME.tags) do
		if (type(v) == "table") and v.is and v:is(Tag) then
			local tagSer = v:save()
			if tagSer then
				tags[k] = tagSer
			end
		end
	end

	G.culled_table = recursive_table_cull({
		cardAreas = cardAreas,
		tags = tags,
		GAME = G.GAME,
		STATE = G.STATE,
		ACTION = G.action or nil,
		BLIND = G.GAME.blind:save(),
		BACK = G.GAME.selected_back:save(),
		VERSION = G.VERSION,
	})
	G.ARGS.save_run = G.culled_table

	G.FILE_HANDLER = G.FILE_HANDLER or {}
	G.FILE_HANDLER.run = true
	G.FILE_HANDLER.update_queued = true
end
