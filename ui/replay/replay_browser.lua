-- §22.2: "My Replays" browser -- lists MPAPI.replay.list_mine, launches a
-- full, uninteractable card-level replay of the picked run via
-- PVP._start_playback (lib/playback_launch.lua) + MPAPI.playback (the same
-- engine lib/playback_handlers.lua's opcode handlers drive).
--
-- v1 scope: no pagination (the plan's own scope decision -- see
-- AUTONOMOUS_DECISIONS.md), most-recent-first, capped to the first page
-- MPAPI.replay.list_mine returns.

local function format_run_label(run)
	local date = tostring(run.startedAt or ''):match('^(%d%d%d%d%-%d%d%-%d%d)') or '?'
	return date .. '  ' .. tostring(run.lobbyCode or '??????') .. '  [' .. tostring(run.status or '?') .. ']'
end

-- Finds the manifest event for `player_id` in an already-built timeline
-- (MPAPI.playback.build_timeline) -- the manifest event's own args ARE the
-- full {seed, deck, sleeve, challenge, stake, ruleset, gamemode, ...} table
-- PVP.RLOG.begin_run recorded, exactly what PVP._start_playback needs.
local function find_manifest(timeline, player_id)
	for _, entry in ipairs(timeline) do
		if entry.player_id == player_id and entry.opcode == 'manifest' then
			return entry.args
		end
	end
	return nil
end

function PVP._launch_replay(run_id)
	MPAPI.replay.get(run_id, function(err, data)
		if err or not data or not data.logs then
			MPAPI.sendWarnMessage('[replay] failed to load run ' .. tostring(run_id) .. ': ' .. tostring(err and err.message))
			return
		end

		local timeline = MPAPI.playback.build_timeline(data.logs)
		local conn = MPAPI.get_connection()
		local my_id = conn and conn.player_id
		local manifest = find_manifest(timeline, my_id)
		if not manifest then
			MPAPI.sendWarnMessage('[replay] no manifest found for our own player in run ' .. tostring(run_id))
			return
		end

		PVP._start_playback(manifest, function()
			local driver = MPAPI.playback.new_driver(timeline, {
				mod_id = 'pvp',
				pov_player_id = my_id,
				on_complete = function()
					attention_text({
						text = 'Replay finished',
						scale = 1,
						hold = 3,
						cover = { align = 'cm' },
					})
				end,
			})
			driver:finish()
			driver:play()
		end)
	end)
end

-- MPAPI account overlay's Match History tab dispatches here via
-- MPAPI.playback.launch(run.modId, run.id) (api/playback/registry.lua) --
-- registered under PVP.id (the SMODS mod id, what run.modId actually is,
-- since MPAPI.create_lobby/create_local_lobby are always called with PVP.id
-- as their own mod_id argument), NOT the literal 'pvp' string used above for
-- mod_id = 'pvp' / register_handler('pvp', ...) -- that's a separate,
-- unrelated opcode-dispatch namespace this PvP mod happens to also use.
MPAPI.playback.register_launcher(PVP.id, PVP._launch_replay)

G.FUNCS.mp_pvp_open_replay_browser = function()
	MPAPI.replay.list_mine(nil, function(err, data)
		if err then
			MPAPI.sendWarnMessage('[replay] list_mine failed: ' .. tostring(err.message))
			return
		end

		local runs = (data and data.runs) or {}
		local rows = {
			{ n = G.UIT.R, config = { align = 'cm', padding = 0.1 }, nodes = {
				{ n = G.UIT.T, config = { text = 'My Replays', scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
			} },
		}

		if #runs == 0 then
			rows[#rows + 1] = { n = G.UIT.R, config = { align = 'cm', minh = 2 }, nodes = {
				{ n = G.UIT.T, config = { text = 'No replays yet.', scale = 0.4, colour = G.C.UI.TEXT_LIGHT } },
			} }
		else
			for _, run in ipairs(runs) do
				rows[#rows + 1] = { n = G.UIT.R, config = { align = 'cm', padding = 0.05 }, nodes = {
					UIBox_button({
						button = 'mp_pvp_replay_pick_' .. run.id,
						label = { format_run_label(run) },
						colour = G.C.BLUE,
						minw = 5,
						minh = 0.6,
						scale = 0.35,
					}),
				} }
				G.FUNCS['mp_pvp_replay_pick_' .. run.id] = function()
					G.FUNCS.exit_overlay_menu()
					PVP._launch_replay(run.id)
				end
			end
		end

		G.FUNCS.overlay_menu({ definition = create_UIBox_generic_options({ contents = rows }) })
	end)
end
