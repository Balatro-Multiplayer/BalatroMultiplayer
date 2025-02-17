-- Credit to Cryptid devs for this function
local create_mod_badges_ref = SMODS.create_mod_badges
function SMODS.create_mod_badges(obj, badges)
	create_mod_badges_ref(obj, badges)
	if obj and obj.mp_credits then
		obj.mp_credits.idea = obj.mp_credits.idea or {}
		obj.mp_credits.art = obj.mp_credits.art or {}
		obj.mp_credits.code = obj.mp_credits.code or {}
		local function calc_scale_fac(text)
			local size = 0.9
			local font = G.LANG.font
			local max_text_width = 2 - 2 * 0.05 - 4 * 0.03 * size - 2 * 0.03
			local calced_text_width = 0
			-- Math reproduced from DynaText:update_text
			for _, c in utf8.chars(text) do
				local tx = font.FONT:getWidth(c) * (0.33 * size) * G.TILESCALE * font.FONTSCALE
					+ 2.7 * 1 * G.TILESCALE * font.FONTSCALE
				calced_text_width = calced_text_width + tx / (G.TILESIZE * G.TILESCALE)
			end
			local scale_fac = calced_text_width > max_text_width and max_text_width / calced_text_width or 1
			return scale_fac
		end
		if obj.mp_credits.art or obj.mp_credits.code or obj.mp_credits.idea then
			local scale_fac = {}
			local min_scale_fac = 1
			local strings = { "MULTIPLAYER" }
			for _, v in ipairs({ "idea", "art", "code" }) do
				if obj.mp_credits[v] then
					for i = 1, #obj.mp_credits[v] do
						strings[#strings + 1] =
							localize({ type = "variable", key = "mp_" .. v, vars = { obj.mp_credits[v][i] } })[1]
					end
				end
			end
			for i = 1, #strings do
				scale_fac[i] = calc_scale_fac(strings[i])
				min_scale_fac = math.min(min_scale_fac, scale_fac[i])
			end
			local ct = {}
			for i = 1, #strings do
				ct[i] = {
					string = strings[i],
				}
			end
			local mp_badge = {
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.R,
						config = {
							align = "cm",
							colour = G.C.MULITPLAYER,
							r = 0.1,
							minw = 2 / min_scale_fac,
							minh = 0.36,
							emboss = 0.05,
							padding = 0.03 * 0.9,
						},
						nodes = {
							{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
							{
								n = G.UIT.O,
								config = {
									object = DynaText({
										string = ct or "ERROR",
										colours = { obj.mp_credits and obj.mp_credits.text_colour or G.C.WHITE },
										silent = true,
										float = true,
										shadow = true,
										offset_y = -0.03,
										spacing = 1,
										scale = 0.33 * 0.9,
									}),
								},
							},
							{ n = G.UIT.B, config = { h = 0.1, w = 0.03 } },
						},
					},
				},
			}
			local function eq_col(x, y)
				for i = 1, 4 do
					if x[1] ~= y[1] then
						return false
					end
				end
				return true
			end
			for i = 1, #badges do
				if eq_col(badges[i].nodes[1].config.colour, G.C.MULITPLAYER) then
					badges[i].nodes[1].nodes[2].config.object:remove()
					badges[i] = mp_badge
					break
				end
			end
		end
	end
end

function add_nemesis_info(info_queue)
	if G.LOBBY.code then
		info_queue[#info_queue + 1] = {
			set = "Other",
			key = "current_nemesis",
			vars = { G.LOBBY.is_host and G.LOBBY.guest.username or G.LOBBY.host.username },
		}
	end
end
