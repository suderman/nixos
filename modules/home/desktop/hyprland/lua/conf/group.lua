local stylix = require("generated.stylix")
local M = {}

function M.apply(_, _)
	hl.config({
		group = {
			merge_groups_on_drag = true,
			col = {
				border_active = stylix.base0D.rgb,
				border_inactive = stylix.base03.rgb,
				border_locked_active = stylix.base0C.rgb,
			},
			groupbar = {
				enabled = true,
				font_family = "sanserif",
				font_size = 14,
				gaps_in = 10,
				gaps_out = 5,
				gradient_round_only_edges = false,
				gradient_rounding = 20,
				gradient_rounding_power = 4.0,
				gradients = true,
				height = 20,
				indicator_gap = 0,
				indicator_height = 0,
				keep_upper_gap = false,
				render_titles = true,
				round_only_edges = false,
				rounding = 15,
				rounding_power = 4.0,

				text_color = stylix.base00.rgba(0.8),
				text_color_inactive = stylix.base00.rgba(0.8),
				text_color_locked_active = stylix.base05.rgba(0.8),
				text_color_locked_inactive = stylix.base05.rgba(0.8),

				col = {
					active = stylix.base05.rgba(0.8),
					inactive = stylix.base05.rgba(0.8),
					locked_active = stylix.base00.rgba(0.8),
					locked_inactive = stylix.base00.rgba(0.6),
				},
			},
		},
	})
end

return M
