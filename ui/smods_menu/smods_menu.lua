SMODS.Mods.Multiplayer.credits_tab = MP.UI.create_credits_tab

SMODS.Mods.Multiplayer.config_tab = MP.UI.create_config_tab

SMODS.Mods.Multiplayer.extra_tabs = MP.UI.create_extra_tabs

function G.FUNCS.bmp_discord(e)
	love.system.openURL("https://discord.gg/gEemz4ptuF")
end

function G.FUNCS.bmp_github(e)
	love.system.openURL("https://github.com/Balatro-Multiplayer/BalatroMultiplayer/")
end

function G.FUNCS.change_blind_col(args) -- all we're doing is just saving + redefining the ui elements here
	MP.UTILS.save_blind_col(args.to_val)
	MP.LOBBY.blind_col = args.to_val
	local sprite = G.OVERLAY_MENU:get_UIE_by_ID("blind_col_changer_sprite")
	sprite.config.object:remove()
	sprite.config.object = AnimatedSprite(
		0,
		0,
		1.4,
		1.4,
		G.ANIMATION_ATLAS["mp_player_blind_col"],
		G.P_BLINDS[MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col)].pos
	)
	sprite.config.object:define_draw_steps({
		{ shader = "dissolve", shadow_height = 0.05 },
		{ shader = "dissolve" },
	})
	sprite.UIBox:recalculate()
	local option = G.OVERLAY_MENU:get_UIE_by_ID("blind_col_changer_option")
	option.children[1].children[1].config.text =
		localize({ type = "name_text", key = MP.UTILS.blind_col_numtokey(MP.LOBBY.blind_col), set = "Blind" })
	option.UIBox:recalculate()
end

function G.FUNCS.mp_change_timersfx(args)
	SMODS.Mods["Multiplayer"].config.timersfx = args.to_key
	SMODS.save_mod_config(SMODS.Mods["Multiplayer"]) -- probably unnecessary?
end
