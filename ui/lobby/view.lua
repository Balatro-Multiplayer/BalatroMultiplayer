MP.build_in_lobby_ui = function()
	local L = MP.lobby
	local lobby = MPAPI.get_current_lobby()

	if lobby and not L.ui_ref then
		L.ref = lobby
		L.ui_ref = MPAPI.create_lobby_ui(lobby)
	end
	if not L.ui_ref then
		return MP.build_pre_lobby_ui()
	end

	L.create_buttons()
	MPAPI.set_logo_offset(-10, true)

	return {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.C,
				config = { align = "cm" },
				nodes = {
					{ n = G.UIT.R, config = { align = "cm", padding = 0.1, mid = true }, nodes = { L.ui_ref.node } },
					{ n = G.UIT.R, config = { minh = 0.2 } },
					{ n = G.UIT.R, config = { align = "cm" }, nodes = { L.build_controls() } },
				},
			},
		},
	}
end
