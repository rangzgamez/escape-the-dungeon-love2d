-- conf.lua - Configuration file for Love2D Vertical Jumper
-- Controls the game settings and window properties

function love.conf(t)
    -- Identity
    t.identity = "escapeTheDungeon"           -- Save directory name
    t.appendidentity = false                -- Search files in source directory before save directory
    t.version = "11.3"                      -- Love2D version this game was made for
    t.console = false                       -- Attach console for debug prints (Windows only)

    -- Window Settings
    t.window.title = "Escape the Dungeon!"  -- Window title
    t.window.icon = nil                     -- Window icon path (set this when you have an icon)
    t.window.width = 390                    -- Default window width (iPhone size)
    t.window.height = 844                   -- Default window height (iPhone size)
    t.window.borderless = false             -- Remove window border
    t.window.resizable = true               -- Allow window resizing
    t.window.minwidth = 390                 -- Minimum window width
    t.window.minheight = 600                -- Minimum window height
    t.window.fullscreen = false             -- Enable fullscreen
    t.window.fullscreentype = "desktop"     -- "desktop" or "exclusive"
    t.window.vsync = 1                      -- Vertical sync (1 = enabled, 0 = disabled, -1 = adaptive)
    t.window.msaa = 0                       -- Multi-sample anti-aliasing level (higher values are smoother)
    t.window.depth = nil                    -- Bits per sample of depth buffer
    t.window.stencil = nil                  -- Bits per sample of stencil buffer
    t.window.display = 1                    -- Display index to use on multi-monitor setups
    t.window.highdpi = true                 -- Enable high-dpi mode (not all systems support this)
    t.window.usedpiscale = true             -- Scale the screen based on DPI

    -- Modules
    -- Only enable the modules you need to reduce memory usage
    t.modules.audio = true                  -- Enable audio module
    t.modules.data = true                   -- Enable data module (for JSON)
    t.modules.event = true                  -- Enable event handling
    t.modules.font = true                   -- Enable font module
    t.modules.graphics = true               -- Enable graphics module
    t.modules.image = true                  -- Enable image loading
    t.modules.joystick = false              -- Enable joystick module
    t.modules.keyboard = true               -- Enable keyboard module
    t.modules.math = true                   -- Enable math module
    t.modules.mouse = true                  -- Enable mouse module
    t.modules.physics = false               -- Disable Box2D physics (we use custom physics)
    t.modules.sound = true                  -- Enable sound module
    t.modules.system = true                 -- Enable system access
    t.modules.thread = false                -- Disable threading (unless needed)
    t.modules.timer = true                  -- Enable timer module
    t.modules.touch = true                  -- Enable touch module (mobile)
    t.modules.video = false                 -- Disable video playback
    t.modules.window = true                 -- Enable window creation

    -- Accelerometer
    t.accelerometerjoystick = true          -- Enable accelerometer on iOS/Android as a joystick

    -- Other settings
    t.externalstorage = false               -- Use external storage on Android (true recommended)
    t.gammacorrect = false                  -- Enable gamma correction (advanced)
end