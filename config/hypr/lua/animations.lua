--------------------
---- ANIMATIONS ----
--------------------

hl.config({
    animations = {
        enabled = true,
    },
})

-- Bezier curves
hl.curve("fluid",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}   } })
hl.curve("smoothIn",   { type = "bezier", points = { {0.25, 1},    {0.5, 1}      } })
hl.curve("smoothOut",  { type = "bezier", points = { {0.36, 0},    {0.66, -0.56} } })
hl.curve("oversmooth", { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.08} } })

-- Windows animations
hl.animation({ leaf = "windows",     enabled = true, speed = 4.5, bezier = "oversmooth", style = "popin 85%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.2, bezier = "oversmooth", style = "popin 85%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3.2, bezier = "smoothOut",  style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.8, bezier = "fluid" })

-- Fade animations
hl.animation({ leaf = "fade",    enabled = true, speed = 3.5, bezier = "smoothIn" })
hl.animation({ leaf = "fadeIn",  enabled = true, speed = 3.2, bezier = "smoothIn" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.8, bezier = "smoothIn" })

-- Layer shell animations (Quickshell, Mako, Vicinae, Rofi)
hl.animation({ leaf = "layers",    enabled = true, speed = 3.8, bezier = "oversmooth", style = "fade" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 3.5, bezier = "oversmooth", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "smoothIn",   style = "fade" })

-- Workspaces animations
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4.2, bezier = "oversmooth", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4.0, bezier = "oversmooth", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "smoothOut",  style = "slidefade 15%" })

-- Borders & active elements
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "fluid" })
