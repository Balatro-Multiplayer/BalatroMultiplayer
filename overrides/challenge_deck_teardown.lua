-- Back:generate_UI — challenge-deck menu teardown crash workaround.
local back_generate_ui_ref = Back.generate_UI
function Back:generate_UI(other, ui_scale, min_dims, challenge)
	local name = other and other.name or self.name
	if not challenge and name == "Challenge Deck" and MP.LOBBY.code then
		challenge = MP.LOBBY.deck.challenge -- very generous assumption
		local ret = back_generate_ui_ref(self, other, ui_scale, min_dims, challenge)
		-- Exiting the opened challenge menu otherwise crashes on ui teardown; hacky fallback.
		ret.nodes[1].nodes[1].config.button = "exit_overlay_menu"
		return ret
	end
	return back_generate_ui_ref(self, other, ui_scale, min_dims, challenge)
end
