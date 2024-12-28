function G.MULTIPLAYER.COMPONENTS.Disableable_Option_Cycle(args)
	local enabled_table = args.enabled_ref_table or {}
	local enabled = enabled_table[args.enabled_ref_value]

	if not enabled then
		args.options = { args.options[args.current_option] }
		args.current_option = 1
	end

	local option_component = create_option_cycle(args)
	return option_component
end

--[[ create_option_cycle returns this
  {
    n = G.UIT.C, 
    config = {
      align = "cm", 
      padding = 0.1, 
      r = 0.1, 
      colour = G.C.CLEAR, 
      id = args.id and (not args.label and args.id or nil) or nil, 
      focus_args = args.focus_args
    }, 
    nodes={
      {
        n = G.UIT.C, 
        config = {
          align = "cm",
          r = 0.1, 
          minw = 0.6*args.scale, 
          hover = not disabled, 
          colour = not disabled and args.colour or G.C.BLACK,
          shadow = not disabled, 
          button = not disabled and 'option_cycle' or nil, 
          ref_table = args, 
          ref_value = 'l', 
          focus_args = {type = 'none'}
        }, 
        nodes = {
          {
            n = G.UIT.T, 
            config = {
              ref_table = args, 
              ref_value = 'l', 
              scale = args.text_scale, 
              colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE
            }
          }
        }
      },
      args.mid and { 
        n = G.UIT.C, 
        config = {
          id = 'cycle_main'
        }, 
        nodes = {
          { 
            n = G.UIT.R, 
            config = {
              align = "cm", 
              minh = 0.05
            }, 
            nodes = {
              args.mid
            }
          },
          not disabled and choice_pips or nil
        }
      }
      or { 
        n=G.UIT.C, 
        config = {
          id = 'cycle_main', 
          align = "cm", 
          minw = args.w, 
          minh = args.h, 
          r = 0.1, 
          padding = 0.05, 
          colour = args.colour,
          emboss = 0.1, 
          hover = true, 
          can_collide = true, 
          on_demand_tooltip = args.on_demand_tooltip
        }, 
        nodes={
          {
            n=G.UIT.R, 
            config={
              align = "cm"
            }, 
            nodes={
              {
                n=G.UIT.R, 
                config={
                  align = "cm"
                }, 
                nodes={
                  {
                    n=G.UIT.O, 
                    config={
                      object = DynaText({
                        string = {{
                          ref_table = args, 
                          ref_value = "current_option_val"
                        }}, 
                        colours = {G.C.UI.TEXT_LIGHT},
                        pop_in = 0, 
                        pop_in_rate = 8, 
                        reset_pop_in = true,
                        shadow = true, 
                        float = true, 
                        silent = true, 
                        bump = true, 
                        scale = args.text_scale, 
                        non_recalc = true
                      })
                    }
                  },
                }
              },
              {
                n=G.UIT.R, 
                config={
                  align = "cm", 
                  minh = 0.05
                }, 
                nodes={}
              },
              not disabled and choice_pips or nil
            }
          }
        }
      },
      {
        n=G.UIT.C, 
        config={
          align = "cm",
          r = 0.1, 
          minw = 0.6*args.scale, 
          hover = not disabled, 
          colour = not disabled and args.colour or G.C.BLACK,
          shadow = not disabled, 
          button = not disabled and 'option_cycle' or nil, 
          ref_table = args, 
          ref_value = 'r', 
          focus_args = {
            type = 'none'
          }
        }, 
        nodes={
          {
            n=G.UIT.T, 
            config={
              ref_table = args, 
              ref_value = 'r', 
              scale = args.text_scale, 
              colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE
            }
          }
        }
      },
    }
  }
]]
