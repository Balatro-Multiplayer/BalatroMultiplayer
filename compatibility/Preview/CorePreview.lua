-- The functions responsible for running the simulation at appropriate times;
-- ie. whenever the player modifies card selection or card order.

function FN.PRE.simulate()
	-- Guard against simulating in redundant places:
	if FN.PRE.five_second_coroutine and coroutine.status(FN.PRE.five_second_coroutine) == "suspended" then
		coroutine.resume(FN.PRE.five_second_coroutine)
	end
	if
		not (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.PLAY_TAROT)
	then
		return { score = { min = 0, exact = 0, max = 0 }, dollars = { min = 0, exact = 0, max = 0 } }
	end

	if G.SETTINGS.FN.hide_face_down then
		for _, card in ipairs(G.hand.highlighted) do
			if card.facing == "back" then return nil end
		end
		if #G.hand.highlighted ~= 0 then
			for _, joker in ipairs(G.jokers.cards) do
				if joker.facing == "back" then return nil end
			end
		end
	end

	return FN.SIM.run()
end

-- SIMULATION UPDATE ADVICE:

function FN.PRE.add_update_event(trigger)
	function sim_func()
		FN.PRE.data = FN.PRE.simulate()
		return true
	end
	if FN.PRE.enabled() then G.E_MANAGER:add_event(Event({ trigger = trigger, func = sim_func })) end
end

-- Update simulation after a consumable (eg. Tarot, Planet) is used:
local orig_use = Card.use_consumeable
function Card:use_consumeable(area, copier)
	orig_use(self, area, copier)
	if not MP.INTEGRATIONS.Preview then return end
	FN.PRE.add_update_event("immediate")
end

-- Update simulation after card selection changed:
local orig_hl = CardArea.parse_highlighted
function CardArea:parse_highlighted()
	orig_hl(self)
	if not MP.INTEGRATIONS.Preview then return end

	if not FN.PRE.lock_updates and FN.PRE.show_preview then FN.PRE.show_preview = false end
	FN.PRE.add_update_event("immediate")
end

-- Update simulation after joker sold:
local orig_card_remove = Card.remove_from_area
function Card:remove_from_area()
	orig_card_remove(self)
	if not MP.INTEGRATIONS.Preview then return end

	if self.config.type == "joker" then FN.PRE.add_update_event("immediate") end
end

-- Update simulation after joker reordering:
local orig_update = CardArea.update
function CardArea:update(dt)
	orig_update(self, dt)
	if not MP.INTEGRATIONS.Preview then return end

	FN.PRE.update_on_card_order_change(self)
end

function FN.PRE.update_on_card_order_change(cardarea)
	if
		#cardarea.cards == 0
		or not (
			G.STATE == G.STATES.SELECTING_HAND
			or G.STATE == G.STATES.DRAW_TO_HAND
			or G.STATE == G.STATES.PLAY_TAROT
		)
	then
		return
	end
	-- Important not to update on G.STATES.HAND_PLAYED, because it would reset the preview text!
	if G.STATE == G.STATES.HAND_PLAYED then return end

	local prev_order = nil
	if cardarea.config.type == "joker" and cardarea.cards[1].ability.set == "Joker" then
		if cardarea.cards[1].edition and cardarea.cards[1].edition.mp_phantom then return end
		-- Note that the consumables cardarea also has type 'joker' so must verify by checking first card.
		prev_order = FN.PRE.joker_order
	elseif cardarea.config.type == "hand" then
		prev_order = FN.PRE.hand_order
	else
		return
	end

	-- Go through stored card IDs and check against current card IDs, in-order.
	-- If any mismatch occurs, toggle flag and update name for next time.
	local should_update = false
	if #cardarea.cards ~= #prev_order then prev_order = {} end
	for i, c in ipairs(cardarea.cards) do
		if c.sort_id ~= prev_order[i] then
			prev_order[i] = c.sort_id
			should_update = true
		end
	end

	if should_update then
		if cardarea.config.type == "joker" or cardarea.cards[1].ability.set == "Joker" then
			FN.PRE.joker_order = prev_order
		elseif cardarea.config.type == "hand" then
			FN.PRE.hand_order = prev_order
		end
		if FN.PRE.show_preview and not FN.PRE.lock_updates then FN.PRE.show_preview = false end
		FN.PRE.add_update_event("immediate")
	end
end

-- SIMULATION RESET ADVICE:

function FN.PRE.add_reset_event(trigger)
	function reset_func()
		FN.PRE.data = { score = { min = 0, exact = 0, max = 0 }, dollars = { min = 0, exact = 0, max = 0 } }
		return true
	end
	if FN.PRE.enabled() then G.E_MANAGER:add_event(Event({ trigger = trigger, func = reset_func })) end
end

local orig_eval = G.FUNCS.evaluate_play
function G.FUNCS.evaluate_play(e)
	orig_eval(e)

	if not MP.INTEGRATIONS.Preview then return end
	FN.PRE.add_reset_event("after")
end

local orig_discard = G.FUNCS.discard_cards_from_highlighted
function G.FUNCS.discard_cards_from_highlighted(e, is_hook_blind)
	orig_discard(e, is_hook_blind)

	if not MP.INTEGRATIONS.Preview then return end
	if not is_hook_blind then FN.PRE.add_reset_event("immediate") end
end

-- USER INTERFACE ADVICE:

-- Add animation to preview text:
function G.FUNCS.fn_pre_score_UI_set(e)
	local new_preview_text = ""
	local should_juice = false
	if FN.PRE.lock_updates then
		if e.config.id == "fn_pre_l" then
			new_preview_text = " " .. MP.UTILS.get_preview_cfg("text") .. " "
			should_juice = true
		end
	else
		if FN.PRE.data then
			if FN.PRE.show_preview and (FN.PRE.data.score.min ~= FN.PRE.data.score.max) then
				-- Format as 'X - Y' :
				if e.config.id == "fn_pre_l" then
					new_preview_text = FN.PRE.format_number(FN.PRE.data.score.min) .. " - "
					if FN.PRE.is_enough_to_win(FN.PRE.data.score.min) then should_juice = true end
				elseif e.config.id == "fn_pre_r" then
					new_preview_text = FN.PRE.format_number(FN.PRE.data.score.max)
					if FN.PRE.is_enough_to_win(FN.PRE.data.score.max) then should_juice = true end
				end
			else
				-- Format as single number:
				if e.config.id == "fn_pre_l" then
					if true then
						-- Spaces around number necessary to distinguish Min/Max text from Exact text,
						-- which is itself necessary to force a HUD update when switching between Min/Max and Exact.
						if FN.PRE.show_preview then
							new_preview_text = " " .. FN.PRE.format_number(FN.PRE.data.score.min) .. " "
							if FN.PRE.is_enough_to_win(FN.PRE.data.score.min) then should_juice = true end
						else
							if FN.PRE.is_enough_to_win(FN.PRE.data.score.min) then
								should_juice = true
								new_preview_text = "  "
							else
								if FN.PRE.is_enough_to_win(FN.PRE.data.score.max) then
									new_preview_text = "  "
									should_juice = true
								else
									new_preview_text = "  "
								end
							end
						end
					end
				else
					new_preview_text = ""
				end
			end
		else
			-- Spaces around number necessary to distinguish Min/Max text from Exact text, same as above ^
			if e.config.id == "fn_pre_l" then
				if true then
					new_preview_text = " ?????? "
				else
					new_preview_text = "??????"
				end
			else
				new_preview_text = ""
			end
		end
	end

	if (not FN.PRE.text.score[e.config.id:sub(-1)]) or new_preview_text ~= FN.PRE.text.score[e.config.id:sub(-1)] then
		FN.PRE.text.score[e.config.id:sub(-1)] = new_preview_text
		e.config.object:update_text()
		-- Wobble:
		if not G.TAROT_INTERRUPT_PULSE then
			if should_juice then
				G.FUNCS.text_super_juice(e, 5)
				e.config.object.colours = { G.C.MONEY }
			else
				G.FUNCS.text_super_juice(e, 0)
				e.config.object.colours = { G.C.UI.TEXT_LIGHT }
			end
		end
	end
end

function G.FUNCS.fn_pre_dollars_UI_set(e)
	local new_preview_text = ""
	local new_colour = nil
	if FN.PRE.data then
		if true and (FN.PRE.data.dollars.min ~= FN.PRE.data.dollars.max) then
			if e.config.id == "fn_pre_dollars_top" then
				new_preview_text = " " .. FN.PRE.get_sign_str(FN.PRE.data.dollars.max) .. FN.PRE.data.dollars.max
				new_colour = FN.PRE.get_dollar_colour(FN.PRE.data.dollars.max)
			elseif e.config.id == "fn_pre_dollars_bot" then
				new_preview_text = " " .. FN.PRE.get_sign_str(FN.PRE.data.dollars.min) .. FN.PRE.data.dollars.min
				new_colour = FN.PRE.get_dollar_colour(FN.PRE.data.dollars.min)
			end
		else
			if e.config.id == "fn_pre_dollars_top" then
				local _data = G.SETTINGS.FN.show_min_max and FN.PRE.data.dollars.min or FN.PRE.data.dollars.exact

				new_preview_text = " " .. FN.PRE.get_sign_str(_data) .. _data
				new_colour = FN.PRE.get_dollar_colour(_data)
			else
				new_preview_text = ""
				new_colour = FN.PRE.get_dollar_colour(0)
			end
		end
	else
		new_preview_text = " +??"
		new_colour = FN.PRE.get_dollar_colour(0)
	end

	if not FN.PRE.text.dollars[e.config.id:sub(-3)] or new_preview_text ~= FN.PRE.text.dollars[e.config.id:sub(-3)] then
		FN.PRE.text.dollars[e.config.id:sub(-3)] = new_preview_text
		e.config.object.colours = { new_colour }
		e.config.object:update_text()
		if not G.TAROT_INTERRUPT_PULSE then e.config.object:pulse(0.25) end
	end
end
