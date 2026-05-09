local util = require("lib.util")

local M = {}

function M.apply(_, _)
    local move = {
        h = { dir = "l", x = -40, y = 0 },
        j = { dir = "d", x = 0, y = 40 },
        k = { dir = "u", x = 0, y = -40 },
        l = { dir = "r", x = 40, y = 0 },
    }

    util.exec("SUPER + SHIFT + Q", "hyprctl dispatch exit")

    util.exec("SUPER + RETURN", "kitty")
    util.exec("SUPER + Y", "kitty --class Yazi yazi")
    util.exec("SUPER + ALT + Y", "nautilus --new-window")
    util.exec("SUPER + E", "kitty --class Neovim nvim")
    util.exec("SUPER + ALT + E", "neovide --neovim-bin nvim")
    util.exec("SUPER + B", "chromium-browser")
    util.exec("SUPER + SHIFT + B", "chromium-browser --incognito")
    util.exec("SUPER + ALT + B", "firefox")
    util.exec("SUPER + ALT + SHIFT + B", "firefox --private-window")
    util.exec("SUPER + CTRL + PERIOD", "1password")

    util.exec("SUPER + LEFT", "hypr-workspace prev")
    util.exec("SUPER + RIGHT", "hypr-workspace next")
    util.exec("SUPER + SEMICOLON", "hypr-workspace prev")
    util.exec("SUPER + APOSTROPHE", "hypr-workspace next")
    hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind("SUPER + ALT + mouse_down", hl.dsp.layout("move -col"))
    hl.bind("SUPER + ALT + mouse_up", hl.dsp.layout("move +col"))

    for i = 1, 9 do
        util.workspace_bind(tostring(i), i)
    end

    util.exec("SUPER + ALT + P", "hypr-workspace prev")
    util.exec("SUPER + ALT + N", "hypr-workspace next")
    util.exec("SUPER + SLASH", "hypr-layout next")
    util.exec("SUPER + ALT + SLASH", "hypr-layout prev")

    util.exec("SUPER + I", "hypr-tile")
    util.exec("SUPER + ALT + I", "hypr-tile alt")
    util.dispatch("SUPER + SHIFT + I", "cyclenext tiled")
    hl.bind("SUPER + ALT + M", hl.dsp.layout("addmaster"))
    hl.bind("SUPER + ALT + SHIFT + M", hl.dsp.layout("removemaster"))
    hl.bind("SUPER + W", hl.dsp.window.close())
    util.dispatch("SUPER + U", "focusurgentorlast")
    util.dispatch("SUPER + BACKSLASH", "focuscurrentorlast")

    util.exec("SUPER + TAB", "hypr-supertab")
    util.exec("SUPER + ALT + TAB", "hypr-supertab next")
    util.exec("SUPER + SHIFT + TAB", "hypr-supertab prev")
    util.exec("SUPER + M", "hypr-supertab mark")
    util.exec("SUPER + M", "hypr-supertab clear", { long_press = true })

    hl.bind("SUPER + ESCAPE", hl.dsp.workspace.toggle_special("special"))
    util.exec("SUPER + ALT + ESCAPE", "hypr-togglespecial")

    util.exec("SUPER + Q", "hypr-togglegrouporkill")
    util.dispatch("SUPER + COMMA", "changegroupactive b")
    util.dispatch("SUPER + COMMA", "lockactivegroup lock")
    util.dispatch("SUPER + PERIOD", "changegroupactive f")
    util.dispatch("SUPER + PERIOD", "lockactivegroup lock")
    util.dispatch("SUPER + ALT + COMMA", "movegroupwindow b")
    util.dispatch("SUPER + ALT + COMMA", "lockactivegroup lock")
    util.dispatch("SUPER + ALT + PERIOD", "movegroupwindow f")
    util.dispatch("SUPER + ALT + PERIOD", "lockactivegroup lock")
    util.exec("SUPER + ALT + mouse:272", "hypr-togglegrouporlock")
    util.exec("SUPER + COMMA", "hypr-togglegrouporlock f", { long_press = true })
    util.exec("SUPER + PERIOD", "hypr-togglegrouporlock b", { long_press = true })

    util.dispatch("SUPER + F", "fullscreen 1")
    util.dispatch("SUPER + ALT + F", "fullscreen 0")
    util.dispatch("SUPER + F", "fullscreen 0", { long_press = true })

    util.dispatch("SUPER + SHIFT + O", "cyclenext floating")
    util.exec("SUPER + O", "hypr-float")
    util.exec("SUPER + ALT + O", "hypr-togglefullscreenorhidden")
    util.dispatch("SUPER + O", "pin", { long_press = true })

    for i = 1, 9 do
        util.exec("SUPER + SHIFT + " .. i, "hypr-resizefloating " .. i .. "0")
    end

    for key, spec in pairs(move) do
        util.exec("SUPER + ALT + " .. key:upper(), string.format("hypr-movewindoworgrouporactive %s %d %d", spec.dir, spec.x, spec.y), { repeating = true })
    end

    hl.bind("SUPER + ALT + SHIFT + H", hl.dsp.layout("swapcol l"), { repeating = true })
    hl.bind("SUPER + ALT + SHIFT + L", hl.dsp.layout("swapcol r"), { repeating = true })
    util.dispatch("SUPER + SHIFT + H", "resizeactive -80 0", { repeating = true })
    util.dispatch("SUPER + SHIFT + J", "resizeactive 0 80", { repeating = true })
    util.dispatch("SUPER + SHIFT + K", "resizeactive 0 -80", { repeating = true })
    util.dispatch("SUPER + SHIFT + L", "resizeactive 80 0", { repeating = true })
    hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }), { repeating = true })
    hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }), { repeating = true })
    hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }), { repeating = true })
    hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }), { repeating = true })

    util.exec("SUPER + RETURN", "hypr-float", { long_press = true })
    util.exec("SUPER + Y", "hypr-float", { long_press = true })
    util.exec("SUPER + E", "hypr-float", { long_press = true })
    util.exec("SUPER + B", "hypr-float", { long_press = true })
    util.exec("SUPER + ALT + RETURN", "hypr-float", { long_press = true })
    util.exec("SUPER + ALT + Y", "hypr-float", { long_press = true })
    util.exec("SUPER + ALT + E", "hypr-float", { long_press = true })
    util.exec("SUPER + ALT + B", "hypr-float", { long_press = true })

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
end

return M
