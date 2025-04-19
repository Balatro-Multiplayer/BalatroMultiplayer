-- These functions are mostly just for handling really big numbers,
-- no matter the source and even if talisman is not installed.

-- This should NOT be used as a substitute for bigints in functional coded due to how barebones it is,
-- Instead, it should be used for graphical purposes and such 

MP.INSANE_INT = {}

MP.INSANE_INT.empty = function()
    return {
        coeffiocient = 0,
        exponent = 0,
        e_count = 0
    }
end

MP.INSANE_INT.create = function(coeffiocient, exponent, e_count)
    return {
        coeffiocient = tonumber(coeffiocient) or 0,
        exponent = tonumber(exponent) or 0,
        e_count = tonumber(e_count) or 0
    }
end

MP.INSANE_INT.from_string = function(str)
	local e_count = 0
	while #str > 0 and string.lower(string.sub(str, 1, 1)) == "e" do
		e_count = e_count + 1
		str = string.sub(str, 2)
	end

    local parts = MP.UTILS.string_split(str, "e")

    return MP.INSANE_INT.create(parts[1], #parts > 1 and parts[2] or 0, e_count)
end

MP.INSANE_INT.to_string = function(insane_int_display)
    local e = ""
    for i = 1, insane_int_display.e_count do
        e = e .. "e"
    end

    if insane_int_display.exponent == 0 then
        return e .. number_format(insane_int_display.coeffiocient)
    end

    return e .. number_format(insane_int_display.coeffiocient, 10000) .. "e" .. number_format(insane_int_display.exponent)
end

-- This doesn't really fit with the comment at the top,
-- but I needed a way to compare highscores without storing this value seperately for no reason
MP.INSANE_INT.greater_than = function(insane_int_display1, insane_int_display2)
    if insane_int_display1.e_count ~= insane_int_display2.e_count then
        return tonumber(insane_int_display1.e_count) > tonumber(insane_int_display2.e_count)
    end

    if insane_int_display1.exponent ~= insane_int_display2.exponent then
        return tonumber(insane_int_display1.exponent) > tonumber(insane_int_display2.exponent)
    end

    return tonumber(insane_int_display1.coeffiocient) > tonumber(insane_int_display2.coeffiocient)
end

MP.INSANE_INT.add = function(insane_int_display1, insane_int_display2)
    local starting_e_count
    local coeffiocient
    local exponent

    local myStartingECount = insane_int_display1.e_count
    local myCoefficient = insane_int_display1.coeffiocient
    local myExponent = insane_int_display1.exponent

    local otherStartingECount = insane_int_display2.e_count
    local otherCoefficient = insane_int_display2.coeffiocient
    local otherExponent = insane_int_display2.exponent

    if myStartingECount > otherStartingECount then
        otherExponent = (otherExponent / math.pow(10, (myStartingECount - otherStartingECount)))
        starting_e_count = myStartingECount
    elseif myStartingECount < otherStartingECount then
        myExponent = (myExponent / math.pow(10, (otherStartingECount - myStartingECount)))
        starting_e_count = otherStartingECount
    else
        starting_e_count = myStartingECount
    end

    if myExponent > otherExponent then
        coeffiocient = (otherCoefficient / math.pow(10, (myExponent - otherExponent))) + myCoefficient
        exponent = myExponent
    elseif myExponent < otherExponent then
        coeffiocient = (myCoefficient / math.pow(10, (otherExponent - myExponent))) + otherCoefficient
        exponent = otherExponent
    else
        coeffiocient = myCoefficient + otherCoefficient
        exponent = myExponent
    end

    return MP.INSANE_INT.create(coeffiocient, exponent, starting_e_count)
end