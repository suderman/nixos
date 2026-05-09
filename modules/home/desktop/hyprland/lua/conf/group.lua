local M = {}

function M.apply(_, _)
    hl.config({
        group = {
            merge_groups_on_drag = true,
            col = {
                border_active = "rgb(89b4fa)",
                border_inactive = "rgb(45475a)",
                border_locked_active = "rgb(94e2d5)",
            },
            groupbar = {
                enabled = true,
                font_family = "sanserif",
                font_size = 14,
                gaps_in = 10,
                gaps_out = 5,
                gradient_round_only_edges = false,
                gradient_rounding = 20,
                gradient_rounding_power = 4.0,
                gradients = true,
                height = 20,
                indicator_gap = 0,
                indicator_height = 0,
                keep_upper_gap = false,
                render_titles = true,
                round_only_edges = false,
                rounding = 15,
                rounding_power = 4.0,
                text_color = "rgba(30,30,46,0.8)",
                text_color_inactive = "rgba(30,30,46,0.8)",
                text_color_locked_active = "rgba(205,214,244,0.8)",
                text_color_locked_inactive = "rgba(205,214,244,0.8)",
                col = {
                    active = "rgba(205,214,244,0.8)",
                    inactive = "rgba(205,214,244,0.8)",
                    locked_active = "rgba(30,30,46,0.8)",
                    locked_inactive = "rgba(30,30,46,0.6)",
                },
            },
        },
    })
end

return M
