local util = require("lib.util")

local M = {}

function M.apply()
	local move = {
		h = { dir = "l", x = -40, y = 0 },
		j = { dir = "d", x = 0, y = 40 },
		k = { dir = "u", x = 0, y = -40 },
		l = { dir = "r", x = 40, y = 0 },
	}
	local function active_layout()
		local ws = util.active_workspace()
		return ws and ws.tiled_layout
	end

	-- Workspace cycling intentionally uses open-workspace selectors (e+/-1)
	-- so the old "step through existing or empty" behavior is preserved.
	local function cycle_workspace(direction)
		hl.dispatch(hl.dsp.focus({ workspace = direction == "prev" and "e-1" or "e+1" }))
	end

	-- Respect each layout's own idea of "next" / "previous".
	local function cycle_window(direction)
		local layout = active_layout()

		if layout == "master" then
			hl.dispatch(hl.dsp.layout(direction == "prev" and "rollprev" or "rollnext"))
		elseif layout == "scrolling" then
			hl.dispatch(hl.dsp.focus({ direction = direction == "prev" and "left" or "right" }))
		elseif layout == "monocle" then
			hl.dispatch(hl.dsp.layout(direction == "prev" and "cycleprev" or "cyclenext"))
		else
			hl.dispatch(hl.dsp.window.cycle_next({ next = direction ~= "prev" }))
		end
	end

	-- Float a tiled window, but leave existing floating windows alone except
	-- for unpinning if they were pinned.
	local function float_active()
		local win = hl.get_active_window()
		if not win then
			return
		end

		if win.floating then
			if win.pinned then
				hl.dispatch(hl.dsp.window.pin())
			end
			return
		end

		hl.dispatch(hl.dsp.window.float({ action = "float" }))
		hl.dispatch(hl.dsp.window.center())
	end

	-- Tile a floating window. Tiled windows swap with master on master,
	-- elsewhere toggle or swap the split depending on the modifier.
	local function tile_active(alt_mode)
		local win = hl.get_active_window()
		if not win then
			return
		end

		if win.floating then
			hl.dispatch(hl.dsp.window.float({ action = "tile" }))
			return
		end

		local layout = active_layout()

		if layout == "master" then
			hl.dispatch(hl.dsp.layout("swapwithmaster master"))
		else
			hl.dispatch(hl.dsp.layout(alt_mode and "swapsplit" or "togglesplit"))
		end
	end

	-- Floating windows move by pixels. Tiled windows use the group-aware
	-- directional move so unlocked groups still absorb windows.
	local function move_active(spec)
		local win = hl.get_active_window()
		if win and win.floating then
			hl.dispatch(hl.dsp.window.move({ x = spec.x, y = spec.y, relative = true }))
		else
			hl.dispatch(hl.dsp.window.move({ direction = spec.dir, group_aware = true }))
		end
	end

	-- Resize only floating windows to a share of the monitor's logical size;
	-- tiled windows keep their layout size. Resize takes pixels, not percents.
	local function resize_floating(percent)
		local win = hl.get_active_window()
		if not (win and win.floating and win.monitor) then
			return
		end
		local monitor = win.monitor
		local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
		if monitor.transform % 2 == 1 then
			width, height = height, width
		end
		hl.dispatch(hl.dsp.window.resize({
			x = math.floor(width * percent / 100),
			y = math.floor(height * percent / 100),
		}))
		hl.dispatch(hl.dsp.window.center())
	end

	-- Move the active window into the special workspace, or back out of it.
	local function toggle_special_window()
		local win = hl.get_active_window()
		if win and win.workspace then
			hl.dispatch(hl.dsp.window.move({ workspace = win.workspace.special and "e+0" or "special" }))
		end
	end

	util.bind("SUPER + SHIFT + Q", "Exit compositor", hl.dsp.exit())

	util.exec("SUPER + RETURN", "kitty")
	util.exec("SUPER + Y", "thunar")
	util.exec("SUPER + ALT + Y", "nautilus --new-window")
	-- util.exec("SUPER + E", "kitty --class Neovim nvim")
	util.exec("SUPER + E", "emacsclient --create-frame")
	util.exec("SUPER + ALT + E", "neovide --neovim-bin nvim")
	util.exec("SUPER + B", "chromium-browser")
	util.exec("SUPER + SHIFT + B", "chromium-browser --incognito")
	util.exec("SUPER + ALT + B", "firefox")
	util.exec("SUPER + ALT + SHIFT + B", "firefox --private-window")
	util.exec("SUPER + ALT + SHIFT + T", "desktop-theme toggle", { description = "Toggle light/dark appearance" })
	util.exec("SUPER + CTRL + PERIOD", "1password")

	util.bind("SUPER + LEFT", "Previous workspace", function()
		cycle_workspace("prev")
	end)
	util.bind("SUPER + RIGHT", "Next workspace", function()
		cycle_workspace("next")
	end)
	util.bind("SUPER + SEMICOLON", "Previous workspace", function()
		cycle_workspace("prev")
	end)
	util.bind("SUPER + APOSTROPHE", "Next workspace", function()
		cycle_workspace("next")
	end)
	util.bind("SUPER + mouse_down", "Previous workspace", function()
		cycle_workspace("prev")
	end)
	util.bind("SUPER + mouse_up", "Next workspace", function()
		cycle_workspace("next")
	end)
	util.bind("SUPER + ALT + mouse_down", "Previous scrolling column", hl.dsp.layout("move -col"))
	util.bind("SUPER + ALT + mouse_up", "Next scrolling column", hl.dsp.layout("move +col"))

	for i = 1, 9 do
		util.workspace_bind(tostring(i), i)
	end

	util.bind("SUPER + ALT + P", "Previous workspace", function()
		cycle_workspace("prev")
	end)
	util.bind("SUPER + ALT + N", "Next workspace", function()
		cycle_workspace("next")
	end)
	util.bind("SUPER + P", "Previous window", function()
		cycle_window("prev")
	end, { repeating = true })
	util.bind("SUPER + N", "Next window", function()
		cycle_window("next")
	end, { repeating = true })
	util.bind("SUPER + SLASH", "Next layout", function()
		util.cycle_layout("next")
	end)
	util.bind("SUPER + ALT + SLASH", "Previous layout", function()
		util.cycle_layout("prev")
	end)

	util.bind("SUPER + I", "Tile or promote window", function()
		tile_active(false)
	end)
	util.bind("SUPER + ALT + I", "Swap tiled split", function()
		tile_active(true)
	end)
	util.bind("SUPER + SHIFT + I", "Next tiled window", hl.dsp.window.cycle_next({ tiled = true }))
	util.bind("SUPER + ALT + M", "Add master", hl.dsp.layout("addmaster"))
	util.bind("SUPER + ALT + SHIFT + M", "Remove master", hl.dsp.layout("removemaster"))
	util.bind("SUPER + W", "Close window", hl.dsp.window.close())
	util.bind("SUPER + ALT + Q", "Force quit window", hl.dsp.window.kill())
	util.bind("SUPER + U", "Focus urgent or last window", hl.dsp.focus({ urgent_or_last = true }))
	util.bind("SUPER + BACKSLASH", "Focus last window", hl.dsp.focus({ last = true }))

	util.exec("SUPER + TAB", "hypr-supertab")
	util.exec("SUPER + ALT + TAB", "hypr-supertab next")
	util.exec("SUPER + SHIFT + TAB", "hypr-supertab prev")
	util.exec("SUPER + M", "hypr-supertab mark")
	util.exec("SUPER + M", "hypr-supertab clear", { long_press = true })

	util.bind("SUPER + ESCAPE", "Toggle special workspace", hl.dsp.workspace.toggle_special("special"))
	util.bind("SUPER + ALT + ESCAPE", "Move window to or from special workspace", toggle_special_window)

	util.bind("SUPER + Q", "Ungroup or close window", util.toggle_group_or_close)
	util.bind("SUPER + COMMA", "Previous group window", hl.dsp.group.prev())
	util.bind("SUPER + COMMA", "Lock group after selection", hl.dsp.group.lock_active({ action = "lock" }))
	util.bind("SUPER + PERIOD", "Next group window", hl.dsp.group.next())
	util.bind("SUPER + PERIOD", "Lock group after selection", hl.dsp.group.lock_active({ action = "lock" }))
	util.bind("SUPER + ALT + COMMA", "Move window backward in group", hl.dsp.group.move_window({ forward = false }))
	util.bind("SUPER + ALT + COMMA", "Lock group after selection", hl.dsp.group.lock_active({ action = "lock" }))
	util.bind("SUPER + ALT + PERIOD", "Move window forward in group", hl.dsp.group.move_window({ forward = true }))
	util.bind("SUPER + ALT + PERIOD", "Lock group after selection", hl.dsp.group.lock_active({ action = "lock" }))
	util.bind("SUPER + ALT + mouse:272", "Toggle group or group lock", function()
		util.toggle_group_or_lock()
	end)
	util.bind("SUPER + COMMA", "Next group window and toggle lock", function()
		util.toggle_group_or_lock("f")
	end, { long_press = true })
	util.bind("SUPER + PERIOD", "Previous group window and toggle lock", function()
		util.toggle_group_or_lock("b")
	end, { long_press = true })

	util.bind("SUPER + F", "Toggle maximized", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
	util.bind(
		"SUPER + ALT + F",
		"Toggle fullscreen",
		hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })
	)
	util.bind(
		"SUPER + F",
		"Toggle fullscreen",
		hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
		{ long_press = true }
	)

	util.bind("SUPER + SHIFT + O", "Next floating window", hl.dsp.window.cycle_next({ floating = true }))
	util.bind("SUPER + O", "Float or unpin window", float_active)
	util.bind("SUPER + ALT + O", "Exit fullscreen or hide floating windows", util.toggle_fullscreen_or_hidden)
	util.bind("SUPER + O", "Pin floating window", hl.dsp.window.pin(), { long_press = true })

	for i = 1, 9 do
		util.bind("SUPER + SHIFT + " .. i, "Resize floating window to " .. i .. "0%", function()
			resize_floating(i * 10)
		end)
	end

	for key, spec in pairs(move) do
		util.bind("SUPER + ALT + " .. key:upper(), "Move window or group " .. spec.dir, function()
			move_active(spec)
		end, { repeating = true })
	end

	util.bind("SUPER + ALT + SHIFT + H", "Swap column left", hl.dsp.layout("swapcol l"), { repeating = true })
	util.bind("SUPER + ALT + SHIFT + L", "Swap column right", hl.dsp.layout("swapcol r"), { repeating = true })
	util.bind(
		"SUPER + SHIFT + H",
		"Shrink window width",
		hl.dsp.window.resize({ x = -80, y = 0, relative = true }),
		{ repeating = true }
	)
	util.bind(
		"SUPER + SHIFT + J",
		"Grow window height",
		hl.dsp.window.resize({ x = 0, y = 80, relative = true }),
		{ repeating = true }
	)
	util.bind(
		"SUPER + SHIFT + K",
		"Shrink window height",
		hl.dsp.window.resize({ x = 0, y = -80, relative = true }),
		{ repeating = true }
	)
	util.bind(
		"SUPER + SHIFT + L",
		"Grow window width",
		hl.dsp.window.resize({ x = 80, y = 0, relative = true }),
		{ repeating = true }
	)
	util.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "left" }), { repeating = true })
	util.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "down" }), { repeating = true })
	util.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "up" }), { repeating = true })
	util.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "right" }), { repeating = true })

	util.bind("SUPER + RETURN", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + Y", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + E", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + B", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + ALT + RETURN", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + ALT + Y", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + ALT + E", "Float or unpin window", float_active, { long_press = true })
	util.bind("SUPER + ALT + B", "Float or unpin window", float_active, { long_press = true })

	util.bind("SUPER + mouse:272", "Drag window", hl.dsp.window.drag(), { mouse = true })
	util.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })
end

return M
