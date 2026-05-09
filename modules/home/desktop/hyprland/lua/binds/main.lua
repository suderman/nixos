local util = require("lib.util")

local M = {}

function M.apply(_, _)
    local move = {
        h = { dir = "l", x = -40, y = 0 },
        j = { dir = "d", x = 0, y = 40 },
        k = { dir = "u", x = 0, y = -40 },
        l = { dir = "r", x = 40, y = 0 },
    }
    local layout_state = {}

    local function active_layout()
        local ws = hl.get_active_workspace()
        if not ws then
            return nil
        end

        return ws.tiledLayout or ws.layout
    end

    local function cycle_workspace(direction)
        hl.dispatch(hl.dsp.focus({ workspace = direction == "prev" and "e-1" or "e+1" }))
    end

    local function cycle_layout(direction)
        local ws = hl.get_active_workspace()
        if not ws then
            return
        end

        local layouts = { "dwindle", "master", "scrolling", "monocle" }
        local current = layout_state[ws.id] or ws.tiledLayout or ws.layout or "dwindle"
        local idx = 1

        for i, layout in ipairs(layouts) do
            if layout == current then
                idx = i
                break
            end
        end

        if direction == "prev" then
            idx = ((idx - 2) % #layouts) + 1
        else
            idx = (idx % #layouts) + 1
        end

        layout_state[ws.id] = layouts[idx]
        hl.workspace_rule({ workspace = tostring(ws.id), layout = layouts[idx] })
        hl.exec_cmd("pkill -RTMIN+8 waybar")
    end

    local function cycle_window(direction)
        local layout = active_layout()

        if layout == "master" then
            hl.dispatch(hl.dsp.layout(direction == "prev" and "rollprev" or "rollnext"))
            hl.dispatch(hl.dsp.focus({ window = "master" }))
        elseif layout == "scrolling" then
            hl.dispatch(hl.dsp.focus({ direction = direction == "prev" and "left" or "right" }))
        elseif layout == "monocle" then
            hl.dispatch(hl.dsp.layout(direction == "prev" and "cycleprev" or "cyclenext"))
        else
            hl.dispatch(hl.dsp.window.cycle_next({ next = direction ~= "prev" }))
        end
    end

    local function float_active()
        local win = hl.get_active_window()
        if not win then
            return
        end

        if win.floating then
            if win.pinned then
                hl.dispatch(hl.dsp.window.pin())
            end
            return
        end

        hl.dispatch(hl.dsp.window.float({ action = "float" }))
        hl.dispatch(hl.dsp.window.center())
    end

    local function tile_active(alt_mode)
        local win = hl.get_active_window()
        if not win then
            return
        end

        if win.floating then
            hl.dispatch(hl.dsp.window.float({ action = "tile" }))
            return
        end

        local layout = active_layout()

        if layout == "master" then
            hl.dispatch(hl.dsp.layout("swapwithmaster master"))
        else
            hl.dispatch(hl.dsp.layout(alt_mode and "swapsplit" or "togglesplit"))
        end
    end

    hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())

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

    hl.bind("SUPER + LEFT", function() cycle_workspace("prev") end)
    hl.bind("SUPER + RIGHT", function() cycle_workspace("next") end)
    hl.bind("SUPER + SEMICOLON", function() cycle_workspace("prev") end)
    hl.bind("SUPER + APOSTROPHE", function() cycle_workspace("next") end)
    hl.bind("SUPER + mouse_down", function() cycle_workspace("prev") end)
    hl.bind("SUPER + mouse_up", function() cycle_workspace("next") end)
    hl.bind("SUPER + ALT + mouse_down", hl.dsp.layout("move -col"))
    hl.bind("SUPER + ALT + mouse_up", hl.dsp.layout("move +col"))

    for i = 1, 9 do
        util.workspace_bind(tostring(i), i)
    end

    hl.bind("SUPER + ALT + P", function() cycle_workspace("prev") end)
    hl.bind("SUPER + ALT + N", function() cycle_workspace("next") end)
    hl.bind("SUPER + SLASH", function() cycle_layout("next") end)
    hl.bind("SUPER + ALT + SLASH", function() cycle_layout("prev") end)

    hl.bind("SUPER + I", function() tile_active(false) end)
    hl.bind("SUPER + ALT + I", function() tile_active(true) end)
    hl.bind("SUPER + SHIFT + I", hl.dsp.window.cycle_next({ tiled = true }))
    hl.bind("SUPER + ALT + M", hl.dsp.layout("addmaster"))
    hl.bind("SUPER + ALT + SHIFT + M", hl.dsp.layout("removemaster"))
    hl.bind("SUPER + W", hl.dsp.window.close())
    hl.bind("SUPER + U", hl.dsp.focus({ urgent_or_last = true }))
    hl.bind("SUPER + BACKSLASH", hl.dsp.focus({ last = true }))

    util.exec("SUPER + TAB", "hypr-supertab")
    util.exec("SUPER + ALT + TAB", "hypr-supertab next")
    util.exec("SUPER + SHIFT + TAB", "hypr-supertab prev")
    util.exec("SUPER + M", "hypr-supertab mark")
    util.exec("SUPER + M", "hypr-supertab clear", { long_press = true })

    hl.bind("SUPER + ESCAPE", hl.dsp.workspace.toggle_special("special"))
    util.exec("SUPER + ALT + ESCAPE", "hypr-togglespecial")

    util.exec("SUPER + Q", "hypr-togglegrouporkill")
    hl.bind("SUPER + COMMA", hl.dsp.group.prev())
    hl.bind("SUPER + COMMA", hl.dsp.group.lock_active({ action = "lock" }))
    hl.bind("SUPER + PERIOD", hl.dsp.group.next())
    hl.bind("SUPER + PERIOD", hl.dsp.group.lock_active({ action = "lock" }))
    hl.bind("SUPER + ALT + COMMA", hl.dsp.group.move_window({ forward = false }))
    hl.bind("SUPER + ALT + COMMA", hl.dsp.group.lock_active({ action = "lock" }))
    hl.bind("SUPER + ALT + PERIOD", hl.dsp.group.move_window({ forward = true }))
    hl.bind("SUPER + ALT + PERIOD", hl.dsp.group.lock_active({ action = "lock" }))
    util.exec("SUPER + ALT + mouse:272", "hypr-togglegrouporlock")
    util.exec("SUPER + COMMA", "hypr-togglegrouporlock f", { long_press = true })
    util.exec("SUPER + PERIOD", "hypr-togglegrouporlock b", { long_press = true })

    hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
    hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
    hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { long_press = true })

    hl.bind("SUPER + SHIFT + O", hl.dsp.window.cycle_next({ floating = true }))
    hl.bind("SUPER + O", float_active)
    util.exec("SUPER + ALT + O", "hypr-togglefullscreenorhidden")
    hl.bind("SUPER + O", hl.dsp.window.pin(), { long_press = true })

    for i = 1, 9 do
        util.exec("SUPER + SHIFT + " .. i, "hypr-resizefloating " .. i .. "0")
    end

    for key, spec in pairs(move) do
        util.exec("SUPER + ALT + " .. key:upper(), string.format("hypr-movewindoworgrouporactive %s %d %d", spec.dir, spec.x, spec.y), { repeating = true })
    end

    hl.bind("SUPER + ALT + SHIFT + H", hl.dsp.layout("swapcol l"), { repeating = true })
    hl.bind("SUPER + ALT + SHIFT + L", hl.dsp.layout("swapcol r"), { repeating = true })
    hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -80, y = 0, relative = true }), { repeating = true })
    hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 80, relative = true }), { repeating = true })
    hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -80, relative = true }), { repeating = true })
    hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 80, y = 0, relative = true }), { repeating = true })
    hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }), { repeating = true })
    hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }), { repeating = true })
    hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }), { repeating = true })
    hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }), { repeating = true })

    hl.bind("SUPER + RETURN", float_active, { long_press = true })
    hl.bind("SUPER + Y", float_active, { long_press = true })
    hl.bind("SUPER + E", float_active, { long_press = true })
    hl.bind("SUPER + B", float_active, { long_press = true })
    hl.bind("SUPER + ALT + RETURN", float_active, { long_press = true })
    hl.bind("SUPER + ALT + Y", float_active, { long_press = true })
    hl.bind("SUPER + ALT + E", float_active, { long_press = true })
    hl.bind("SUPER + ALT + B", float_active, { long_press = true })

    hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
end

return M
