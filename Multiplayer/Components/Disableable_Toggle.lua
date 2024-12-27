function G.MULTIPLAYER.COMPONENTS.Disableable_Toggle(args)
	local enabled_table = args.enabled_ref_table or {}
	local enabled = enabled_table[args.enabled_ref_value]

	local toggle_component = create_toggle(args)
	toggle_component.nodes[2].nodes[1].nodes[1].config.id = args.id
	toggle_component.nodes[2].nodes[1].nodes[1].config.button = enabled and "toggle_button" or nil
	toggle_component.nodes[2].nodes[1].nodes[1].config.button_dist = enabled and 0.2 or nil
	toggle_component.nodes[2].nodes[1].nodes[1].config.hover = enabled and true or false
	toggle_component.nodes[2].nodes[1].nodes[1].config.toggle_callback = enabled and args.callback or nil
	return toggle_component
end

--[[ create_toggle returns this
  {
    n=args.col and G.UIT.C or G.UIT.R, 
    config={
      align = "cm", 
      padding = 0.1, 
      r = 0.1,
      colour = G.C.CLEAR, 
      focus_args = {funnel_from = true}
    }, 
    nodes={
      {
        n=G.UIT.C, 
        config={
          align = "cr", 
          minw = args.w
        }, 
        nodes={
          {
            n=G.UIT.T, 
            config={
              text = args.label, 
              scale = args.label_scale, 
              colour = G.C.UI.TEXT_LIGHT
            }
          },
          {
            n=G.UIT.B, 
            config={
              w = 0.1, 
              h = 0.1
            }
          },
        }
      },
      {
        n=G.UIT.C, 
        config={
          align = "cl", 
          minw = 0.3*args.w
        },
        nodes={
          {
            n=G.UIT.C, 
            config={
              align = "cm", 
              r = 0.1, 
              colour = G.C.BLACK
            }, 
            nodes={
              {
                n=G.UIT.C, 
                config={
                  align = "cm", 
                  r = 0.1, 
                  padding = 0.03, 
                  minw = 0.4*args.scale, 
                  minh = 0.4*args.scale, 
                  outline_colour = G.C.WHITE, 
                  outline = 1.2*args.scale, 
                  line_emboss = 0.5*args.scale, 
                  ref_table = args,
                  colour = args.inactive_colour, 
                  button = 'toggle_button', 
                  button_dist = 0.2, 
                  hover = true,
                  toggle_callback = args.callback, 
                  func = 'toggle', 
                  focus_args = {funnel_to = true}
                }, 
                nodes={
                  {
                    n=G.UIT.O, 
                    config={
                      object = check
                    }
                  },
                }
              },
            }
          }
        }
      },
    }
  }
]]
