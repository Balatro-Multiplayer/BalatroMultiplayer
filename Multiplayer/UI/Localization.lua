set_language_ref = G.set_language
function G.set_language(self)
	set_language_ref(self)
	if G.localization.mods == nil or G.localization.mods.mp == nil then
		local localization = require("localization." .. G.SETTINGS.language)
		if localization["singleplayer"] == nil then
			localization = require("localization.en-us")
		end
		G.localization.mods = { mp = localization }
	end
end

function mp_localize(args, fallback)
	if fallback == nil then
		fallback = args
	end
	return G.localization.mods.mp[args] or fallback
end
G:set_language()
