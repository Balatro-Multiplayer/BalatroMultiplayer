SMODS.Atlas({
  key = "prophet",
  path = "t_prophet.jpeg", -- Assign a single string value to match the expected type
  px = 71,
  py = 95,
})

SMODS.Consumable({
  key = "mp_prophet",
  set = "Tarot",
  atlas = "prophet",
  cost = 3,
  unlocked = true,
  discovered = true,
  loc_txt = {
		name = "The Prophet",
		text = {
			"View all {C:attention}Jokers{} and",
			"see their position in",
			"your seeded {C:attention}shop queue{}"
		}
	},
  loc_vars = function(self, info_queue, card)
    MP.UTILS.add_nemesis_info(info_queue)
    return { vars = {} }
  end,
  in_pool = function(self)
    return MP.LOBBY.code
  end,
  can_use = function(self, card)
    return true
  end,
  use = function(self, card, area, copier)
    local _card = copier or card
    G.E_MANAGER:add_event(Event({
      trigger = "after",
      delay = 0.4,
      func = function()
        play_sound("tarot1", 0.8, 1)
        card:juice_up(0.8, 0.5)
        
        -- Create prophet joker selection UI
        MP.create_prophet_ui()
        
        return true
      end,
    }))
  end,
  mp_credits = {
    idea = { "Oliver Marker" },
    art = { "Jonah Jaffe" },
    code = { "Oliver Marker" },
  },
})

-- Function to create the prophet UI showing all jokers using collection-style UI
function MP.create_prophet_ui()
  -- Use SMODS collection system for jokers with custom behavior
  local pool = SMODS.collection_pool(G.P_CENTER_POOLS.Joker)
  local rows = {5, 5, 5} -- 5 jokers per row, 3 rows per page (15 total per page)
  
  -- Create card areas for the prophet collection
  G.prophet_collection = {}
  local deck_tables = {}
  local cards_per_page = 0
  local row_totals = {}
  
  for j = 1, #rows do
    row_totals[j] = cards_per_page
    cards_per_page = cards_per_page + rows[j]
    G.prophet_collection[j] = CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2, G.ROOM.T.h,
      (rows[j]+0.25)*G.CARD_W,
      0.95*G.CARD_H, 
      {card_limit = rows[j], type = 'title', highlight_limit = 0, collection = true}
    )
    table.insert(deck_tables, {
      n = G.UIT.R, 
      config = {align = "cm", padding = 0.07, no_fill = true}, 
      nodes = {{n = G.UIT.O, config = {object = G.prophet_collection[j]}}}
    })
  end
  
  -- Create pagination options
  local options = {}
  for i = 1, math.ceil(#pool/cards_per_page) do
    table.insert(options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#pool/cards_per_page)))
  end
  
  -- Function to handle page changes
  G.FUNCS.prophet_collection_page = function(e)
    if not e or not e.cycle_config then return end
    for j = 1, #G.prophet_collection do
      for i = #G.prophet_collection[j].cards, 1, -1 do
        local c = G.prophet_collection[j]:remove_card(G.prophet_collection[j].cards[i])
        c:remove()
        c = nil
      end
    end
    
    for j = 1, #rows do
      for i = 1, rows[j] do
        local center = pool[i+row_totals[j] + (cards_per_page*(e.cycle_config.current_option - 1))]
        if not center then break end
        local card = Card(G.prophet_collection[j].T.x + G.prophet_collection[j].T.w/2, G.prophet_collection[j].T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, center)
        
        -- Make the card clickable for Prophet functionality
        card.states.hover.can = true
        card.click = function()
          -- Calculate and show position for this joker
          MP.show_joker_position(center.key, center)
        end
        
        card:start_materialize(nil, i>1 or j>1)
        G.prophet_collection[j]:emplace(card)
      end
    end
  end
  
  -- Initialize with first page
  G.FUNCS.prophet_collection_page{ cycle_config = { current_option = 1 }}
  
  -- Create the UI
  local ui_definition = create_UIBox_generic_options({
    back_func = 'close_prophet_ui',
    contents = {
      {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
        {n = G.UIT.T, config = {
          text = "Select a Joker to See Queue Position", 
          scale = 0.5, 
          colour = G.C.WHITE
        }}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {
        {n = G.UIT.T, config = {
          text = "Click any joker to find out how far away it is in your seeded queue", 
          scale = 0.3, 
          colour = G.C.UI.TEXT_LIGHT
        }}
      }},
      {n = G.UIT.R, config = {align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes = deck_tables}, 
      (cards_per_page < #pool) and {n = G.UIT.R, config = {align = "cm"}, nodes = {
        create_option_cycle({
          options = options, 
          w = 4.5, 
          cycle_shoulders = true, 
          opt_callback = 'prophet_collection_page', 
          current_option = 1, 
          colour = G.C.RED, 
          no_pips = true, 
          focus_args = {snap_to = true, nav = 'wide'}
        })
      }} or nil,
    }
  })
  
  -- Show the overlay
  G.FUNCS.overlay_menu({
    definition = ui_definition,
  })
end

-- Function to show a specific joker's position (called when clicking a joker)
function MP.show_joker_position(joker_key, center)
  -- Calculate this joker's position in the queue
  local max_rerolls = 1000 -- Same value used in calculation
  local position = MP.calculate_joker_position(joker_key)
  
  local position_text, position_color, position_detail
  if position then
    position_text = "Position #" .. position .. " in joker queue"
    position_color = position <= 20 and G.C.GREEN or 
            position <= 100 and G.C.ORANGE or G.C.WHITE
    
    if position <= 20 then
      position_detail = "Very close! Only " .. (position - 1) .. " joker" .. (position == 2 and "" or "s") .. " ahead of it."
    elseif position <= 100 then
      position_detail = "Moderately far. " .. (position - 1) .. " jokers ahead of it."
    else
      position_detail = "Far away. " .. (position - 1) .. " jokers ahead of it."
    end
  else
    position_text = "Not found in next " .. max_rerolls .. " shop rerolls"
    position_color = G.C.RED
    position_detail = "This joker may be banned, not available in the current pool, or appears beyond " .. max_rerolls .. " rerolls."
  end
  
  -- Create detailed info UI
  local info_ui = create_UIBox_generic_options({
    back_func = 'prophet_back_to_collection',
    contents = {
      {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
        {n = G.UIT.T, config = {
          text = center.name, 
          scale = 0.6, 
          colour = G.C.WHITE
        }}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
        {n = G.UIT.T, config = {
          text = position_text, 
          scale = 0.45, 
          colour = position_color
        }}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
        {n = G.UIT.T, config = {
          text = position_detail, 
          scale = 0.35, 
          colour = G.C.UI.TEXT_LIGHT
        }}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {
        {n = G.UIT.T, config = {
          text = "Rarity: " .. (center.rarity == 1 and "Common" or 
                     center.rarity == 2 and "Uncommon" or 
                     center.rarity == 3 and "Rare" or "Legendary"), 
          scale = 0.3, 
          colour = G.C.UI.TEXT_LIGHT
        }}
      }},
    }
  })
  
  -- Show detailed info
  G.FUNCS.overlay_menu({
    definition = info_ui,
  })
end

-- Function to close the prophet UI completely from detail view
G.FUNCS.prophet_back_to_collection = function(e)
  G.FUNCS.exit_overlay_menu(e)
  -- For debugging: reopen the prophet collection so you can check multiple jokers
  MP.create_prophet_ui()
end

-- Function to calculate a specific joker's position in the seeded joker queue
function MP.calculate_joker_position(joker_key)
  -- Check if the joker exists
  local joker_center = G.P_CENTERS[joker_key]
  if not joker_center then
    return nil -- Joker doesn't exist
  end
  
  -- CRITICAL: Save the ENTIRE pseudorandom state before simulation
  local saved_pseudorandom = copy_table(G.GAME.pseudorandom)
  
  -- Simple approach: use the same key_append as the shop ('sho')
  -- Let the RNG state advance naturally with each create_card call
  local max_jokers = 1000 -- Check next 1000 jokers in the queue
  
  for position = 1, max_jokers do
    -- Create a joker using the same key_append as the shop
    local test_card = create_card('Joker', nil, nil, nil, nil, nil, nil, 'sho')
    
    if test_card and test_card.config and test_card.config.center then
      local selected_joker = test_card.config.center.key
      
      -- Clean up the test card immediately to avoid memory issues
      if test_card.remove then
        test_card:remove()
      end
      
      -- Check if this is our target joker
      if selected_joker == joker_key or 
               (joker_key == "hanging_chad" and selected_joker == "mp_hanging_chad") then
        -- CRITICAL: Restore the ENTIRE pseudorandom state before returning
        G.GAME.pseudorandom = saved_pseudorandom
        return position
      end
    end
  end
  
  -- CRITICAL: Restore the ENTIRE pseudorandom state before returning (joker not found)
  G.GAME.pseudorandom = saved_pseudorandom
  return nil -- Not found in next 1000 positions
end

-- Close function for the Prophet UI
G.FUNCS.close_prophet_ui = function(e)
  -- Clean up prophet collection areas
  if G.prophet_collection then
    for j = 1, #G.prophet_collection do
      for i = #G.prophet_collection[j].cards, 1, -1 do
        local c = G.prophet_collection[j]:remove_card(G.prophet_collection[j].cards[i])
        if c then
          c:remove()
          c = nil
        end
      end
    end
    G.prophet_collection = nil
  end
  G.FUNCS.exit_overlay_menu(e)
end

