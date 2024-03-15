--- STEAMODDED HEADER
--- STEAMODDED SECONDARY FILE

----------------------------------------------
------------MOD GAME UI-----------------------

local Lobby = require "Lobby"

Game_UI = {}

local create_UIBox_options_ref = create_UIBox_options
function create_UIBox_options()
  if Lobby.code then
    local current_seed = nil
    local main_menu = nil
    local your_collection = nil
    local credits = nil

    G.E_MANAGER:add_event(Event({
      blockable = false,
      func = function()
        G.REFRESH_ALERTS = true
      return true
      end
    }))

    if G.STAGE == G.STAGES.RUN then
      main_menu = UIBox_button{ label = {'Return to Lobby'}, button = "go_to_menu", minw = 5}
      your_collection = UIBox_button{ label = {localize('b_collection')}, button = "your_collection", minw = 5, id = 'your_collection'}
      current_seed = {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
          {n=G.UIT.C, config={align = "cm", padding = 0}, nodes={
          {n=G.UIT.T, config={text = localize('b_seed')..": ", scale = 0.4, colour = G.C.WHITE}}
        }},
        {n=G.UIT.C, config={align = "cm", padding = 0, minh = 0.8}, nodes={
          {n=G.UIT.C, config={align = "cm", padding = 0, minh = 0.8}, nodes={
            {n=G.UIT.R, config={align = "cm", r = 0.1, colour = G.GAME.seeded and G.C.RED or G.C.BLACK, minw = 1.8, minh = 0.5, padding = 0.1, emboss = 0.05}, nodes={
              {n=G.UIT.C, config={align = "cm"}, nodes={
                {n=G.UIT.T, config={ text = tostring(G.GAME.pseudorandom.seed), scale = 0.43, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
              }}
            }}
          }}
        }},
        UIBox_button({col = true, button = 'copy_seed', label = {localize('b_copy')}, colour = G.C.BLUE, scale = 0.3, minw = 1.3, minh = 0.5,}),
      }}
    end
    if G.STAGE == G.STAGES.MAIN_MENU then
      credits = UIBox_button{ label = {localize('b_credits')}, button = "show_credits", minw = 5}
    end

    local settings = UIBox_button({button = 'settings', label = {localize('b_settings')}, minw = 5, focus_args = {snap_to = true}})
    local high_scores = UIBox_button{ label = {localize('b_stats')}, button = "high_scores", minw = 5}

    local t = create_UIBox_generic_options({ contents = {
        settings,
        G.GAME.seeded and current_seed or nil,
        main_menu,
        high_scores,
        your_collection,
        credits
      }})
    return t
  else
    return create_UIBox_options_ref()
  end
end

local create_UIBox_blind_choice_ref = create_UIBox_blind_choice
function create_UIBox_blind_choice(type, run_info)
  if Lobby.code then
    if not G.GAME.blind_on_deck then
      G.GAME.blind_on_deck = 'Small'
    end
    if not run_info then G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = 'Select' end
  
    local disabled = false
    type = type or 'Small'
  
    local blind_choice = {
      config = G.P_BLINDS[G.GAME.round_resets.blind_choices[type]],
    }
  
    blind_choice.animation = AnimatedSprite(0,0, 1.4, 1.4, G.ANIMATION_ATLAS['blind_chips'],  blind_choice.config.pos)
    blind_choice.animation:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'}
    })
    local extras = nil
    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)
  
    G.GAME.orbital_choices = G.GAME.orbital_choices or {}
    G.GAME.orbital_choices[G.GAME.round_resets.ante] = G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}
  
    if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then 
      local _poker_hands = {}
      for k, v in pairs(G.GAME.hands) do
          if v.visible then _poker_hands[#_poker_hands+1] = k end
      end
  
      G.GAME.orbital_choices[G.GAME.round_resets.ante][type] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
    end
  
    if type == 'Small' then
      extras = nil
    elseif type == 'Big' then
      extras = nil
    elseif not run_info then
      local dt1 = DynaText({string = {{string = 'LIFE', colour = G.C.FILTER}}, colours = {G.C.BLACK}, scale = 0.55, silent = true, pop_delay = 4.5, shadow = true, bump = true, maxw = 3})
      local dt2 = DynaText({string = {{string = 'or', colour = G.C.WHITE}},colours = {G.C.CHANCE}, scale = 0.35, silent = true, pop_delay = 4.5, shadow = true, maxw = 3})
      local dt3 = DynaText({string = {{string = 'DEATH', colour = G.C.FILTER}}, colours = {G.C.BLACK}, scale = 0.55, silent = true, pop_delay = 4.5, shadow = true, bump = true, maxw = 3})
      extras = 
      {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.R, config={align = "cm", padding = 0.07, r = 0.1, colour = {0,0,0,0.12}, minw = 2.9}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = dt1}},
            }},
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = dt2}},
            }},
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = dt3}},
            }},
          }},
        }}
    end
    G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante

    local loc_target = localize{type = 'raw_descriptions', key = blind_choice.config.key, set = 'Blind', vars = {localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands')}}
    local loc_name = localize{type = 'name_text', key = blind_choice.config.key, set = 'Blind'}
    local blind_col = get_blind_main_colour(type)
    local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante)*blind_choice.config.mult*G.GAME.starting_params.ante_scaling

    if G.GAME.round_resets.blind_choices[type] == 'bl_pvp' then
      blind_amt = '????'
    end

    local text_table = loc_target
  
    local blind_state = G.GAME.round_resets.blind_states[type]
    local _reward = true
    if G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward[type] then _reward = nil end
    if blind_state == 'Select' then blind_state = 'Current' end
    local run_info_colour = run_info and (blind_state == 'Defeated' and G.C.GREY or blind_state == 'Skipped' and G.C.BLUE or blind_state == 'Upcoming' and G.C.ORANGE or blind_state == 'Current' and G.C.RED or G.C.GOLD)
    local t = 
    {n=G.UIT.R, config={id = type, align = "tm", func = 'blind_choice_handler', minh = not run_info and 10 or nil, ref_table = {deck = nil, run_info = run_info}, r = 0.1, padding = 0.05}, nodes={
      {n=G.UIT.R, config={align = "cm", colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5), r = 0.1, outline = 1, outline_colour = G.C.L_BLACK}, nodes={  
        {n=G.UIT.R, config={align = "cm", padding = 0.2}, nodes={
            not run_info and {n=G.UIT.R, config={id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or G.C.ORANGE, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'select_blind'}, nodes={
              {n=G.UIT.T, config={ref_table = G.GAME.round_resets.loc_blind_states, ref_value = type, scale = 0.45, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT, shadow = not disabled}}
            }} or 
            {n=G.UIT.R, config={id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = run_info_colour, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, emboss = 0.08}, nodes={
              {n=G.UIT.T, config={text = localize(blind_state, 'blind_states'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
            }}
          }},
          {n=G.UIT.R, config={id = 'blind_name',align = "cm", padding = 0.07}, nodes={
            {n=G.UIT.R, config={align = "cm", r = 0.1, outline = 1, outline_colour = blind_col, colour = darken(blind_col, 0.3), minw = 2.9, emboss = 0.1, padding = 0.07, line_emboss = 1}, nodes={
              {n=G.UIT.O, config={object = DynaText({string = loc_name, colours = {disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE}, shadow = not disabled, float = not disabled, y_offset = -4, scale = 0.45, maxw =2.8})}},
            }},
          }},
          {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
            {n=G.UIT.R, config={id = 'blind_desc', align = "cm", padding = 0.05}, nodes={
              {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.R, config={align = "cm", minh = 1.5}, nodes={
                  {n=G.UIT.O, config={object = blind_choice.animation}},
                }},
                text_table[1] and {n=G.UIT.R, config={align = "cm", minh = 0.7, padding = 0.05, minw = 2.9}, nodes={
                  text_table[1] and {n=G.UIT.R, config={align = "cm", maxw = 2.8}, nodes={
                    {n=G.UIT.T, config={id = blind_choice.config.key, ref_table = {val = ''}, ref_value = 'val', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled, func = 'HUD_blind_debuff_prefix'}},
                    {n=G.UIT.T, config={text = text_table[1] or '-', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}}
                  }} or nil,
                  text_table[2] and {n=G.UIT.R, config={align = "cm", maxw = 2.8}, nodes={
                    {n=G.UIT.T, config={text = text_table[2] or '-', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}}
                  }} or nil,
                }} or nil,
              }},
              {n=G.UIT.R, config={align = "cm",r = 0.1, padding = 0.05, minw = 3.1, colour = G.C.BLACK, emboss = 0.05}, nodes={
                {n=G.UIT.R, config={align = "cm", maxw = 3}, nodes={
                  {n=G.UIT.T, config={text = localize('ph_blind_score_at_least'), scale = 0.3, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}}
                }},
                {n=G.UIT.R, config={align = "cm", minh = 0.6}, nodes={
                  {n=G.UIT.O, config={w=0.5,h=0.5, colour = G.C.BLUE, object = stake_sprite, hover = true, can_collide = false}},
                  {n=G.UIT.B, config={h=0.1,w=0.1}},
                  {n=G.UIT.T, config={text = number_format(blind_amt), scale = score_number_scale(0.9, blind_amt), colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.RED, shadow =  not disabled}}
                }},
                _reward and {n=G.UIT.R, config={align = "cm"}, nodes={
                  {n=G.UIT.T, config={text = localize('ph_blind_reward'), scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled}},
                  {n=G.UIT.T, config={text = string.rep(localize("$"), blind_choice.config.dollars)..'+', scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.MONEY, shadow = not disabled}}
                }} or nil,
              }},
            }},
          }},
        }},
          {n=G.UIT.R, config={id = 'blind_extras', align = "cm"}, nodes={
            extras,
          }}
  
      }}
    return t
  else
    return create_UIBox_blind_choice_ref(type, run_info)
  end
end

function Game_UI.update_enemy()
  if Lobby.code then
    G.HUD_blind.alignment.offset.y = -10
    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.3,
      blockable = false,
      func = function()
        G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = Lobby.enemy
        G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = 'score'
        G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text = 'Current enemy score'
        G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text = 'Enemy hands left: '
        G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string = {{ref_table = Lobby.enemy, ref_value = 'hands'}}
        G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
        G.HUD_blind.alignment.offset.y = 0
        return true
      end
    }))
  end
end

function Game_UI.reset_blind_HUD()
  if Lobby.code then
    G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string = {{ref_table = G.GAME.blind, ref_value = 'loc_name'}}
    G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:update_text()
    G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_table = G.GAME.blind
    G.HUD_blind:get_UIE_by_ID("HUD_blind_count").config.ref_value = 'chip_text'
    G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[1].children[1].config.text = localize('ph_blind_score_at_least')
    G.HUD_blind:get_UIE_by_ID("HUD_blind").children[2].children[2].children[2].children[3].children[1].config.text = localize('ph_blind_reward')
    G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object.config.string = {{ref_table = G.GAME.current_round, ref_value = 'dollars_to_be_earned'}}
    G.HUD_blind:get_UIE_by_ID("dollars_to_be_earned").config.object:update_text()
  end
end

local update_draw_to_hand_ref = Game.update_draw_to_hand
function Game:update_draw_to_hand(dt)
  if Lobby.code then
    if not G.STATE_COMPLETE and G.GAME.current_round.hands_played == 0 and 
    G.GAME.current_round.discards_used == 0 and 
    G.GAME.facing_blind then
      if G.GAME.blind.name == 'Your Nemesis' then
        G.E_MANAGER:add_event(Event({
          trigger = 'after',
          delay = 1,
          blockable = false,
          func = function()
            G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:pop_out(0)
            Game_UI.update_enemy()
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.45,
              blockable = false,
              func = function()
                G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object.config.string = {{ref_table = Lobby.enemy, ref_value = 'username'}}
                G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:update_text()
                G.HUD_blind:get_UIE_by_ID("HUD_blind_name").config.object:pop_in(0)
                return true
              end
            }))
            return true
          end
        }))
      end
    end
  end
  update_draw_to_hand_ref(self,dt)
end

local blind_defeat_ref = Blind.defeat
function Blind:defeat(silent)
  blind_defeat_ref(self, silent)
  Game_UI.reset_blind_HUD()
end

return Game_UI
----------------------------------------------
------------MOD GAME UI END-------------------