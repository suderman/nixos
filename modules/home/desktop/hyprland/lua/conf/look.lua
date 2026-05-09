local util = require("lib.util")

local M = {}

function M.apply(_, _)
    hl.config({
        general = {
            snap = {
                enabled = true,
                window_gap = 10,
                monitor_gap = 10,
                border_overlap = true,
            },
            border_size = 0,
            col = {
                active_border = "rgb(89b4fa)",
                inactive_border = "rgb(45475a)",
            },
            extend_border_grab_area = 15,
            gaps_in = { top = 10, right = 10, bottom = 5, left = 10 },
            gaps_out = { top = 10, right = 20, bottom = 20, left = 20 },
            gaps_workspaces = 20,
            layout = "dwindle",
            resize_on_border = true,
        },
        decoration = {
            rounding = 10,
            shadow = {
                enabled = true,
                range = 20,
                render_power = 3,
                offset = "0 3",
                color = "rgba(1e1e2e99)",
            },
            dim_inactive = false,
            dim_strength = 0.1,
            dim_special = 0.5,
            blur = {
                enabled = true,
                size = 4,
                passes = 3,
                ignore_opacity = true,
                special = true,
                xray = true,
            },
        },
        misc = {
            animate_manual_resizes = true,
            animate_mouse_windowdragging = false,
            background_color = "rgb(1e1e2e)",
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            enable_swallow = false,
            focus_on_activate = false,
            key_press_enables_dpms = true,
            mouse_move_enables_dpms = true,
            on_focus_under_fullscreen = 2,
            swallow_exception_regex = "wev|^(*.Yazi.*)$|^(*.mpv.*)$|^(*.imv.*)$|^(*.nvim.*)$",
            swallow_regex = "^(Alacritty|kitty|footclient)$",
        },
        binds = {
            workspace_back_and_forth = false,
        },
    })

    hl.config({
        animations = {
            enabled = true,
        },
    })

    util.curve("overshot", { 0.05, 0.9 }, { 0.1, 1.05 })
    util.curve("smoothOut", { 0.36, 0.0 }, { 0.66, -0.56 })
    util.curve("smoothIn", { 0.25, 1.0 }, { 0.5, 1.0 })
    util.curve("win", { 0.05, 0.9 }, { 0.1, 1.05 })
    util.curve("winIn", { 0.1, 1.1 }, { 0.1, 1.1 })
    util.curve("winOut", { 0.3, -0.3 }, { 0.0, 1.0 })
    util.curve("liner", { 1.0, 1.0 }, { 1.0, 1.0 })
    util.curve("md3_standard", { 0.2, 0.0 }, { 0.0, 1.0 })
    util.curve("md3_decel", { 0.05, 0.7 }, { 0.1, 1.0 })
    util.curve("md3_accel", { 0.3, 0.0 }, { 0.8, 0.15 })
    util.curve("hyprnostretch", { 0.05, 0.9 }, { 0.1, 1.0 })
    util.curve("win10", { 0.0, 0.0 }, { 0.0, 1.0 })
    util.curve("gnome", { 0.0, 0.85 }, { 0.3, 1.0 })
    util.curve("funky", { 0.46, 0.35 }, { -0.2, 1.2 })

    hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "overshot", style = "slide" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "default" })
    hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "default" })
    hl.animation({ leaf = "borderangle", enabled = true, speed = 20, bezier = "liner", style = "once" })
    hl.animation({ leaf = "fade", enabled = true, speed = 1, bezier = "smoothIn" })
    hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "smoothIn" })
    hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slidevert" })
    hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "overshot", style = "slidefadevert -50%" })
    hl.animation({ leaf = "layers", enabled = true, speed = 0.1, bezier = "default", style = "fade" })
end

return M
