function love.conf(t)
    t.window.title = "Wings of Fury"
    --t.window.vsync = 0

    t.window.resizable = true

    -- Original Flash player window dimensions
    t.window.width = 730
    t.window.height = 450

    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
end