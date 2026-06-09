local M = {}

function M.apply(keyd_bin, window_rules, layer_rules)
	local active_window = { class = "", title = "" }
	local active_layers = {}
	local last_command = nil

	local function normalize(value, pattern)
		return (value or ""):gsub(pattern, "-"):gsub("^%-+", ""):gsub("%-+$", ""):lower()
	end

	local function normalize_class(value)
		return normalize(value, "[^A-Za-z0-9]+")
	end

	local function normalize_title(value)
		return normalize(value, "[^%w]+")
	end

	local function normalize_glob(value, normalizer)
		local parts = {}
		local start = 1

		while true do
			local first, last = value:find("%*", start)
			if not first then
				parts[#parts + 1] = normalizer(value:sub(start))
				break
			end

			parts[#parts + 1] = normalizer(value:sub(start, first - 1))
			parts[#parts + 1] = "*"
			start = last + 1
		end

		return table.concat(parts)
	end

	local function glob_to_pattern(value)
		return "^" .. value:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"):gsub("%*", ".*") .. "$"
	end

	local function matches(value, pattern)
		return value:match(glob_to_pattern(pattern)) ~= nil
	end

	local function split_window_rule(section)
		local class_rule, title_rule = section:match("^(.-)|(.+)$")
		if class_rule then
			return class_rule, title_rule
		end

		return section, nil
	end

	local function merge_into(dst, src)
		for from, to in pairs(src) do
			dst[from] = to
		end
	end

	local function select_window_bindings(class, title)
		local merged = {}

		for _, entry in ipairs(window_rules or {}) do
			local class_rule, title_rule = split_window_rule(entry.section)
			local normalized_class_rule = normalize_glob(class_rule, normalize_class)

			if matches(class, normalized_class_rule) then
				if title_rule == nil then
					merge_into(merged, entry.bindings)
				else
					local normalized_title_rule = normalize_glob(title_rule, normalize_title)
					if matches(title, normalized_title_rule) then
						merge_into(merged, entry.bindings)
					end
				end
			end
		end

		return merged
	end

	local function select_layer_rules()
		local merged = {}

		for _, entry in ipairs(layer_rules or {}) do
			local normalized_section = normalize_glob(entry.section, normalize_class)

			for namespace in pairs(active_layers) do
				if matches(namespace, normalized_section) then
					merge_into(merged, entry.bindings)
					break
				end
			end
		end

		return merged
	end

	local function merge_bindings(window_bindings, layer_bindings)
		local merged = {}

		for from, to in pairs(window_bindings) do
			merged[from] = to
		end

		for from, to in pairs(layer_bindings) do
			merged[from] = to
		end

		return merged
	end

	local function shell_quote(value)
		return "'" .. tostring(value):gsub("'", "'\"'\"'") .. "'"
	end

	local function bindings_to_command(bindings)
		local keys = {}

		for key in pairs(bindings) do
			keys[#keys + 1] = key
		end

		table.sort(keys)

		local parts = {}

		for _, key in ipairs(keys) do
			parts[#parts + 1] = shell_quote(key .. "=" .. bindings[key])
		end

		if #parts == 0 then
			return keyd_bin .. " bind reset"
		end

		return keyd_bin .. " bind reset " .. table.concat(parts, " ")
	end

	local function reapply()
		local bindings =
			merge_bindings(select_window_bindings(active_window.class, active_window.title), select_layer_rules())
		local command = bindings_to_command(bindings)

		if command == last_command then
			return
		end

		last_command = command
		hl.exec_cmd(command)
	end

	local function set_active_window(window)
		local next_window = {
			class = normalize_class(window and window.class or ""),
			title = normalize_title(window and window.title or ""),
		}

		if next_window.class == active_window.class and next_window.title == active_window.title then
			return
		end

		active_window = next_window
		reapply()
	end

	local function add_layer(namespace)
		-- Hyprland 0.55+ passes a LayerSurface object here, not the legacy
		-- raw namespace string from the old IPC event stream.
		local layer = normalize_class(namespace and namespace.namespace or "")
		if active_layers[layer] then
			return
		end

		active_layers[layer] = true
		reapply()
	end

	local function remove_layer(namespace)
		-- Keep the same extraction path for close events so open/close track the
		-- same normalized namespace key in active_layers.
		local layer = normalize_class(namespace and namespace.namespace or "")
		if not active_layers[layer] then
			return
		end

		active_layers[layer] = nil
		reapply()
	end

	hl.on("hyprland.start", function()
		set_active_window(hl.get_active_window())
		reapply()
	end)

	hl.on("window.active", function(window)
		set_active_window(window)
	end)

	-- Lua mode uses layer.opened / layer.closed and passes LayerSurface.
	hl.on("layer.opened", function(namespace)
		add_layer(namespace)
	end)

	hl.on("layer.closed", function(namespace)
		remove_layer(namespace)
	end)
end

return M
