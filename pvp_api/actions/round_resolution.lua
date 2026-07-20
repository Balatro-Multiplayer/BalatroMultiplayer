local A = MP._pvp_action_helpers.A

-- Round / match resolution (host-authoritative inputs).
A("pvp_fail_round", function(_at, from, _params)
	MP.referee_on_fail_round(from)
end)

A("pvp_fail_timer", function(_at, from, _params)
	MP.referee_on_fail_timer(from)
end)

A("pvp_fail_pvp_timer", function(_at, from, _params)
	MP.referee_on_fail_pvp_timer(from)
end)
