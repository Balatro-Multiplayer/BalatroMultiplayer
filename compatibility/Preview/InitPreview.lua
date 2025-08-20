-- Global values that must be present for the rest of this mod to work.

if not FN then FN = {} end

FN.PRE = {
	data = {
		score = { min = 0, exact = 0, max = 0 },
		dollars = { min = 0, exact = 0, max = 0 },
	},
	text = {
		score = { l = "", r = "" },
		dollars = { top = "", bot = "" },
	},
	joker_order = {},
	hand_order = {},
	show_preview = false,
	lock_updates = false,
	on_startup = true,
	five_second_coroutine = nil,
}

function FN.PRE.start_new_coroutine()
	if FN.PRE.five_second_coroutine and coroutine.status(FN.PRE.five_second_coroutine) ~= "dead" then
		FN.PRE.five_second_coroutine = nil -- Reset the coroutine
	end

	-- Create and start a new coroutine
	FN.PRE.five_second_coroutine = coroutine.create(function()
		-- Show UI updates
		FN.PRE.lock_updates = true
		FN.PRE.show_preview = true
		FN.PRE.add_update_event("immediate") -- Force UI refresh

		local start_time = os.time()
		if not MP.is_pvp_boss() then
			while os.time() - start_time < 5 do
				FN.PRE.simulate() -- Force a simulation run
				FN.PRE.add_update_event("immediate") -- Ensure UI updates
				coroutine.yield() -- Allow game to continue running
			end
		end
		-- Delay for 5 seconds
		FN.PRE.lock_updates = false
		FN.PRE.show_preview = true
		FN.PRE.add_update_event("immediate") -- Refresh UI again
	end)

	coroutine.resume(FN.PRE.five_second_coroutine) -- Start it immediately
end

FN.PRE._start_up = Game.start_up
function Game:start_up()
	FN.PRE._start_up(self)

	if not MP.INTEGRATIONS.Preview then return end

	if not G.SETTINGS.FN then G.SETTINGS.FN = {} end
	if not G.SETTINGS.FN.PRE then
		G.SETTINGS.FN.PRE = true

		G.SETTINGS.FN.preview_score = true
		G.SETTINGS.FN.preview_dollars = true
		G.SETTINGS.FN.hide_face_down = true
		G.SETTINGS.FN.show_min_max = true
	end
end
