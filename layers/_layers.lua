-- Credit to @MathIsFun_ and the Balatro Multiplayer project for the layer system this is based on.
-- PvP layer content registers directly into MPAPI.Layer (no PvP-side wrapper --
-- MPAPI.Layer already provides the shared MPAPI.Layers registry and its
-- reworked_* reverse-index tables for free, so MPAPI's own pool-gating register
-- hook (api/layers/pool_gating.lua) auto-gates PvP content the same way it
-- already does for MPAPI/Speed content).
--
-- Pool-inclusion enforcement itself (the should_exclude_from_pool check + the
-- Lovely patch that wires it into get_current_pool) now lives entirely in MPAPI
-- (BalatroMultiplayerAPI/lovely/pool_gating.toml) so any MPAPI-consumer mod gets
-- the same isolation for free. PvP just registers how to tell whether its own
-- content should be active right now -- individual jokers/consumables no longer
-- need their own mp_include for the common case (see objects/ for the handful
-- that still define one, for logic beyond this default).
MPAPI.register_mod_isolation(PVP.id, function()
	return PVP.LOBBY.code and PVP.LOBBY.config.multiplayer_jokers
end)

-- ----------------------------------------------------------------------------
-- Modifier layers
-- ----------------------------------------------------------------------------
-- MPAPI.MODIFIERS/add_modifier/etc. already exist (identical shape, same "not
-- materialized onto the ruleset" design) -- delegate rather than keep a second
-- copy. modifiers_parse is the only externally-called one (networking/
-- action_handlers.lua); the rest (add/remove/apply_default_modifiers) had zero
-- callers anywhere in this codebase.
PVP.modifiers_parse = MPAPI.modifiers_parse

-- PVP.active_layer_chain()/get_active_ruleset() (rulesets/_rulesets.lua) resolve the
-- same lobby metadata MPAPI's own equivalents do, but additionally know about PvP's
-- practice-mode case that MPAPI doesn't -- kept as the PvP-owned resolution layer
-- for that reason, even though the two agree for any live lobby.
function PVP.is_layer_active(layer_name)
	if not layer_name then return false end
	for _, name in ipairs(PVP.active_layer_chain()) do
		if name == layer_name then return true end
	end
	return false
end

function PVP.is_any_layer_active(layers)
	for _, layer_name in pairs(layers) do
		if PVP.is_layer_active(layer_name) then return true end
	end
	return false
end
