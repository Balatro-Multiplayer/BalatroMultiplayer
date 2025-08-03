function MP.UI.BackgroundGrouping(text, nodes, text_scale)
	text_scale = text_scale or 0.33
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.UI.TRANSPARENT_DARK },
		nodes = {
			{ n = G.UIT.R, config = { align = "cm" }, nodes = nodes },
			{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = { { n = G.UIT.T, config = { text = text, colour = lighten(G.C.L_BLACK, 0.5), scale = text_scale } } } }
		}
	}
end
