-- main_pooling.lua - Example main file with object pooling
-- This demonstrates how to integrate object pools into the game

local Player = require("entities/player")
local ParticlePool = require("managers/particlePool")
local XpPelletPool = require("managers/xpPelletPool")
local EnemyPool = require("managers/enemyPool")
local PlatformPool = require("managers/platformPool")
local CollisionManager = require("managers/collisionManager")
local Events = require("lib/events")
local Camera = require("managers/camera")
local TimeManager = require("lib/timeManager")
local InputManager = require("managers/inputManager")

-- Game dimensions
local SCREEN_WIDTH = 390  -- iPhone screen width
local SCREEN_HEIGHT = 844 -- iPhone screen height

-- Game state
local player
local particlePool
local xpPelletPool
local enemyPool
local platformPool
local camera
local timeManager
local inputManager
local gameOver = false
local gameOverReason = 'DIED'
local score = 0
local distanceClimbed = 0
local startHeight = 0
local distanceFromLava = 0

-- Settings and debug
local settingsVisible = false
local debugMode = false
local showCollisionBounds = false
local showStatsOverlay = false
local disableParticles = false

-- Set up event handlers
local function setupEventHandlers()
    -- Clear any existing handlers
    Events.clearAll()
    
    -- Input drag events
    Events.on("dragStart", function(data)
        timeManager:startDragSlowdown()
        camera:clearShake()
    end)
    
    Events.on("dragEnd", function(data)
        timeManager:endDragSlowdown()
        player:onDragEnd(data)
    end)
    
    Events.on("dragCancel", function()
        timeManager:endDragSlowdown()
    end)
    
    -- Player state events
    Events.on("playerStateChanged", function(data)
        if debugMode then
            print("Player state changed from " .. (data.prevState or "nil") .. " to " .. data.newState)
        end
    end)
    
    -- Camera shake events
    Events.on("playerHit", function(data)
        camera:shake(3, 0.2)
    end)
    
    Events.on("playerDashStarted", function(data)
        camera:shake(3 * data.power, 0.2)
    end)
    
    Events.on("enemyKill", function(data)
        local comboCount = data.comboCount or 0
        camera:shake(2 + comboCount * 0.3, 0.25)
        timeManager:onEnemyKill(data)
    end)
    
    -- Combo system events are handled by ParticlePool's event handlers
    
    -- Collection radius changes from player upgrades
    Events.on("playerCollectionRadiusChanged", function(data)
        xpPelletPool:setCollectionRadiusBonus(data.bonus or 0)
    end)
end

-- Initialize pools and game state
local function initializeGame()
    -- Clear any existing state
    CollisionManager.clear()
    
    -- Reset game state
    gameOver = false
    score = 0
    distanceClimbed = 0
    
    -- Create input manager
    inputManager = InputManager:new()
    
    -- Create time manager
    timeManager = TimeManager:new()
    
    -- Create player
    player = Player:new()
    
    -- Create object pools
    particlePool = ParticlePool:new()
    xpPelletPool = XpPelletPool:new()
    enemyPool = EnemyPool:new()
    platformPool = PlatformPool:new()
    
    -- Initialize platforms
    platformPool:initialize(SCREEN_HEIGHT - 50)
    startHeight = player.y
    
    -- Initialize enemies
    enemyPool:initialize(SCREEN_HEIGHT, platformPool:getPlatforms())
    
    -- Create camera
    camera = Camera:new(player)
    
    -- Set debug mode
    particlePool:setParticlesDisabled(disableParticles)
    if debugMode then
        platformPool:setDebugMode(true)
        enemyPool:setDebugMode(true)
        xpPelletPool:setDebugMode(true)
    end
    
    -- Set up event handlers
    setupEventHandlers()
end

-- Update game physics
local function updatePhysics(dt)
    -- Update player
    player:update(dt)
    
    -- Update camera
    distanceFromLava = camera:update(dt, player, 0)
    
    -- Check if player has been caught by lava
    if camera:isPlayerCaughtByLava(player) or distanceFromLava <= 0 then
        -- Player caught by lava - game over
        gameOver = true
        gameOverReason = "CAUGHT BY LAVA"
        
        -- Create some particle effects for burning
        particlePool:createBurnEffect(player.x + player.width/2, player.y + player.height/2)
        
        -- Add some screen shake
        camera:shake(5, 0.5)
    end
    
    -- Calculate distance climbed
    distanceClimbed = startHeight - camera.y
    
    -- Increase score based on height climbed
    score = math.max(score, math.floor(distanceClimbed / 10))
    
    -- Update platforms and generate new ones
    platformPool:update(dt, camera)
    
    -- Update enemies and generate new ones
    enemyPool:update(dt, player, camera)
    
    -- Update XP pellets with magnetic attraction
    xpPelletPool:update(dt, player, camera)
    
    -- Check for game over
    if player.health <= 0 then
        gameOver = true
        gameOverReason = "NO HEALTH"
    end
    
    -- Handle collisions
    CollisionManager:update(dt)
end

-- Main love.update function
function love.update(dt)
    if gameOver then
        if love.keyboard.isDown("r") then
            initializeGame()
        end
        return
    end
    
    -- Apply time effects
    dt = timeManager:update(dt)
    
    -- Store original dt for animations
    local realDt = dt
    
    -- Update input manager
    inputManager:update(dt, camera)
    
    -- Update particles (always update, even if paused)
    particlePool:update(realDt)
    
    -- Player is in level up menu, pause the game
    if player.levelUpPending then
        -- Just update minimal elements
        player:updateXpPopup(realDt)
        return
    end
    
    -- Update game physics
    updatePhysics(dt)
end

-- Main love.draw function
function love.draw()
    -- Apply camera transformation
    love.graphics.push()
    love.graphics.translate(0, -camera.y + love.graphics.getHeight() / 2 + camera.shakeOffsetX)
    
    -- Draw platforms
    platformPool:draw()
    
    -- Draw enemies
    enemyPool:draw()
    
    -- Draw XP pellets
    xpPelletPool:draw()
    
    -- Draw player
    player:draw()
    
    -- Draw particle effects
    particlePool:draw(camera)
    
    -- Draw collision bounds if enabled
    if showCollisionBounds then
        local debugBounds = CollisionManager.getDebugBounds()
        
        for _, info in ipairs(debugBounds) do
            love.graphics.setColor(info.color)
            love.graphics.rectangle("line", 
                info.bounds.x, 
                info.bounds.y, 
                info.bounds.width, 
                info.bounds.height
            )
        end
    end
    
    love.graphics.pop()
    
    -- Draw lava
    camera:drawLava()
    
    -- Draw trajectory preview
    inputManager:draw(camera)
    
    -- Draw UI elements
    drawUI()
    
    -- Draw settings if visible
    if settingsVisible then
        drawSettings()
    end
    
    -- Draw stats overlay if enabled
    if showStatsOverlay then
        drawStatsOverlay()
    end
    
    -- Draw game over screen
    if gameOver then
        drawGameOver()
    end
end

-- Draw UI elements
function drawUI()
    -- Draw score and height
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Height: " .. math.floor(distanceClimbed), 10, 30)
    
    -- Draw health bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 50, 100, 20)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 50, 100 * (player.health / 3), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health", 15, 52)
    
    -- Draw lava distance warning
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("Lava: " .. math.floor(distanceFromLava) .. "px", 10, 70)
    
    -- Draw XP bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 80, 100, 10)
    love.graphics.setColor(0.2, 0.8, 1)
    love.graphics.rectangle("fill", 10, 80, 100 * (player.experience / player.xpToNextLevel), 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level " .. player.level, 115, 77)
    
    -- Draw settings button
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", SCREEN_WIDTH - 40, 40, 30, 30)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", SCREEN_WIDTH - 40, 40, 30, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("S", SCREEN_WIDTH - 30, 45)
    
    -- Draw player XP popup
    player:drawXpPopup()
    
    -- Draw game state indicators
    if inputManager:isDraggingActive() then
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.print("AIMING", SCREEN_WIDTH - 80, 10)
    end
    
    -- Show debug indicators
    if debugMode then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("DEBUG MODE", SCREEN_WIDTH - 100, 80)
        
        if disableParticles then
            love.graphics.setColor(0.8, 0.8, 0)
            love.graphics.print("PARTICLES OFF", SCREEN_WIDTH - 120, 100)
        end
        
        if showCollisionBounds then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("COLLISION BOUNDS ON", SCREEN_WIDTH - 180, 120)
        end
    end
end

-- Draw settings menu
function drawSettings()
    -- Settings panel background
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", 5, 100, 200, 240)
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.rectangle("line", 5, 100, 200, 240)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME SETTINGS", 10, 105)
    
    -- Debug options section
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("DEBUG OPTIONS:", 10, 135)
    
    -- Debug mode option
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 10, 160, 20, 20)
    if debugMode then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", 13, 163, 14, 14)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Debug mode (F1)", 35, 160)
    
    -- Disable particles option
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 10, 190, 20, 20)
    if disableParticles then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", 13, 193, 14, 14)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Disable particle effects (F2)", 35, 190)
    
    -- Show collision bounds option
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 10, 220, 20, 20)
    if showCollisionBounds then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", 13, 223, 14, 14)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Show collision bounds (F3)", 35, 220)
    
    -- Show stats overlay option
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 10, 250, 20, 20)
    if showStatsOverlay then
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", 13, 253, 14, 14)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Show stats overlay (F4)", 35, 250)
    
    -- Spawn test XP pellets button
    love.graphics.setColor(0.3, 0.3, 0.6)
    love.graphics.rectangle("fill", 10, 290, 150, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Spawn Test XP (X)", 20, 298)
    
    -- Instructions
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Press 'S' to close settings", 10, 330)
end

-- Draw game over screen
function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    
    love.graphics.setColor(1, 0, 0)
    love.graphics.printf(gameOverReason, 0, SCREEN_HEIGHT / 2 - 40, SCREEN_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Press R to restart", 0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, "center")
    love.graphics.printf("Final Score: " .. score, 0, SCREEN_HEIGHT / 2 + 40, SCREEN_WIDTH, "center")
end

-- Draw stats overlay
function drawStatsOverlay()
    -- Get stats from object pools
    local platformStats = platformPool:getStats()
    local enemyStats = enemyPool:getStats()
    local xpStats = xpPelletPool:getStats()
    local particleStats = particlePool:getStats()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", SCREEN_WIDTH - 210, 140, 200, 240)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Memory Usage Stats", SCREEN_WIDTH - 200, 145)
    
    -- Format
    local y = 170
    local lineHeight = 18
    
    -- Platform stats
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Platforms:", SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("  Active: %d platforms, %d springs", 
        platformStats.activePlatforms, platformStats.activeSpringboards), SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.print(string.format("  Pool: %d/%d platforms, %d/%d springs", 
        platformStats.platformPool.active, platformStats.platformPool.total,
        platformStats.springboardPool.active, platformStats.springboardPool.total), SCREEN_WIDTH - 200, y)
    y = y + lineHeight + 5
    
    -- Enemy stats
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Enemies:", SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("  Active: %d enemies", enemyStats.active), SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.print(string.format("  Pool: %d/%d bats, %d/%d slimes", 
        enemyStats.batPool.active, enemyStats.batPool.total,
        enemyStats.slimePool.active, enemyStats.slimePool.total), SCREEN_WIDTH - 200, y)
    y = y + lineHeight + 5
    
    -- XP stats
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("XP Pellets:", SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("  Active: %d pellets", xpStats.active), SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.print(string.format("  Pool: %d/%d pellets", 
        xpStats.active, xpStats.total), SCREEN_WIDTH - 200, y)
    y = y + lineHeight + 5
    
    -- Particle stats
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Particles:", SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("  Active: %d effects", particleStats.active), SCREEN_WIDTH - 200, y)
    y = y + lineHeight
    love.graphics.print(string.format("  Pool: %d/%d effects", 
        particleStats.active, particleStats.total), SCREEN_WIDTH - 200, y)
end

-- Handle key presses
function love.keypressed(key)
    -- Forward key events to player
    player:keypressed(key)

    -- Quit the game when escape is pressed
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        debugMode = not debugMode
        platformPool:setDebugMode(debugMode)
        enemyPool:setDebugMode(debugMode)
        xpPelletPool:setDebugMode(debugMode)
    elseif key == "r" then
        -- Reset game
        initializeGame()
    elseif key == "f2" then
        -- Toggle particle effects
        disableParticles = not disableParticles
        particlePool:setParticlesDisabled(disableParticles)
    elseif key == "f3" then
        -- Toggle collision bounds
        showCollisionBounds = not showCollisionBounds
    elseif key == "f4" then
        -- Toggle stats overlay
        showStatsOverlay = not showStatsOverlay
    elseif key == "x" and debugMode then
        -- Debug: Spawn test XP pellets
        xpPelletPool:spawnTestPellets(player, 5)
    end

    -- Toggle settings menu with S key
    if key == "s" then
        settingsVisible = not settingsVisible
    end
end

-- Handle mouse events
function love.mousepressed(x, y, button)
    -- Handle setting UI interactions
    if settingsVisible then
        -- Check if clicking on a setting toggle
        if x >= 10 and x <= 30 and y >= 160 and y <= 180 then
            debugMode = not debugMode
            platformPool:setDebugMode(debugMode)
            enemyPool:setDebugMode(debugMode)
            xpPelletPool:setDebugMode(debugMode)
            return
        elseif x >= 10 and x <= 30 and y >= 190 and y <= 210 then
            disableParticles = not disableParticles
            particlePool:setParticlesDisabled(disableParticles)
            return
        elseif x >= 10 and x <= 30 and y >= 220 and y <= 240 then
            showCollisionBounds = not showCollisionBounds
            return
        elseif x >= 10 and x <= 30 and y >= 250 and y <= 270 then
            showStatsOverlay = not showStatsOverlay
            return
        elseif x >= 10 and x <= 160 and y >= 290 and y <= 320 then
            xpPelletPool:spawnTestPellets(player, 5)
            return
        end
    end
    
    -- Check if clicking settings button
    if x >= SCREEN_WIDTH - 40 and x <= SCREEN_WIDTH - 10 and y >= 40 and y <= 70 then
        settingsVisible = not settingsVisible
        return
    end
    
    -- Handle drag start
    inputManager:mousepressed(x, y, button, camera, player)
end

function love.mousemoved(x, y)
    inputManager:mousemoved(x, y, camera)
end

function love.mousereleased(x, y, button)
    inputManager:mousereleased(x, y, button, camera)
end

-- Love callback for loading game
function love.load()
    -- Set the window dimensions to match mobile resolution
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Set the window title
    love.window.setTitle("Vertical Jumper - Pooled Objects")

    -- Set default background color
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)

    -- Initialize the game
    initializeGame()
end

-- If this file is run directly, start the game
if ... == nil then
    love.run()
end

-- Return the modified game for imports
return {
    initializeGame = initializeGame,
    drawStatsOverlay = drawStatsOverlay
}