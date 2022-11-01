local wezterm = require 'wezterm';
return {

  font = wezterm.font("JetBrains Mono"),
  -- font = wezterm.font("Noto Color Emoji"),
  -- font = wezterm.font("PowerlineExtraSymbols"), =>
  -- color_scheme = "Batman",

  enable_wayland = true,
  warn_about_missing_glyphs = false,


  -- initial_rows = 24,
  initial_rows = 36,
  -- initial_cols = 80,
  initial_cols = 160,

  window_decorations = "RESIZE",
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  tab_bar_at_bottom = false,
  -- tab_max_width = 32,
  tab_max_width = 64,

  -- colors = {
  --   tab_bar = {
  --     -- The color of the strip that goes along the top of the window
  --     -- (does not apply when fancy tab bar is in use)
  --     background = "#0b0022",
  --
  --     -- The active tab is the one that has focus in the window
  --     active_tab = {
  --       -- The color of the background area for the tab
  --       bg_color = "#2b2042",
  --       -- The color of the text for the tab
  --       fg_color = "#c0c0c0",
  --
  --       -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
  --       -- label shown for this tab.
  --       -- The default is "Normal"
  --       intensity = "Normal",
  --
  --       -- Specify whether you want "None", "Single" or "Double" underline for
  --       -- label shown for this tab.
  --       -- The default is "None"
  --       underline = "None",
  --
  --       -- Specify whether you want the text to be italic (true) or not (false)
  --       -- for this tab.  The default is false.
  --       italic = false,
  --
  --       -- Specify whether you want the text to be rendered with strikethrough (true)
  --       -- or not for this tab.  The default is false.
  --       strikethrough = false,
  --     },
  --
  --     -- Inactive tabs are the tabs that do not have focus
  --     inactive_tab = {
  --       bg_color = "#1b1032",
  --       fg_color = "#808080",
  --
  --       -- The same options that were listed under the `active_tab` section above
  --       -- can also be used for `inactive_tab`.
  --     },
  --
  --     -- You can configure some alternate styling when the mouse pointer
  --     -- moves over inactive tabs
  --     inactive_tab_hover = {
  --       bg_color = "#3b3052",
  --       fg_color = "#909090",
  --       italic = true,
  --
  --       -- The same options that were listed under the `active_tab` section above
  --       -- can also be used for `inactive_tab_hover`.
  --     },
  --
  --     -- The new tab button that let you create new tabs
  --     new_tab = {
  --       bg_color = "#1b1032",
  --       fg_color = "#808080",
  --
  --       -- The same options that were listed under the `active_tab` section above
  --       -- can also be used for `new_tab`.
  --     },
  --
  --     -- You can configure some alternate styling when the mouse pointer
  --     -- moves over the new tab button
  --     new_tab_hover = {
  --       bg_color = "#3b3052",
  --       fg_color = "#909090",
  --       italic = true,
  --
  --       -- The same options that were listed under the `active_tab` section above
  --       -- can also be used for `new_tab_hover`.
  --     }
  --   }
  -- },

  window_padding = {
    left = "0.5cell",
    right = "0.5cell",
    top = "0.1cell",
    bottom = "0.1cell",
  },

  -- window_padding = {
  --   left = "0",
  --   right = "0",
  --   top = "0",
  --   bottom = "0",
  -- },

  -- window_background_gradient = {
  --   -- Can be "Vertical" or "Horizontal".  Specifies the direction
  --   -- in which the color gradient varies.  The default is "Horizontal",
  --   -- with the gradient going from left-to-right.
  --   -- Radial gradients are also supported; see the other example below
  --   orientation = "Vertical",
  --
  --   -- Specifies the set of colors that are interpolated in the gradient.
  --   -- Accepts CSS style color specs, from named colors, through rgb
  --   -- strings and more
  --   colors = {
  --     "#0f0c29",
  --     "#302b63",
  --     "#24243e"
  --   },
  --
  --   -- Instead of specifying `colors`, you can use one of a number of
  --   -- predefined, preset gradients.
  --   -- A list of presets is shown in a section below.
  --   -- preset = "Warm",
  --
  --   -- Specifies the interpolation style to be used.
  --   -- "Linear", "Basis" and "CatmullRom" as supported.
  --   -- The default is "Linear".
  --   interpolation = "Linear",
  --
  --   -- How the colors are blended in the gradient.
  --   -- "Rgb", "LinearRgb", "Hsv" and "Oklab" are supported.
  --   -- The default is "Rgb".
  --   blend = "Rgb",
  --
  --   -- To avoid vertical color banding for horizontal gradients, the
  --   -- gradient position is randomly shifted by up to the `noise` value
  --   -- for each pixel.
  --   -- Smaller values, or 0, will make bands more prominent.
  --   -- The default value is 64 which gives decent looking results
  --   -- on a retina macbook pro display.
  --   -- noise = 64,
  --
  --   -- By default, the gradient smoothly transitions between the colors.
  --   -- You can adjust the sharpness by specifying the segment_size and
  --   -- segment_smoothness parameters.
  --   -- segment_size configures how many segments are present.
  --   -- segment_smoothness is how hard the edge is; 0.0 is a hard edge,
  --   -- 1.0 is a soft edge.
  --
  --   -- segment_size = 11,
  --   -- segment_smoothness = 0.0,
  -- },

  -- window_background_opacity = 0.5,


  keys = {

    -- {key="c", mods="SUPER", action=wezterm.action{CopyTo="Clipboard"}},
    -- {key="v", mods="SUPER", action=wezterm.action{PasteFrom="Clipboard"}},
    -- {key="]", mods="SUPER", action='ActivateTabRelative=1"'},
    -- {key="[", mods="SUPER", action='ActivateTabRelative=-1"'},

    {key="Insert", mods="CTRL", action=wezterm.action{CopyTo="ClipboardAndPrimarySelection"}},
    {key="Insert", mods="SHIFT", action=wezterm.action{PasteFrom="Clipboard"}},

    -- {key="c", mods="ALT", action=wezterm.action{CopyTo="Clipboard"}},
    -- {key="v", mods="ALT", action=wezterm.action{PasteFrom="Clipboard"}},

    -- {key="c", mods="SUPER", action=wezterm.action{CopyTo="Clipboard"}},
    -- {key="v", mods="SUPER", action=wezterm.action{PasteFrom="Clipboard"}},

    {key="[", mods="SUPER", action=wezterm.action{ActivateTabRelative=-1}},
    {key="]", mods="SUPER", action=wezterm.action{ActivateTabRelative=1}},
    
    -- {key="arrowup", mods="SUPER", action=wezterm.action{ActivateTabRelative=-1}},
    -- {key="arrowdown", mods="SUPER", action=wezterm.action{ActivateTabRelative=1}},

    -- Turn off the default CMD-m Hide action
    {key="m", mods="SUPER", action="DisableDefaultAssignment"}

  },

  launch_menu = {
    {
      args = {"btop"},
    },
    {
      -- Optional label to show in the launcher. If omitted, a label
      -- is derived from the `args`
      label = "Bash",
      -- The argument array to spawn.  If omitted the default program
      -- will be used as described in the documentation above
      args = {"bash", "-l"},

      -- You can specify an alternative current working directory;
      -- if you don't specify one then a default based on the OSC 7
      -- escape sequence will be used (see the Shell Integration
      -- docs), falling back to the home directory.
      -- cwd = "/some/path"

      -- You can override environment variables just for this command
      -- by setting this here.  It has the same semantics as the main
      -- set_environment_variables configuration option described above
      -- set_environment_variables = { FOO = "bar" },
    },
  }
}
