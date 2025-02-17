function G.MULTIPLAYER.COMPONENTS.Disableable_Button(args)
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

--[[ UIBox_button returns this
{
  n = G.UIT.C | G.UIT.R, 
  config = {
    align = 'cm'
  },
  nodes = {
    {
      n= G.UIT.C, 
      config={
        align = "cm",
        padding = args.padding or 0,
        r = 0.1,
        hover = true,
        colour = args.colour,
        one_press = args.one_press,
        button = (args.button ~= 'nil') and args.button or nil,
        choice = args.choice,
        chosen = args.chosen,
        focus_args = args.focus_args,
        minh = args.minh - 0.3*(args.count and 1 or 0),
        shadow = true,
        func = args.func,
        id = args.id,
        back_func = args.back_func,
        ref_table = args.ref_table,
        mid = args.mid
      }, 
      nodes = {
        n = G.UIT.R, 
        config = {
          align = "cm", 
          padding = 0, 
          minw = args.minw, 
          maxw = args.maxw
        }, 
        nodes = {
          {
            n = G.UIT.T, 
            config = {
              text = v, 
              scale = args.scale, 
              colour = args.text_colour, 
              shadow = args.shadow, 
              focus_args = button_pip and args.focus_args or nil, 
              func = button_pip, 
              ref_table = args.ref_table
            }
          }
        }
      }
    }
  }
}
]]
--

--[[ Reference disableable button
{
  n = G.UIT.R, 
  config={
    id = 'select_blind_button', 
    align = "cm", 
    ref_table = blind_choice.config, 
    colour = disabled and G.C.UI.BACKGROUND_INACTIVE or G.C.ORANGE, 
    minh = 0.6, 
    minw = 2.7, 
    padding = 0.07, 
    r = 0.1, 
    shadow = true, 
    hover = true, 
    one_press = true, 
    button = 'select_blind'
  }, 
  nodes = {
    {
      n = G.UIT.T, 
      config = {
        ref_table = G.GAME.round_resets.loc_blind_states, 
        ref_value = type, 
        scale = 0.45, 
        colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT, 
        shadow = not disabled
      }
    }
  }
}
]]
--
