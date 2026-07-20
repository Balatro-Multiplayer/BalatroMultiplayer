-- Keep saving disabled while in a lobby (does NOT force go_to_menu on lobby-code change;
-- the API drives menu/lobby transitions now).
local in_lobby = false
local gameUpdateRef = Game.update
function Game:update(dt)
	if (MP.LOBBY.code and not in_lobby) or (not MP.LOBBY.code and in_lobby) then
		in_lobby = not in_lobby
		G.F_NO_SAVING = in_lobby
	end
	gameUpdateRef(self, dt)
end
