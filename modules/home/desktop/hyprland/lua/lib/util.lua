local M = {}

function M.exec(keys, command, opts)
	-- Shell out for app launchers and small helper scripts.
	return hl.bind(keys, hl.dsp.exec_cmd(command), opts)
end

function M.dispatch(keys, command, opts)
	return M.exec(keys, "hyprctl dispatch '" .. command .. "'", opts)
end

function M.workspace_bind(key, workspace)
	-- Shared numeric workspace convention used across all hosts.
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(workspace) }))
	hl.bind("SUPER + ALT + " .. key, hl.dsp.window.move({ workspace = tostring(workspace) }))
end

function M.curve(name, p1, p2)
	hl.curve(name, { type = "bezier", points = { p1, p2 } })
end

function M.timer_dispatch(timeout_ms, dispatch)
	return function()
		hl.timer(function()
			hl.dispatch(dispatch)
		end, { timeout = timeout_ms, type = "oneshot" })
	end
end

return M
