-- The old top-right main-menu connection line (G.HUD_connection_status) was removed: the
-- API account panel already shows connection status, so the PvP HUD was a redundant
-- duplicate. This stays as a no-op that tears down any stale HUD, so its many callers
-- (lobby teardown, action handlers, etc.) remain valid without rendering anything.
function MP.UI.update_connection_status()
	if G.HUD_connection_status then
		G.HUD_connection_status:remove()
		G.HUD_connection_status = nil
	end
end
