MP.UI.BlindChip = {}

function MP.UI.BlindChip.custom(atlas, x, y)
	local blind_chip = AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS[atlas], { x = x, y = y })
	blind_chip:define_draw_steps({
		{ shader = "dissolve", shadow_height = 0.05 },
		{ shader = "dissolve" },
	})
	return blind_chip
end

function MP.UI.BlindChip.small()
	return MP.UI.BlindChip.custom("blind_chips", 0, 0)
end

function MP.UI.BlindChip.big()
	return MP.UI.BlindChip.custom("blind_chips", 0, 1)
end

function MP.UI.BlindChip.random()
	return MP.UI.BlindChip.custom("blind_chips", 0, 30)
end

function MP.UI.BlindChip.nemesis()
	return MP.UI.BlindChip.custom("mp_player_blind_col", 0, 22)
end
