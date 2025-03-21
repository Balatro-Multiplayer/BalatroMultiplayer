local key_hold_update_ref = Controller.key_hold_update
function Controller:key_hold_update(key, dt)
	if not MP.LOBBY.code then
		key_hold_update_ref(self, key, dt)
	end
end
