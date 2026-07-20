local A = MP._pvp_action_helpers.A
local self_id = MP._pvp_action_helpers.self_id

A("pvp_ante_timer", function(_at, from, params)
	if from == self_id() then
		return
	end
	MP.dispatch_action("startAnteTimer", { time = params.time, isPvP = params.isPvP, fromNemesis = true })
end)

A("pvp_pause_ante_timer", function(_at, from, params)
	if from == self_id() then
		return
	end
	MP.dispatch_action("pauseAnteTimer", { time = params.time, fromNemesis = true })
end)
