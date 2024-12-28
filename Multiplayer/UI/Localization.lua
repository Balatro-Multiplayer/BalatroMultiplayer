set_language_ref = G.set_language
function G.set_language(self)
	set_language_ref(self)
	if G.localization == nil then
		G.localization = {}
	end
	if G.localization.mods == nil or G.localization.mods.mp == nil then
		local localization = G.MULTIPLAYER.load_mp_file("localization/" .. G.SETTINGS.language .. ".lua")
		if localization == nil or localization["misc"] == nil then
			sendWarnMessage(
				"Failed to load multiplayer localization file for language: '" .. G.SETTINGS.language .. "'",
				"MULTIPLAYER"
			)
			localization = G.MULTIPLAYER.load_mp_file("localization/en-us.lua")
		end
		if localization ~= nil then
			G.localization.mods = { mp = localization.misc.mp }
		end
	end
end

function mp_localize(key, fallback)
	if fallback == nil then
		fallback = args
	end
	if G.localization.mods ~= nil and G.localization.mods.mp ~= nil then
		return G.localization.mods.mp[key] or fallback
	end
	return fallback
end
G:set_language()
