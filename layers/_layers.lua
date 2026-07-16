-- Credit to @MathIsFun_ and the Balatro Multiplayer project for the layer system this is based on.
-- Thin delegating wrapper around MPAPI.Layer: registers PvP layers into the shared
-- MPAPI.Layers registry and its reworked_* reverse-index tables (MPAPI._JOKER_LAYERS
-- etc.), so MPAPI's own pool-gating register hook (api/layers/pool_gating.lua) auto-
-- gates PvP content the same way it already does for MPAPI/Speed content -- PvP's
-- own duplicate SMODS.Joker/Consumable/Tag.register monkeypatch is retired.
--
-- MP.should_exclude_from_pool stays: it's directly wired into lovely/misc.toml's
-- pool-filtering patch (not just the register-time auto-gate), and only reads
-- whatever `mp_include` ended up on the object -- unaffected by who set it.

function MP.Layer(name, definition)
	MPAPI.Layer(name, definition)
end

function MP.should_exclude_from_pool(v)
	if v.mp_include and type(v.mp_include) == "function" then return not v:mp_include() end
	if v.key and v.key:match("^%a+_mp_") then return true end
	return false
end

-- ----------------------------------------------------------------------------
-- Modifier layers
-- ----------------------------------------------------------------------------
-- MPAPI.MODIFIERS/add_modifier/etc. already exist (identical shape, same "not
-- materialized onto the ruleset" design) -- delegate rather than keep a second
-- copy. modifiers_parse is the only externally-called one (networking/
-- action_handlers.lua); the rest (add/remove/apply_default_modifiers) had zero
-- callers anywhere in this codebase.
MP.modifiers_parse = MPAPI.modifiers_parse

-- MP.active_layer_chain()/get_active_ruleset() (rulesets/_rulesets.lua) resolve the
-- same lobby metadata MPAPI's own equivalents do, but additionally know about PvP's
-- practice-mode/ghost-replay cases that MPAPI doesn't -- kept as the PvP-owned
-- resolution layer for that reason, even though the two agree for any live lobby.
function MP.is_layer_active(layer_name)
	if not layer_name then return false end
	for _, name in ipairs(MP.active_layer_chain()) do
		if name == layer_name then return true end
	end
	return false
end

function MP.is_any_layer_active(layers)
	for _, layer_name in pairs(layers) do
		if MP.is_layer_active(layer_name) then return true end
	end
	return false
end
