MP.MOD_HASH = "0000"
MP.MOD_STRING = ""

function hash(str)
	local str_to_hash = str or "0000"
	local hash = 0
	for i = 1, #str_to_hash do
		local char = string.byte(str_to_hash, i)
		hash = (hash * 31 + char) % 10000
	end
	return string.format("%04d", hash)
end

local function get_mod_data()
	local mod_table = {}
	for key, mod in pairs(SMODS.Mods) do
		if not mod.disabled and key ~= "Lovely" and key ~= "Balatro" and key ~= "Steamodded" then
			table.insert(mod_table, key .. "-" .. mod.version)
		end
	end
	for key, mod in pairs(MP.INTEGRATIONS) do
		if mod then
			table.insert(mod_table, key .. "-MultiplayerIntegration")
		end
	end
	return mod_table
end

function MP:generate_hash()
	local mod_data = get_mod_data()
	table.sort(mod_data)
	local mod_string = table.concat(mod_data, ";")
	MP.MOD_STRING = mod_string
	MP.MOD_HASH = hash(mod_string) or "0000"
	sendInfoMessage("Generated Mod Hash: " .. MP.MOD_HASH, "MULTIPLAYER")
	MP.ACTIONS.set_username(MP.LOBBY.username)
end

local hash_generated = false

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	if not hash_generated and SMODS.booted then
		MP:generate_hash()
		hash_generated = true
	end
end
