-- Configuration file for LÖVE
function love.conf(t)
    t.title = "Escape the Dungeon - ECS Factory Test"
    t.version = "11.4"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = 1
    
    -- For debugging
    t.console = true
    
    -- Modules we don't need
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    
    -- Enable all debug features during development
    t.window.highdpi = true
end 