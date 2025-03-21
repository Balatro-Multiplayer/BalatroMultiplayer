function MP.UI.Disableable_Button(args)
	local enabled_table = args.enabled_ref_table or {}
	local enabled = enabled_table[args.enabled_ref_value]
	args.colour = args.colour or G.C.RED
	args.text_colour = args.text_colour or G.C.UI.TEXT_LIGHT
	args.disabled_text = args.disabled_text or args.label
	args.label = not enabled and args.disabled_text or args.label

	local button_component = UIBox_button(args)
	button_component.nodes[1].config.button = enabled and args.button or nil
	button_component.nodes[1].config.hover = enabled
	button_component.nodes[1].config.shadow = enabled
	button_component.nodes[1].config.colour = enabled and args.colour or G.C.UI.BACKGROUND_INACTIVE
	button_component.nodes[1].nodes[1].nodes[1].colour = enabled and args.text_colour or G.C.UI.TEXT_INACTIVE
	button_component.nodes[1].nodes[1].nodes[1].shadow = enabled
	return button_component
end