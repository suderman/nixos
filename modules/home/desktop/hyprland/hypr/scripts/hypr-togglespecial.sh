#!/usr/bin/env bash
hyprctl eval '
  local window = hl.get_active_window()
  if window and window.workspace then
    hl.dispatch(hl.dsp.window.move({ workspace = window.workspace.special and "e+0" or "special" }))
  end
'
