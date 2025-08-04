-- Utility functions for UI components

function MP.UI.create_spacer(size, row)
	size = size or 0.2

	return row and {
		n = G.UIT.R,
		config = {
			align = "cm",
			minh = size,
		},
		nodes = {},
	} or {
		n = row and G.UIT.R or G.UIT.C,
		config = {
			align = "cm",
			minw = size,
		},
		nodes = {},
	}
end