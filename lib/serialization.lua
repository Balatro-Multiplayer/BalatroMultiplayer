-- From https://github.com/lunarmodules/Penlight (MIT license)
local function save_global_env()
	local env = {}
	env.hook, env.mask, env.count = debug.gethook()

	-- env.hook is "external hook" if is a C hook function
	if env.hook ~= "external hook" then debug.sethook() end

	env.string_mt = getmetatable("")
	debug.setmetatable("", nil)
	return env
end

-- From https://github.com/lunarmodules/Penlight (MIT license)
local function restore_global_env(env)
	if env then
		debug.setmetatable("", env.string_mt)
		if env.hook ~= "external hook" then debug.sethook(env.hook, env.mask, env.count) end
	end
end

local function STR_UNPACK_CHECKED(str)
	-- Code generated from STR_PACK should only return a table and nothing else
	if str:sub(1, 8) ~= "return {" then error('Invalid string header, expected "return {..."') end

	-- Protect against code injection by disallowing function definitions
	-- This is a very naive check, but hopefully won't trigger false positives
	if str:find("[^\"'%w_]function[^\"'%w_]") then error("Function keyword detected") end

	-- Load with an empty environment, no functions or globals should be available
	local chunk = assert(load(str, nil, "t", {}))
	local global_env = save_global_env()
	local success, str_unpacked = pcall(chunk)
	restore_global_env(global_env)
	if not success then error(str_unpacked) end

	return str_unpacked
end

function MP.UTILS.str_pack_and_encode(data)
	local str = STR_PACK(data)
	local str_compressed = love.data.compress("string", "gzip", str)
	local str_encoded = love.data.encode("string", "base64", str_compressed)
	return str_encoded
end

-- A legitimately serialized object (a saved joker, a nemesis deck) is at most a
-- few KB once gzipped and base64-encoded. Reject anything far larger BEFORE we
-- spend CPU decoding/decompressing it: this is the client-side defense against
-- zip-bomb payloads relayed through actions like magnetResponse /
-- receiveEndGameJokers / receiveNemesisDeck. The relay also caps message size,
-- so this is defense-in-depth.
MP.UTILS.MAX_ENCODED_BYTES = 32 * 1024

function MP.UTILS.str_decode_and_unpack(str)
	local success, str_decoded, str_decompressed, str_unpacked
	if type(str) ~= "string" then return nil, "expected string payload" end
	if #str > MP.UTILS.MAX_ENCODED_BYTES then
		return nil, string.format("payload too large (%d > %d bytes)", #str, MP.UTILS.MAX_ENCODED_BYTES)
	end
	success, str_decoded = pcall(love.data.decode, "string", "base64", str)
	if not success then return nil, str_decoded end
	success, str_decompressed = pcall(love.data.decompress, "string", "gzip", str_decoded)
	if not success then return nil, str_decompressed end
	success, str_unpacked = pcall(STR_UNPACK_CHECKED, str_decompressed)
	if not success then return nil, str_unpacked end
	return str_unpacked
end
