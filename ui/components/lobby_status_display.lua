-- Component for displaying lobby status/warning messages
function MP.UI.create_lobby_status_display(text, colour)
	if not text or text == " " then
		return nil
	end

	return {
		n = G.UIT.R,
		config = {
			padding = 1.25,
			align = "cm",
		},
		nodes = {
			{
				n = G.UIT.T,
				config = {
					scale = 0.3,
					shadow = true,
					text = text,
					colour = colour,
				},
			},
		},
	}
end
