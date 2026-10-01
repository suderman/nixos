local root, assets = assert(arg[1]), assert(arg[2])
package.path = root .. "/?.lua;" .. package.path
package.loaded["generated.appearance"] = { enabled = true, assets = assets, default_mode = "dark" }
package.loaded["generated.stylix"] = {}
local selected, configurations
local open = io.open
io.open = function(path, ...)
	if path:match("/desktop%-theme/mode$") then
		return {
			read = function()
				return selected
			end,
			close = function() end,
		}
	end
	return open(path, ...)
end
hl = {
	plugin = {},
	config = function(config)
		configurations[#configurations + 1] = config
	end,
}
local appearance = require("lib.appearance")
for _, mode in ipairs({ "dark", "light", "dark" }) do
	selected, configurations = mode, {}
	local palette = dofile(assets .. "/" .. mode .. "/palette.lua")
	appearance.apply()
	assert(#configurations == 1)
	assert(configurations[1].general.col.active_border == "rgb(" .. palette.base0D .. ")")
	hl.plugin.hyprbars, configurations = {}, {}
	appearance.apply()
	assert(#configurations == 2)
	assert(configurations[2].plugin.hyprbars["col.text"] == "rgb(" .. palette.base05 .. ")")
	hl.plugin.hyprbars = nil
end
selected = "invalid"
assert(not pcall(appearance.apply))
io.open = open
print("appearance colors, plugin ownership and invalid state: passed")
