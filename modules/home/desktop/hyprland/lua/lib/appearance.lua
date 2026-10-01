local M = {}

function M.apply()
	local settings = require("generated.appearance")
	local colors = require("generated.stylix")
	if settings.enabled then
		local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/desktop-theme"
		local file = io.open(state .. "/mode", "r")
		local mode = settings.default_mode
		if file then
			mode = file:read("*l")
			file:close()
		end
		assert(mode == "dark" or mode == "light", "Invalid desktop appearance mode")
		local palette = dofile(settings.assets .. "/" .. mode .. "/palette.lua")
		colors = {}
		for name, hex in pairs(palette) do
			colors[name] = {
				rgb = "rgb(" .. hex .. ")",
				rgba = function(alpha)
					return "rgba(" .. hex .. string.format("%02x", math.floor(alpha * 255 + 0.5)) .. ")"
				end,
			}
		end
	end
	hl.config({
		general = { col = { active_border = colors.base0D.rgb, inactive_border = colors.base03.rgb } },
		decoration = { shadow = { color = colors.base00.rgba(0.6) } },
		misc = { background_color = colors.base00.rgb },
		group = {
			col = {
				border_active = colors.base0D.rgb,
				border_inactive = colors.base03.rgb,
				border_locked_active = colors.base0C.rgb,
			},
			groupbar = {
				text_color = colors.base00.rgba(0.8),
				text_color_inactive = colors.base05.rgba(0.8),
				text_color_locked_active = colors.base00.rgba(0.8),
				text_color_locked_inactive = colors.base05.rgba(0.8),
				col = {
					active = colors.base0D.rgba(0.9),
					inactive = colors.base02.rgba(0.8),
					locked_active = colors.base0C.rgba(0.9),
					locked_inactive = colors.base02.rgba(0.8),
				},
			},
		},
	})
	if hl.plugin.hyprbars then
		hl.config({
			plugin = { hyprbars = {
				bar_color = colors.base00.rgba(0.9),
				["col.text"] = colors.base05.rgb,
			} },
		})
	end
end

return M
