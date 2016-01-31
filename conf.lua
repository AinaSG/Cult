function love.conf(t)
    t.identity = nil                    -- The name of the save directory (string)
    t.version = "0.9.2"                -- The LÖVE version this game was made for (string)
    t.console = false                   -- Attach a console (boolean, Windows only)
    t.gammacorrect = true              -- Enable gamma-correct rendering, when supported by the system (boolean)
 
    t.window.title = "Gaem"         -- The window title (string)
    t.window.icon = nil                 -- Filepath to an image to use as the window's icon (string)
    t.window.width = 1000                -- The window width (number)
    t.window.height = 700              -- The window height (number)
    t.window.borderless = false         -- Remove all border visuals from the window (boolean)
    t.window.resizable = false          -- Let the window be user-resizable (boolean)
    t.window.fullscreen = false         -- Enable fullscreen (boolean)
    t.window.vsync = true               -- Enable vertical sync (boolean)
    t.window.msaa = 0                   -- The number of samples to use with multi-sampled antialiasing (number)
    t.window.display = 1                -- Index of the monitor to show the window in (number)
    t.window.highdpi = true            -- Enable high-dpi mode for the window on a Retina display (boolean)
    t.window.fullscreen = false
end