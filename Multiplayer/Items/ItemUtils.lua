function add_nemesis_info(info_queue)
	if G.LOBBY.code then
		info_queue[#info_queue + 1] = {
			set = "Other",
			key = "current_nemesis",
			vars = { G.LOBBY.is_host and G.LOBBY.guest.username or G.LOBBY.host.username },
		}
	end
end
