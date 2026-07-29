-----------------------
---- LOOK AND FEEL ----
-----------------------

local wallust = require("themes.wallust")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 2,

        border_size = 3,

        col = {
            active_border   = { colors = { wallust.color4, wallust.color6 }, angle = 95 },
            inactive_border = wallust.color0,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 4,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 30,
            passes   = 5,
            vibrancy = 0.1696,
        },
    },
})
