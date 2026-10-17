-- Chaos Clock in the run: the forecast row on each blind select card, and a HUD
-- readout of the windows live right now. Data comes from MP.CHAOS_CLOCK
-- (layers/chaos_clock.lua); this file only draws it.

local TITLE = "CHAOS CLOCK"
local CLOCK_COLOUR = G.C.DARK_EDITION

local function text(str, scale, colour)
	return { n = G.UIT.T, config = { text = str, scale = scale, colour = colour, shadow = true } }
end

-- One line per drawn pick: a window's name, or a mystery effect for an instant.
local function forecast_row(entry, dim)
	local colour = dim and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT
	local nodes
	if entry.window == "instant" then
		nodes = { text("Mystery Effect", 0.32, colour) }
	else
		nodes = { text(entry.text, 0.32, colour) }
		if entry.window == "run" then nodes[2] = text("  REST OF RUN", 0.26, dim and colour or G.C.RED) end
	end
	return { n = G.UIT.R, config = { align = "cm", maxw = 2.8 }, nodes = nodes }
end

local function forecast_box(slot)
	local forecast = MP.CHAOS_CLOCK.forecast_for(slot)
	if not forecast then return nil end
	local state = G.GAME.round_resets.blind_states[slot]
	local dim = state == "Skipped" or state == "Defeated"
	local rows = {
		{
			n = G.UIT.R,
			config = { align = "cm" },
			nodes = { text(TITLE, 0.28, dim and G.C.UI.TEXT_INACTIVE or CLOCK_COLOUR) },
		},
	}
	for _, entry in ipairs(forecast) do
		rows[#rows + 1] = forecast_row(entry, dim)
	end
	if #forecast == 0 then
		rows[#rows + 1] =
			{ n = G.UIT.R, config = { align = "cm" }, nodes = { text("No effect", 0.3, G.C.UI.TEXT_INACTIVE) } }
	end
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.06, r = 0.1, colour = { 0, 0, 0, 0.12 }, minw = 2.9 },
				nodes = rows,
			},
		},
	}
end

-- Wraps both builders (vanilla's and MP's in blind_choice.lua, which loads
-- first): the forecast goes between the card and its extras (skip tag / ante
-- note). Run Info's Blinds tab uses the same builder, so it shows there too.
local create_UIBox_blind_choice_ref = create_UIBox_blind_choice
---@diagnostic disable-next-line: lowercase-global
function create_UIBox_blind_choice(type, run_info)
	local t = create_UIBox_blind_choice_ref(type, run_info)
	local box = G.GAME.mp_clock and forecast_box(type or "Small")
	if box and t and t.nodes then table.insert(t.nodes, #t.nodes, box) end
	return t
end

local function ends_text(window)
	if window == "blind" then return "Until next Blind" end
	if window == "ante" then return "Until Ante " .. (G.GAME.round_resets.ante + 1) end
	return "Rest of run"
end

-- Rebuild after a clock transition or HUD creation. Remove the old UIBox
-- first so expired effects cannot remain visible.
function MP.UI.refresh_chaos_clock_hud()
	if G.MP_CLOCK_HUD then
		G.MP_CLOCK_HUD:remove()
		G.MP_CLOCK_HUD = nil
	end
	if not (G.consumeables and not G.consumeables.REMOVED and G.GAME and G.GAME.mp_clock) then return end
	local live = MP.CHAOS_CLOCK.live()
	if #live == 0 then return end
	local rows = {
		{ n = G.UIT.R, config = { align = "cl" }, nodes = { text(TITLE, 0.28, CLOCK_COLOUR) } },
	}
	for _, entry in ipairs(live) do
		rows[#rows + 1] = {
			n = G.UIT.R,
			config = { align = "cl" },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cl", minw = 1.9 },
					nodes = { text(entry.text, 0.3, G.C.UI.TEXT_LIGHT) },
				},
				{
					n = G.UIT.C,
					config = { align = "cr" },
					nodes = { text(ends_text(entry.window), 0.26, G.C.UI.TEXT_INACTIVE) },
				},
			},
		}
	end
	G.MP_CLOCK_HUD = UIBox({
		definition = {
			n = G.UIT.ROOT,
			config = { align = "cl", padding = 0.08, r = 0.1, colour = { 0, 0, 0, 0.35 } },
			nodes = rows,
		},
		-- Under the consumable slots, right-aligned: clear of the jokers, the blind
		-- select cards and the shop panel, which ends left of that edge.
		config = { align = "bm", offset = { x = 0, y = 0.45 }, major = G.consumeables, bond = "Weak" },
	})
	G.MP_CLOCK_HUD.alignment.offset.x = (G.consumeables.T.w - G.MP_CLOCK_HUD.T.w) / 2
end

local start_run_ref = Game.start_run
function Game:start_run(args)
	local ret = start_run_ref(self, args)
	MP.UI.refresh_chaos_clock_hud()
	return ret
end

local delete_run_ref = Game.delete_run
function Game:delete_run()
	if G.MP_CLOCK_HUD then
		G.MP_CLOCK_HUD:remove()
		G.MP_CLOCK_HUD = nil
	end
	return delete_run_ref(self)
end
