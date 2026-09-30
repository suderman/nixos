-- Run with lua test.lua /path/to/lua. No compositor needed for these checks.
local root = assert(arg[1], "Lua module directory required")
package.path = root .. "/?.lua;" .. package.path

local workspace, special_workspace
local rules = {}
hl = {
	get_active_special_workspace = function()
		return special_workspace
	end,
	get_active_workspace = function()
		return workspace
	end,
	workspace_rule = function(rule)
		rules[#rules + 1] = rule
		workspace.tiled_layout = rule.layout
	end,
	exec_cmd = function() end,
}
local util = require("lib.util")
for _, selector in ipairs({ "1", "name:notes", "special:notes" }) do
	for _, field in ipairs({ "config_name", "addressable_name" }) do
		workspace = { [field] = selector, tiled_layout = "dwindle" }
		for _, layout in ipairs({ "master", "scrolling", "monocle", "dwindle" }) do
			util.cycle_layout("next")
			assert(rules[#rules].workspace == selector)
			assert(workspace.tiled_layout == layout)
		end
		util.cycle_layout("prev")
		assert(workspace.tiled_layout == "monocle")
		-- External changes must override any previous cycling state.
		workspace.tiled_layout = "master"
		util.cycle_layout("next")
		assert(workspace.tiled_layout == "scrolling")
	end
end
special_workspace = { addressable_name = "special:visible", tiled_layout = "dwindle" }
workspace = { addressable_name = "1", tiled_layout = "master" }
hl.workspace_rule = function(rule)
	rules[#rules + 1] = rule
end
util.cycle_layout("next")
assert(rules[#rules].workspace == "special:visible" and rules[#rules].layout == "master")
workspace, special_workspace = nil, nil
util.cycle_layout("next")
print("layout selectors and external changes: passed")

local active_window
local moved, focused, fullscreen
local floats = { { floating = true }, { floating = true } }
local tiled = { floating = false }
local hidden
hl.get_active_window = function()
	return active_window
end
hl.get_workspace = function()
	return hidden
end
hl.dsp = {
	window = {
		move = function(spec)
			return { move = spec }
		end,
		fullscreen = function(spec)
			return { fullscreen = spec }
		end,
	},
	focus = function(spec)
		return { focus = spec }
	end,
}
hl.dispatch = function(dispatch)
	if dispatch.move then
		moved[#moved + 1] = dispatch.move
	elseif dispatch.focus then
		focused = dispatch.focus.window
	else
		fullscreen = dispatch.fullscreen
	end
end
for _, selector in ipairs({ "1", "notes", "special:notes" }) do
	workspace = {
		addressable_name = selector,
		get_windows = function()
			return { tiled, floats[1], floats[2] }
		end,
	}
	active_window = tiled
	tiled.fullscreen = 0
	hidden, focused, moved = nil, nil, {}
	util.toggle_fullscreen_or_hidden()
	assert(#moved == 2 and moved[1].workspace == "special:hidden" .. selector)
	assert(moved[1].window == floats[1] and not moved[1].follow)
	assert(focused == tiled, "hiding floats must preserve tiled focus")
	hidden = {
		get_windows = function()
			return floats
		end,
	}
	moved = {}
	util.toggle_fullscreen_or_hidden()
	assert(#moved == 2 and moved[1].workspace == selector)
	for mode = 1, 2 do
		tiled.fullscreen, moved = mode, {}
		util.toggle_fullscreen_or_hidden()
		assert(#moved == 0 and fullscreen.action == "toggle")
		assert(fullscreen.mode == (mode == 1 and "maximized" or "fullscreen"))
	end
end
workspace, active_window, hidden, moved = nil, nil, nil, {}
util.toggle_fullscreen_or_hidden()
assert(#moved == 0)
print("floating scratch spaces, focus and fullscreen: passed")

local listeners, commands = {}, {}
local active_window = { class = "Kitty", title = "Editor" }
local layers = {}
hl = {
	on = function(event, callback)
		listeners[event] = callback
	end,
	get_active_window = function()
		return active_window
	end,
	get_layers = function()
		return layers
	end,
	exec_cmd = function(command)
		commands[#commands + 1] = command
	end,
}
local function apply_keyd()
	listeners = {}
	require("lib.keyd").apply("keyd", {
		{ section = "*", bindings = { ["super.a"] = "C-a" } },
		{ section = "kitty|editor*", bindings = { ["super.a"] = "C-e" } },
	}, {
		{ section = "launcher", bindings = { ["super.a"] = "esc" } },
	})
end
apply_keyd()
listeners["hyprland.start"]()
assert(commands[#commands] == "keyd bind reset 'super.a=C-e'")
local count = #commands
listeners["window.active"](active_window)
assert(#commands == count, "unchanged focus must not spawn keyd")

active_window.title = "Shell"
assert(listeners["window.title"], "title rules need a title listener")
listeners["window.title"](active_window)
assert(commands[#commands] == "keyd bind reset 'super.a=C-a'")
local first = { address = "0x1", namespace = "launcher", mapped = true }
local second = { address = "0x2", namespace = "launcher", mapped = true }
listeners["layer.opened"](first)
listeners["layer.opened"](second)
assert(commands[#commands] == "keyd bind reset 'super.a=esc'")
listeners["layer.closed"](first)
assert(commands[#commands] == "keyd bind reset 'super.a=esc'", "second layer is still open")
listeners["layer.closed"](second)
assert(commands[#commands] == "keyd bind reset 'super.a=C-a'")

layers = { second, { address = "0x3", namespace = "launcher", mapped = false } }
apply_keyd()
assert(listeners["config.reloaded"], "reload must restore existing focus and layers")
listeners["config.reloaded"]()
assert(commands[#commands] == "keyd bind reset 'super.a=esc'")
listeners["layer.closed"](second)
assert(commands[#commands] == "keyd bind reset 'super.a=C-a'", "unmapped layers must be ignored")
print("keyd focus, titles, duplicate layers and reload: passed")
