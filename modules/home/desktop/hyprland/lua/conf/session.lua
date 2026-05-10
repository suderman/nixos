local M = {}

function M.apply(host, features)
	hl.monitor({
		output = "",
		mode = "preferred",
		position = "0x0",
		scale = "1",
	})

	for _, monitor in ipairs(host.monitors or {}) do
		hl.monitor(monitor)
	end

	hl.config({
		xwayland = {
			force_zero_scaling = true,
		},
	})

	for key, value in pairs(host.env or {}) do
		hl.env(key, value)
	end

	hl.on("hyprland.start", function()
		for _, command in ipairs(features.exec_once or {}) do
			hl.dispatch(hl.dsp.exec_cmd(command))
		end

		for _, command in ipairs(features.exec or {}) do
			hl.dispatch(hl.dsp.exec_cmd(command))
		end

		for _, command in ipairs(host.exec_once or {}) do
			hl.dispatch(hl.dsp.exec_cmd(command))
		end
	end)
end

return M
