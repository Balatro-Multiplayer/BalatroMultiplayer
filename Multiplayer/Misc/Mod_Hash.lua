G.MULTIPLAYER.MOD_HASH = "0000"
G.MULTIPLAYER.MOD_STRING = ""

function hash(str)
	if not str then
		return "0000"
	end

	local bit = require("bit")
	h = 5381

	for c in str:gmatch(".") do
		h = (bit.lshift(h, 5) + h) + string.byte(c)
	end
	return string.sub(tostring(h), -4)
end

function G.MULTIPLAYER:generate_hash()
	local mod_str = ""
	for key, mod in pairs(SMODS.Mods) do
		if not mod.disabled and key ~= "Lovely" and key ~= "Balatro" and key ~= "Steamodded" then
			mod_str = mod_str .. mod.id .. "-" .. mod.version .. ";"
		end
	end
	self.MOD_STRING = mod_str
	self.MOD_HASH = hash(mod_str)
	sendInfoMessage("Generated Mod Hash: " .. self.MOD_HASH, "MULTIPLAYER")
	self.set_username(G.LOBBY.username)
end

local hash_generated = false

local game_update_ref = Game.update
---@diagnostic disable-next-line: duplicate-set-field
function Game:update(dt)
	game_update_ref(self, dt)

	if not hash_generated and SMODS.booted then
		G.MULTIPLAYER:generate_hash()
		hash_generated = true
	end
end
