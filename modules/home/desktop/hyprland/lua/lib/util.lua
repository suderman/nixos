local M = {}

function M.bind(keys, description, action, opts)
	opts = opts or {}
	opts.description = opts.description or description
	return hl.bind(keys, action, opts)
end

function M.exec(keys, command, opts)
	-- Native descriptions make the live shortcut list useful without parsing Lua.
	return M.bind(keys, command, hl.dsp.exec_cmd(command), opts)
end

function M.workspace_bind(key, workspace)
	M.bind("SUPER + " .. key, "Focus workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
	M.bind(
		"SUPER + ALT + " .. key,
		"Move to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace) })
	)
end

function M.curve(name, p1, p2)
	hl.curve(name, { type = "bezier", points = { p1, p2 } })
end

function M.active_workspace()
	return hl.get_active_special_workspace() or hl.get_active_workspace()
end

function M.cycle_layout(direction)
	local ws = M.active_workspace()
	if not ws then
		return
	end

	local layouts = { "dwindle", "master", "scrolling", "monocle" }
	local index = 1
	for i, layout in ipairs(layouts) do
		if layout == ws.tiled_layout then
			index = i
			break
		end
	end
	index = ((index - 1 + (direction == "prev" and -1 or 1)) % #layouts) + 1

	M.set_layout(layouts[index])
end

function M.set_layout(layout)
	local ws = M.active_workspace()
	if not ws then
		return
	end
	-- Main replaced config_name with addressable_name. IDs are nil for named
	-- workspaces there, so use the compositor's selector on both versions.
	hl.workspace_rule({ workspace = ws.addressable_name or ws.config_name, layout = layout })
end

function M.toggle_fullscreen_or_hidden()
	local window = hl.get_active_window()
	if window and window.fullscreen ~= 0 then
		hl.dispatch(hl.dsp.window.fullscreen({
			mode = window.fullscreen == 1 and "maximized" or "fullscreen",
			action = "toggle",
		}))
		return
	end

	local ws = M.active_workspace()
	if not ws then
		return
	end
	local selector = ws.addressable_name or ws.config_name
	local hidden_selector = "special:hidden" .. selector
	local hidden = hl.get_workspace(hidden_selector)
	local floats = {}
	if hidden then
		for _, candidate in ipairs(hidden:get_windows()) do
			if candidate.floating then
				floats[#floats + 1] = candidate
			end
		end
	end
	local target = selector
	if #floats == 0 then
		for _, candidate in ipairs(ws:get_windows()) do
			if candidate.floating then
				floats[#floats + 1] = candidate
			end
		end
		target = hidden_selector
	end
	for _, candidate in ipairs(floats) do
		hl.dispatch(hl.dsp.window.move({ workspace = target, window = candidate, follow = false }))
	end
	if window and not window.floating then
		hl.dispatch(hl.dsp.focus({ window = window }))
	end
end

return M
