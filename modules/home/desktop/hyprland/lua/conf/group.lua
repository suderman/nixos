local M = {}

function M.apply(_, _)
	hl.config({
		group = {
			merge_groups_on_drag = true,
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
			},
		},
	})
end

return M
