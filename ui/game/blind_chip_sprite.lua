PVP.UI.BlindChip = {}

function PVP.UI.BlindChip.custom(atlas, x, y)
	local blind_chip = AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS[atlas], { x = x, y = y })
	blind_chip:define_draw_steps({
		{ shader = "dissolve", shadow_height = 0.05 },
		{ shader = "dissolve" },
	})
	return blind_chip
end

function PVP.UI.BlindChip.small()
	return PVP.UI.BlindChip.custom("blind_chips", 0, 0)
end

function PVP.UI.BlindChip.big()
	return PVP.UI.BlindChip.custom("blind_chips", 0, 1)
end

function PVP.UI.BlindChip.random()
	return PVP.UI.BlindChip.custom("blind_chips", 0, 30)
end
