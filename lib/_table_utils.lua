-- TODO docstring here for this
--

-- Credit to Henrik Ilgen (https://stackoverflow.com/a/6081639)
function MP.UTILS.serialize_table(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then tmp = tmp .. name .. " = " end

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

-- Used only for some UI blob, can be moved
function MP.UTILS.get_array_index_by_value(options, value)
	for i, v in ipairs(options) do
		if v == value then return i end
	end
	return nil
end

function MP.UTILS.reverse_key_value_pairs(tbl, stringify_keys)
	local reversed_tbl = {}
	for k, v in pairs(tbl) do
		if stringify_keys then v = tostring(v) end
		reversed_tbl[v] = k
	end
	return reversed_tbl
end

function MP.UTILS.shallow_copy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function MP.UTILS.merge_tables(t1, t2)
	local copy = MP.UTILS.shallow_copy(t1)
	for k, v in pairs(t2) do
		copy[k] = v
	end
	return copy
end
