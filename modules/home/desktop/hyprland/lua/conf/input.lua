local M = {}

function M.apply(_, _)
	local function move_scrolling_column(command)
		local ws = hl.get_active_workspace()
		local layout = ws and (ws.tiled_layout or ws.layout)

		if layout == "scrolling" and hl.get_active_window() then
			hl.dispatch(hl.dsp.layout(command))
		end
	end

	hl.config({
		input = {
			kb_layout = "us",
			follow_mouse = 1,
			natural_scroll = true,
			scroll_factor = 1.5,
			scroll_method = "2fg",
			sensitivity = 0,
			touchpad = {
				clickfinger_behavior = true,
				disable_while_typing = true,
				natural_scroll = true,
				scroll_factor = 0.7,
			},
		},
	})

	hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
	hl.gesture({
		fingers = 3,
		direction = "left",
		action = function()
			move_scrolling_column("move +col")
		end,
	})
	hl.gesture({
		fingers = 3,
		direction = "right",
		action = function()
			move_scrolling_column("move -col")
		end,
	})
end

return M
