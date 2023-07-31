return {

  font = wezterm.font("JetBrains Mono"),
  enable_wayland = true,
  warn_about_missing_glyphs = false,

  initial_rows = 36,
  initial_cols = 160,

  window_decorations = "RESIZE",
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = false,
  tab_max_width = 64,

  -- xcursor_theme = "Adwaita",
  hide_mouse_cursor_when_typing = false,

  window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.1cell",
    bottom = "0.1cell",
  },

  keys = {

    {key="Insert", mods="CTRL", action=wezterm.action{CopyTo="ClipboardAndPrimarySelection"}},
    {key="Insert", mods="SHIFT", action=wezterm.action{PasteFrom="Clipboard"}},
    {key="[", mods="SUPER", action=wezterm.action{ActivateTabRelative=-1}},
    {key="]", mods="SUPER", action=wezterm.action{ActivateTabRelative=1}},

    -- Turn off the default CMD-m Hide action
    {key="m", mods="SUPER", action="DisableDefaultAssignment"}

  },

  -- https://github.com/wez/wezterm/issues/3765#issuecomment-1634985882
  front_end = "WebGpu",

  launch_menu = {
    {
      args = {"btop"},
    },
    {
      label = "Bash",
      args = {"bash", "-l"},
    },
  }

}
