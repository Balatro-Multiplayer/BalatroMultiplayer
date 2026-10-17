--[[
  In-game scenario runner. Loaded by core.lua only when MP_SCENARIO is set:

    MP_SCENARIO=custom_wall MP_SCENARIO_QUIT=1 bash run_lovely_macos.sh
    (or: bash scripts/run_scenario.sh custom_wall)

  A scenario file (tests/scenarios/<name>.lua) returns a list of steps:

    return {
      { wait = 2, run = function(S) ... end },          -- seconds after the previous step
      { until_ = function() return G.hand end, timeout = 10, run = ... },
    }

  S.check(cond, msg) logs PASS/FAIL, S.shot(name) saves a PNG under
  .context/scenarios/<scenario>/, S.log(msg) logs a line. Every line is prefixed
  "MP_SCENARIO" in the Lovely log; scripts/run_scenario.sh greps for it.
]]

local name = os.getenv("MP_SCENARIO")
local S = { name = name, pass = 0, fail = 0 }
MP.SCENARIO = S

local function emit(msg)
	sendInfoMessage("MP_SCENARIO " .. msg, "MULTIPLAYER")
end

function S.log(msg)
	emit("LOG " .. tostring(msg))
end

function S.check(cond, msg)
	if cond then
		S.pass = S.pass + 1
		emit("PASS " .. msg)
	else
		S.fail = S.fail + 1
		emit("FAIL " .. msg)
	end
	return cond
end

local shot_dir = MP.path .. "/.context/scenarios/" .. tostring(name)
function S.shot(shot_name)
	NFS.createDirectory(shot_dir)
	local path = shot_dir .. "/" .. shot_name .. ".png"
	love.graphics.captureScreenshot(function(img)
		local data = img:encode("png")
		local f = io.open(path, "wb")
		if f then
			f:write(data:getString())
			f:close()
		end
	end)
	emit("SHOT " .. path)
end

-- Fake UIElement for driving G.FUNCS button handlers directly.
function S.fake_button(ref_table)
	return { config = { ref_table = ref_table }, juice_up = function() end }
end

local steps
local chunk, err = SMODS.load_file("tests/scenarios/" .. tostring(name) .. ".lua", "Multiplayer")
if chunk then
	steps = chunk()
else
	emit("FAIL could not load scenario " .. tostring(name) .. ": " .. tostring(err))
	steps = {}
end

local i, clock, started, finished = 1, 0, false, false

local function finish()
	finished = true
	emit(("DONE pass=%d fail=%d"):format(S.pass, S.fail))
	if os.getenv("MP_SCENARIO_QUIT") then
		G.E_MANAGER:add_event(Event({
			trigger = "after",
			delay = 1,
			blockable = false,
			blocking = false,
			no_delete = true,
			func = function()
				love.event.quit()
				return true
			end,
		}))
	end
end

-- Skip the splash for this boot only; G.SETTINGS is saved to disk, so restore it.
local splash_ref = Game.splash_screen
function Game:splash_screen()
	local skip = G.SETTINGS.skip_splash
	G.SETTINGS.skip_splash = "Yes"
	splash_ref(self)
	G.SETTINGS.skip_splash = skip
end

local update_ref = Game.update
function Game:update(dt)
	update_ref(self, dt)
	if finished then return end
	if not started then
		-- Start once the main menu is up.
		if G.STATE ~= G.STATES.MENU or not G.MAIN_MENU_UI then return end
		started = true
		-- DebugPlus's log previews cover the bottom of every shot. onUpdate flips
		-- the live flag without writing DebugPlus's config file.
		local dp = package.loaded["debugplus.config"]
		local def = dp and dp.configDefinition and dp.configDefinition.showNewLogs
		if def and def.onUpdate then def.onUpdate(false) end
		emit("START " .. tostring(name) .. " steps=" .. #steps)
	end
	local step = steps[i]
	if not step then return finish() end
	clock = clock + dt
	if clock < (step.wait or 0.5) then return end
	if step.until_ then
		local ok, ready = pcall(step.until_)
		if not (ok and ready) then
			if clock < (step.wait or 0.5) + (step.timeout or 10) then return end
			S.check(false, "step " .. i .. " timed out waiting")
			return finish()
		end
	end
	local ok, run_err = pcall(step.run or function() end, S)
	if not ok then
		S.check(false, "step " .. i .. " errored: " .. tostring(run_err))
		return finish()
	end
	i, clock = i + 1, 0
end
