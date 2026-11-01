local M = {}

function M.apply()
	hl.config({
		layout = {
			single_window_aspect_ratio = "4 3",
			single_window_aspect_ratio_tolerance = 0.1,
		},
		dwindle = {
			preserve_split = true,
			smart_split = false,
			split_width_multiplier = 1.35,
		},
		master = {
			mfact = 0.75,
			new_on_top = true,
			new_status = "master",
			orientation = "left",
		},
		scrolling = {
			column_width = 0.4,
			direction = "right",
			focus_fit_method = 1,
			follow_focus = true,
			follow_min_visible = 0.4,
			fullscreen_on_one_column = true,
		},
	})

	-- Inset special workspaces; replaces dwindle's deprecated special_scale_factor.
	hl.workspace_rule({ workspace = "s[true]", gaps_out = 80 })
end

return M
