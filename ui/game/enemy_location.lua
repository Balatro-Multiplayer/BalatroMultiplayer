function MP.UI.enemy_location_blind_render()
    local blind_key, blind_object = MP.GAME.enemy.location_blind, nil
    if blind_key then
        blind_object = G.P_BLINDS[blind_key]
    end

    local blind_object_render
    if blind_object then
        blind_object_render = SMODS.create_sprite(0, 0, 0.4, 0.4, blind_object.atlas or 'blind_chips', blind_object.pos or G.P_BLINDS.bl_small.pos)
        blind_object_render:define_draw_steps({
            {shader = 'dissolve', shadow_height = 0.05 * 0.4 * 0.75},
            {shader = 'dissolve'},
        })
    elseif blind_key and blind_key ~= "" then
        blind_object_render = DynaText({
            string = { blind_key or "Unknown" },
            colours = { G.C.WHITE },
            scale = 0.35,
            shadow = true,
        })
    else
        blind_object_render = Moveable()
    end

    return blind_object_render
end

function MP.UI.round_score_definition()
    return {
        n = G.UIT.C,
        config = { align = "cm", padding = 0.1, func = "mp_setup_hover_enemy_location_display" },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cm", minw = 1.3 },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0, maxw = 1.3 },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = G.SETTINGS.language == "vi" and localize("k_lower_score")
                                        or localize("k_round"),
                                    scale = 0.42,
                                    colour = G.C.UI.TEXT_LIGHT,
                                    shadow = true,
                                },
                            },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0, maxw = 1.3 },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = G.SETTINGS.language == "vi" and localize("k_round")
                                        or localize("k_lower_score"),
                                    scale = 0.42,
                                    colour = G.C.UI.TEXT_LIGHT,
                                    shadow = true,
                                },
                            },
                        },
                    },
                },
            },
            {
                n = G.UIT.C,
                config = { align = "cm", minw = 3.3, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK },
                nodes = {
                    {
                        n = G.UIT.O,
                        config = {
                            w = 0.5,
                            h = 0.5,
                            object = get_stake_sprite(G.GAME.stake or 1, 0.5),
                            hover = true,
                            can_collide = false,
                        },
                    },
                    { n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
                    {
                        n = G.UIT.T,
                        config = {
                            ref_table = G.GAME,
                            ref_value = "chips_text",
                            lang = G.LANGUAGES["en-us"],
                            scale = 0.85,
                            colour = G.C.WHITE,
                            id = "chip_UI_count",
                            func = "chip_UI_set",
                            shadow = true,
                        },
                    },
                },
            },
        },
    }
end
function MP.UI.enemy_location_definition()
    return {
        n = G.UIT.C,
        config = { align = "cm", padding = 0.1 },
        nodes = {
            {
                n = G.UIT.O,
                config = {
                    w = 0.5,
                    h = 0.5,
                    object = get_stake_sprite(G.GAME.stake or 1, 0.5),
                    hover = true,
                    can_collide = false,
                },
            },
            {
                n = G.UIT.C,
                config = { align = "cm", minw = 1.2 },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0, maxw = 1.2 },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = localize("ml_enemy_loc")[1],
                                    scale = 0.42,
                                    colour = G.C.UI.TEXT_LIGHT,
                                    shadow = true,
                                },
                            },
                        },
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0, maxw = 1.2 },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = localize("ml_enemy_loc")[2],
                                    scale = 0.42,
                                    colour = G.C.UI.TEXT_LIGHT,
                                    shadow = true,
                                },
                            },
                        },
                    },
                },
            },
            {
                n = G.UIT.C,
                config = { align = "cm", minw = 2.8, minh = 0.7, r = 0.1, colour = G.C.DYN_UI.BOSS_DARK },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = {
                            maxw = 2.2,
                            align = "cm",
                        },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    ref_table = MP.GAME.enemy,
                                    ref_value = "location",
                                    scale = 0.35,
                                    colour = G.C.WHITE,
                                    id = "chip_UI_count",
                                    shadow = true,
                                    maxw = 2.5,
                                },
                            },
                        }
                    },
                    { n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
                    {
                        n = G.UIT.O,
                        config = {
                            object = MP.UI.enemy_location_blind_render(),
                            id = "mp_enemy_location_render"
                        }
                    }
                },
            },
        },
    }
end

function MP.UI.show_enemy_location()
	local row_dollars_chips = G.HUD:get_UIE_by_ID("row_dollars_chips")
	if row_dollars_chips then
		row_dollars_chips.children[1]:remove()
		row_dollars_chips.children[1] = nil
		G.HUD:add_child(MP.UI.enemy_location_definition(), row_dollars_chips)
	end
end
function MP.UI.hide_enemy_location()
	local row_dollars_chips = G.HUD:get_UIE_by_ID("row_dollars_chips")
	if row_dollars_chips then
		row_dollars_chips.children[1]:remove()
		row_dollars_chips.children[1] = nil
		G.HUD:add_child(MP.UI.round_score_definition(), row_dollars_chips)
	end
end

function MP.UI.update_enemy_location_render()
    local renderer = G.HUD:get_UIE_by_ID("mp_enemy_location_render")
    if renderer then
        local blind_object_render = MP.UI.enemy_location_blind_render()
        renderer.config.object:remove()
        renderer.config.object = blind_object_render
        blind_object_render.parent = renderer

        renderer.UIBox:recalculate()
    end

    local hover_renderer = G.mp_enemy_location_ui and G.mp_enemy_location_ui:get_UIE_by_ID("mp_enemy_location_render")

    if hover_renderer then
        local blind_object_render = MP.UI.enemy_location_blind_render()
        hover_renderer.config.object:remove()
        hover_renderer.config.object = blind_object_render
        blind_object_render.parent = hover_renderer

        hover_renderer.UIBox:recalculate()
    end
end

G.FUNCS.mp_setup_hover_enemy_location_display = function(e)
    e.config.func = nil
    e.states.collide.can = true
    e.states.hover.can = true

    local old_hover = e.hover
    function e:hover(...)
        old_hover(self, ...)
        if not G.mp_enemy_location_ui then
            G.mp_enemy_location_ui = UIBox({
                definition = {
                    n = G.UIT.ROOT,
                    config = { colour = G.C.DYN_UI.BOSS_MAIN, emboss = 0.05, r = 0.25, },
                    nodes = {
                        MP.UI.enemy_location_definition()
                    }
                },
                config = {
                    align = "tmi",
                    offset = { x = 0, y = self.T.h + 0.15 },
                    major = self,
                    instance_type = "CARD",
                }
            })
        end
    end
    local old_stop_hover = e.stop_hover
    function e:stop_hover(...)
        old_stop_hover(self, ...)
        if G.mp_enemy_location_ui then
            G.mp_enemy_location_ui:remove()
            G.mp_enemy_location_ui = nil
        end
    end
    local old_remove = e.remove
    function e:remove(...)
        old_remove(self, ...)
        if G.mp_enemy_location_ui then
            G.mp_enemy_location_ui:remove()
            G.mp_enemy_location_ui = nil
        end
    end
end