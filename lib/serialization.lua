-- Plain-string gzip+base64, for payloads that are ALREADY strings (e.g. the
-- RLOG carbon block -- lib/replay_log.lua) rather than Lua tables. Table
-- serialization (STR_PACK + the anti-code-injection sandboxed unpack) lives in
-- MPAPI.encode/MPAPI.decode (BalatroMultiplayerAPI/api/synced/serialize.lua) --
-- this mod's own former copy of that sandbox was deleted in favor of the single
-- shared implementation there; only this plain-string codec, which MPAPI has no
-- equivalent of, stays PvP-local.
--
-- Applied once, to the whole finalized block, not per-event: per-event gzip
-- overhead (~20-byte header/footer) would dominate a 10-30 byte event and
-- defeat the point -- live-streamed individual events stay uncompressed, only
-- the at-rest/download artifact goes through this.
function MP.UTILS.compress_str(str)
	local compressed = love.data.compress("string", "gzip", str)
	return love.data.encode("string", "base64", compressed)
end

-- Inverse of compress_str. No STR_UNPACK_CHECKED step (there's no Lua table to
-- reconstruct) -- the caller gets the original plain string back.
function MP.UTILS.decompress_str(str)
	if type(str) ~= "string" then return nil, "expected string payload" end
	local success, decoded = pcall(love.data.decode, "string", "base64", str)
	if not success then return nil, decoded end
	local success2, decompressed = pcall(love.data.decompress, "string", "gzip", decoded)
	if not success2 then return nil, decompressed end
	return decompressed
end
