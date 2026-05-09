local M = {}

local function rule(name, opts)
    opts.name = name
    return hl.window_rule(opts)
end

function M.apply(_, _)
    rule("game-workspace", {
        match = { tag = "game" },
        workspace = "9",
        fullscreen = true,
    })

    rule("fullscreen-idle-inhibit", {
        match = { class = ".*" },
        idle_inhibit = "fullscreen",
    })

    rule("mark-border", { match = { tag = "mark" }, border_size = 1 })
    rule("pin-border", { match = { pin = true }, border_size = 2 })
    rule("pin-undecorate-inactive", { match = { pin = true, focus = false }, decorate = false })
    rule("pip-float", {
        match = { tag = "pip" },
        float = true,
        pin = true,
        keep_aspect_ratio = true,
        size = "480 270",
        min_size = "240 135",
        max_size = "960 540",
        move = "((monitor_w*1)-490) ((monitor_h*1)-280)",
    })
    rule("dialog-float", {
        match = { tag = "dialog" },
        float = true,
        center = true,
        border_size = 0,
        size = "1280 768",
    })
    rule("dialog-save-tag", { match = { title = "(Progress|Save File|Save As)" }, tag = "+dialog" })
    rule("dialog-xdgp-tag", { match = { class = "xdg-desktop-portal-gtk" }, tag = "+dialog" })
    rule("dialog-junction-tag", { match = { class = "re.sonny.Junction" }, tag = "+dialog" })
    rule("media-float", { match = { tag = "media" }, float = true, size = "1280 720" })
end

return M
