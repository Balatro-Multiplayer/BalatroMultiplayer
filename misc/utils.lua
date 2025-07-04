MP.UTILS = {}

-- Credit to Henrik Ilgen (https://stackoverflow.com/a/6081639)
function MP.UTILS.serialize_table(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then
		tmp = tmp .. name .. " = "
	end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp = tmp
				.. MP.UTILS.serialize_table(v, k, skipnewlines, depth + 1)
				.. ","
				.. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
	end

	return tmp
end

-- Credit to Steamo (https://github.com/Steamopollys/Steamodded/blob/main/core/core.lua)
function MP.UTILS.wrapText(text, maxChars)
	local wrappedText = ""
	local currentLineLength = 0

	for word in text:gmatch("%S+") do
		if currentLineLength + #word <= maxChars then
			wrappedText = wrappedText .. word .. " "
			currentLineLength = currentLineLength + #word + 1
		else
			wrappedText = wrappedText .. "\n" .. word .. " "
			currentLineLength = #word + 1
		end
	end

	return wrappedText
end

function MP.UTILS.save_username(text)
	MP.ACTIONS.set_username(text)
	SMODS.Mods["Multiplayer"].config.username = text
end

function MP.UTILS.get_username()
	return SMODS.Mods["Multiplayer"].config.username
end

function MP.UTILS.save_blind_col(num)
	MP.ACTIONS.set_blind_col(num)
	SMODS.Mods["Multiplayer"].config.blind_col = num
end

function MP.UTILS.get_blind_col()
	return SMODS.Mods["Multiplayer"].config.blind_col
end

function MP.UTILS.blind_col_numtokey(num)
	local keys = {
		"tooth",
		"small",
		"big",
		"hook",
		"ox",
		"house",
		"wall",
		"wheel",
		"arm",
		"club",
		"fish",
		"psychic",
		"goad",
		"water",
		"window",
		"manacle",
		"eye",
		"mouth",
		"plant",
		"serpent",
		"pillar",
		"needle",
		"head",
		"flint",
		"mark",
	}
	return "bl_" .. (keys[num])
end

function MP.UTILS.get_nemesis_key() -- calling this function assumes the user is currently in a multiplayer game
	local ret = MP.UTILS.blind_col_numtokey((MP.LOBBY.is_host and MP.LOBBY.guest.blind_col or MP.LOBBY.host.blind_col) or
		1)
	if tonumber(MP.GAME.enemy.lives) <= 1 and tonumber(MP.GAME.lives) <= 1 then
		if G.STATE ~= G.STATES.ROUND_EVAL then -- very messy fix that mostly works. breaks in a different way... but far harder to notice
			ret = "bl_final_heart"
		end
	end
	return ret
end

function MP.UTILS.string_split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function MP.UTILS.copy_to_clipboard(text)
	if G.F_LOCAL_CLIPBOARD then
		G.CLIPBOARD = text
	else
		love.system.setClipboardText(text)
	end
end

function MP.UTILS.get_from_clipboard()
	if G.F_LOCAL_CLIPBOARD then
		return G.F_LOCAL_CLIPBOARD
	else
		return love.system.getClipboardText()
	end
end

function MP.UTILS.overlay_message(message)
	G.SETTINGS.paused = true
	local message_table = MP.UTILS.string_split(message, "\n")
	local message_ui = {
		{
			n = G.UIT.R,
			config = {
				padding = 0.2,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						scale = 0.8,
						shadow = true,
						text = "MULTIPLAYER",
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		},
	}

	for _, v in ipairs(message_table) do
		table.insert(message_ui, {
			n = G.UIT.R,
			config = {
				padding = 0.1,
				align = "cm",
			},
			nodes = {
				{
					n = G.UIT.T,
					config = {
						scale = 0.6,
						shadow = true,
						text = v,
						colour = G.C.UI.TEXT_LIGHT,
					},
				},
			},
		})
	end

	G.FUNCS.overlay_menu({
		definition = create_UIBox_generic_options({
			contents = {
				{
					n = G.UIT.C,
					config = {
						padding = 0.2,
						align = "cm",
					},
					nodes = message_ui,
				},
			},
		}),
	})
end

function MP.UTILS.get_joker(key)
	if not G.jokers or not G.jokers.cards then
		return nil
	end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then
			return G.jokers.cards[i]
		end
	end
	return nil
end

function MP.UTILS.get_phantom_joker(key)
	if not MP.shared or not MP.shared.cards then
		return nil
	end
	for i = 1, #MP.shared.cards do
		if
			MP.shared.cards[i].ability.name == key
			and MP.shared.cards[i].edition
			and MP.shared.cards[i].edition.type == "mp_phantom"
		then
			return MP.shared.cards[i]
		end
	end
	return nil
end

function MP.UTILS.run_for_each_joker(key, func)
	if not G.jokers or not G.jokers.cards then
		return
	end
	for i = 1, #G.jokers.cards do
		if G.jokers.cards[i].ability.name == key then
			func(G.jokers.cards[i])
		end
	end
end

function MP.UTILS.run_for_each_phantom_joker(key, func)
	if not MP.shared or not MP.shared.cards then
		return
	end
	for i = 1, #MP.shared.cards do
		if MP.shared.cards[i].ability.name == key then
			func(MP.shared.cards[i])
		end
	end
end

-- Credit to Cryptid devs for this function
local create_mod_badges_ref = SMODS.create_mod_badges
function SMODS.create_mod_badges(obj, badges)
	create_mod_badges_ref(obj, badges)
	if obj and obj.mp_credits then
		obj.mp_credits.art = obj.mp_credits.art or {}
		obj.mp_credits.idea = obj.mp_credits.idea or {}
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
			for _, v in ipairs({ "art", "idea", "code" }) do
				if obj.mp_credits[v] then
					for i = 1, #obj.mp_credits[v] do
						strings[#strings + 1] =
							localize({ type = "variable", key = "a_mp_" .. v, vars = { obj.mp_credits[v][i] } })[1]
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
							colour = G.C.MULTIPLAYER,
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
				if eq_col(badges[i].nodes[1].config.colour, G.C.MULTIPLAYER) then
					badges[i].nodes[1].nodes[2].config.object:remove()
					badges[i] = mp_badge
					break
				end
			end
		end
	end
end

function MP.UTILS.reverse_key_value_pairs(tbl, stringify_keys)
	local reversed_tbl = {}
	for k, v in pairs(tbl) do
		if stringify_keys then
			v = tostring(v)
		end
		reversed_tbl[v] = k
	end
	return reversed_tbl
end

function MP.UTILS.add_nemesis_info(info_queue)
	if MP.LOBBY.code then
		info_queue[#info_queue + 1] = {
			set = "Other",
			key = "current_nemesis",
			vars = { MP.LOBBY.is_host and MP.LOBBY.guest.username or MP.LOBBY.host.username },
		}
	end
end

function MP.UTILS.shallow_copy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function MP.UTILS.get_deck_key_from_name(_name)
	for k, v in pairs(G.P_CENTERS) do
		if v.name == _name then
			return k
		end
	end
end

function MP.UTILS.merge_tables(t1, t2)
	local copy = MP.UTILS.shallow_copy(t1)
	for k, v in pairs(t2) do
		copy[k] = v
	end
	return copy
end

local ease_dollars_ref = ease_dollars
function ease_dollars(mod, instant)
	sendTraceMessage(string.format("Client sent message: action:moneyMoved,amount:%s", tostring(mod)), "MULTIPLAYER")
	return ease_dollars_ref(mod, instant)
end

local sell_card_ref = Card.sell_card
function Card:sell_card()
	if self.ability and self.ability.name then
		sendTraceMessage(
			string.format("Client sent message: action:soldCard,card:%s", self.ability.name),
			"MULTIPLAYER"
		)
	end
	return sell_card_ref(self)
end

local reroll_shop_ref = G.FUNCS.reroll_shop
function G.FUNCS.reroll_shop(e)
	sendTraceMessage(
		string.format("Client sent message: action:rerollShop,cost:%s", G.GAME.current_round.reroll_cost),
		"MULTIPLAYER"
	)

	-- Update reroll stats if in a multiplayer game
	if MP.LOBBY.code and MP.GAME.stats then
		MP.GAME.stats.reroll_count = MP.GAME.stats.reroll_count + 1
		MP.GAME.stats.reroll_cost_total = MP.GAME.stats.reroll_cost_total + G.GAME.current_round.reroll_cost
	end

	return reroll_shop_ref(e)
end

local buy_from_shop_ref = G.FUNCS.buy_from_shop
function G.FUNCS.buy_from_shop(e)
	local c1 = e.config.ref_table
	if c1 and c1:is(Card) then
		sendTraceMessage(
			string.format("Client sent message: action:boughtCardFromShop,card:%s,cost:%s", c1.ability.name, c1.cost),
			"MULTIPLAYER"
		)
	end
	return buy_from_shop_ref(e)
end

local use_card_ref = G.FUNCS.use_card
function G.FUNCS.use_card(e, mute, nosave)
	if e.config and e.config.ref_table and e.config.ref_table.ability and e.config.ref_table.ability.name then
		sendTraceMessage(
			string.format("Client sent message: action:usedCard,card:%s", e.config.ref_table.ability.name),
			"MULTIPLAYER"
		)
	end
	return use_card_ref(e, mute, nosave)
end

-- Pre-compile a reversed list of all the centers
local reversed_centers = nil

function MP.UTILS.card_to_string(card)
	if not card or not card.base or not card.base.suit or not card.base.value then
		return ""
	end

	if not reversed_centers then
		reversed_centers = MP.UTILS.reverse_key_value_pairs(G.P_CENTERS)
	end

	local suit = string.sub(card.base.suit, 1, 1)

	local rank_value_map = {
		['10'] = 'T', Jack = 'J', Queen = 'Q', King = 'K', Ace = 'A'
	}
	local rank = rank_value_map[card.base.value] or card.base.value

	local enhancement = reversed_centers[card.config.center] or "none"
	local edition = card.edition and MP.UTILS.reverse_key_value_pairs(card.edition, true)["true"] or "none"
	local seal = card.seal or "none"

	local card_str = suit .. "-" .. rank .. "-" .. enhancement .. "-" .. edition .. "-" .. seal

	return card_str
end

function MP.UTILS.joker_to_string(card)
	if not card or not card.config or not card.config.center or not card.config.center.key then
		return ""
	end

	local edition = card.edition and MP.UTILS.reverse_key_value_pairs(card.edition, true)["true"] or "none"
	local eternal_or_perishable = "none"
	if card.ability then
		if card.ability.eternal then
			eternal_or_perishable = "eternal"
		elseif card.ability.perishable then
			eternal_or_perishable = "perishable"
		end
	end
	local rental = (card.ability and card.ability.rental) and "rental" or "none"

	local joker_string = card.config.center.key .. "-" .. edition .. "-" .. eternal_or_perishable .. "-" .. rental

	return joker_string
end

function MP.UTILS.unlock_check()
	local notFullyUnlocked = false

	for k, v in pairs(G.P_CENTER_POOLS.Joker) do
		if not v.unlocked then
			notFullyUnlocked = true
			break -- No need to keep checking once we know it's not fully unlocked
		end
	end

	return not notFullyUnlocked
end

function MP.UTILS.encrypt_ID()
	local encryptID = 1
	for key, center in pairs(G.P_CENTERS or {}) do
		if type(key) == "string" and key:match("^j_") then
			if center.cost and type(center.cost) == "number" then
				encryptID = encryptID + center.cost
			end
			if center.config and type(center.config) == "table" then
				encryptID = encryptID + MP.UTILS.sum_numbers_in_table(center.config)
			end
		elseif type(key) == "string" and key:match("^[cvp]_") then
			if center.cost and type(center.cost) == "number" then
				if center.cost == 0 then
					return 0
				end
				encryptID = encryptID + center.cost
			end
		end
	end
	for key, value in pairs(G.GAME.starting_params or {}) do
		if type(value) == "number" and value % 1 == 0 then
			encryptID = encryptID * value
		end
	end
	local day = tonumber(os.date("%d")) or 1
	encryptID = encryptID * day
	local gameSpeed = G.SETTINGS.GAMESPEED
	if gameSpeed then
		gameSpeed = gameSpeed * 16
		gameSpeed = gameSpeed + 7
		encryptID = encryptID + (gameSpeed / 1000)
	else
		encryptID = encryptID + 0.404
	end
	return encryptID
end

function MP.UTILS.parse_Hash(hash)
	local parts = {}
	for part in string.gmatch(hash, "([^;]+)") do
		table.insert(parts, part)
	end

	local config = {
		encryptID = nil,
		unlocked = nil,
		theOrder = nil
	}

	local mod_data = {}

	for _, part in ipairs(parts) do
		local key, val = string.match(part, "([^=]+)=([^=]+)")
		if key == "encryptID" then
			config.encryptID = tonumber(val)
		elseif key == "unlocked" then
			config.unlocked = val == "true"
		elseif key == "theOrder" then
			config.TheOrder = val == "true"
		elseif key ~= "serversideConnectionID" then
			table.insert(mod_data, part)
		end
	end

	return config, table.concat(mod_data, ";")
end

function MP.UTILS.sum_numbers_in_table(t)
	local sum = 0
	for k, v in pairs(t) do
		if type(v) == "number" then
			sum = sum + v
		elseif type(v) == "table" then
			sum = sum + MP.UTILS.sum_numbers_in_table(v)
		end
		-- ignore other types
	end
	return sum
end

function MP.UTILS.bxor(a, b)
	local res = 0
	local bitval = 1
	while a > 0 and b > 0 do
		local a_bit = a % 2
		local b_bit = b % 2
		if a_bit ~= b_bit then
			res = res + bitval
		end
		bitval = bitval * 2
		a = math.floor(a / 2)
		b = math.floor(b / 2)
	end
	res = res + (a + b) * bitval
	return res
end

function MP.UTILS.encrypt_string(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = MP.UTILS.bxor(hash, str:byte(i))
		hash = (hash * 16777619) % 2 ^ 32
	end
	return string.format("%08x", hash)
end

function MP.UTILS.server_connection_ID()
	local os_name = love.system.getOS()
	local raw_id

	if os_name == "Windows" then
		local ffi = require("ffi")

		ffi.cdef [[
		typedef unsigned long DWORD;
		typedef int BOOL;
		typedef const char* LPCSTR;

		BOOL GetVolumeInformationA(
			LPCSTR lpRootPathName,
			char* lpVolumeNameBuffer,
			DWORD nVolumeNameSize,
			DWORD* lpVolumeSerialNumber,
			DWORD* lpMaximumComponentLength,
			DWORD* lpFileSystemFlags,
			char* lpFileSystemNameBuffer,
			DWORD nFileSystemNameSize
		);
		]]

		local serial_ptr = ffi.new("DWORD[1]")
		local ok = ffi.C.GetVolumeInformationA(
			"C:\\", nil, 0,
			serial_ptr, nil, nil,
			nil, 0
		)
		if ok ~= 0 then
			raw_id = tostring(serial_ptr[0])
		end
	end

	if not raw_id then
		raw_id = os.getenv("USER")
			or os.getenv("USERNAME")
			or os_name
	end

	return MP.UTILS.encrypt_string(raw_id)
end

function MP.UTILS.random_message()
	local messages = {
		localize("k_message1"),
		localize("k_message2"),
		localize("k_message3"),
		localize("k_message4"),
		localize("k_message5"),
		localize("k_message6"),
		localize("k_message7"),
		localize("k_message8"),
		localize("k_message9"),
	}
	return messages[math.random(1, #messages)]
end

-- From https://github.com/lunarmodules/Penlight (MIT license)
local function save_global_env()
	local env = {}
	env.hook, env.mask, env.count = debug.gethook()

	-- env.hook is "external hook" if is a C hook function
	if env.hook ~= "external hook" then
		debug.sethook()
	end

	env.string_mt = getmetatable("")
	debug.setmetatable("", nil)
	return env
end

-- From https://github.com/lunarmodules/Penlight (MIT license)
local function restore_global_env(env)
	if env then
		debug.setmetatable("", env.string_mt)
		if env.hook ~= "external hook" then
			debug.sethook(env.hook, env.mask, env.count)
		end
	end
end

local function STR_UNPACK_CHECKED(str)
	-- Code generated from STR_PACK should only return a table and nothing else
	if str:sub(1, 8) ~= "return {" then
		error("Invalid string header, expected \"return {...\"")
	end

	-- Protect against code injection by disallowing function definitions
	-- This is a very naive check, but hopefully won't trigger false positives
	if str:find("[^\"'%w_]function[^\"'%w_]") then
		error("Function keyword detected")
	end

	-- Load with an empty environment, no functions or globals should be available
	local chunk = assert(load(str, nil, "t", {}))
	local global_env = save_global_env()
	local success, str_unpacked = pcall(chunk)
	restore_global_env(global_env)
	if not success then
		error(str_unpacked)
	end

	return str_unpacked
end

function MP.UTILS.str_pack_and_encode(data)
	local str = STR_PACK(data)
	local str_compressed = love.data.compress("string", "gzip", str)
	local str_encoded = love.data.encode("string", "base64", str_compressed)
	return str_encoded
end

function MP.UTILS.str_decode_and_unpack(str)
	local success, str_decoded, str_decompressed, str_unpacked
	success, str_decoded = pcall(love.data.decode, "string", "base64", str)
	if not success then return nil, str_decoded end
	success, str_decompressed = pcall(love.data.decompress, "string", "gzip", str_decoded)
	if not success then return nil, str_decompressed end
	success, str_unpacked = pcall(STR_UNPACK_CHECKED, str_decompressed)
	if not success then return nil, str_unpacked end
	return str_unpacked
end
