-- for some reason this is the only* thing in the mod to use an atlas instead of separate files
SMODS.Atlas({
	key = "decks",
	path = "decks.png",
	px = 71,
	py = 95,
})

SMODS.DrawStep {
	key = 'back_multiplayer',
	order = 11,
	func = function(self)
		if G.GAME.viewed_back and G.GAME.viewed_back.effect.center.mod then
			if G.GAME.viewed_back.effect.center.mod.id == "Multiplayer" then
				G.shared_stickers["mp_sticker_balanced"].role.draw_major = self
				local sticker_offset = self.sticker_offset or {}
				G.shared_stickers["mp_sticker_balanced"]:draw_shader('dissolve', nil, nil, true, self.children.center, nil, self.sticker_rotation, sticker_offset.x, sticker_offset.y)
				G.shared_stickers["mp_sticker_balanced"]:draw_shader('voucher', nil, self.ARGS.send_to_shader, true, self.children.center, nil, self.sticker_rotation, sticker_offset.x, sticker_offset.y)
			end
		end
	end,
	conditions = { vortex = false, facing = 'back' },
}