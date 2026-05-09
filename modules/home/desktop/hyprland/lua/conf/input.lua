local M = {}

function M.apply(_, _)
    hl.config({
        input = {
            kb_layout = "us",
            follow_mouse = 1,
            natural_scroll = true,
            scroll_factor = 1.5,
            scroll_method = "2fg",
            sensitivity = 0,
            touchpad = {
                clickfinger_behavior = true,
                disable_while_typing = true,
                natural_scroll = true,
                scroll_factor = 0.7,
            },
        },
    })

    hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
    hl.gesture({
        fingers = 3,
        direction = "left",
        action = function()
            hl.dispatch(hl.dsp.layout("move +col"))
        end,
    })
    hl.gesture({
        fingers = 3,
        direction = "right",
        action = function()
            hl.dispatch(hl.dsp.layout("move -col"))
        end,
    })
end

return M
