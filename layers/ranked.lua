MP.Layer("ranked", {
	forced_lobby_options = true,
	is_disabled = function(self)
		return MP.UTILS.check_smods_version() or MP.UTILS.check_lovely_version()
	end,
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return true
	end,
})
