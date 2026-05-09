#!/usr/bin/env bash
# Toggle hyprbars in Lua mode by mutating the plugin config directly.
hyprctl eval '
local enabled = hl.get_config("plugin:hyprbars:enabled")
if enabled == nil then
  return
end

hl.config({
  plugin = {
    hyprbars = {
      enabled = not enabled,
    },
  },
})
'
