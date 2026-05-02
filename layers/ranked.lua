MP.Layer("ranked", {
	forced_lobby_options = true,
	force_lobby_options = function(self)
		MP.LOBBY.config.the_order = true
		return true
	end,
})
