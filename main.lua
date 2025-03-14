-- main.lua - Entry point for Love2D Vertical Jumper

-- Import managers and utilities
local ParticleManager = require("managers/particleManager")
local CollisionManager = require("managers/collisionManager")
local World = require("managers/world")
local Camera = require("managers/camera")
local EnemyManager = require("managers/enemyManager")
local Events = require("lib/events")
local TimeManager = require("lib/timeManager")
local TransitionManager = require("managers/transitionManager")
local InputManager = require('managers/inputManager')
local XpManager = require("managers/xpManager")
local LevelUpMenu = require("ui/levelUpMenu")

-- ECS System
local ECS = require("lib/ecs/ecs")
local Bridge = require("lib/ecs/bridge")
local ECSEntity = require("entities/ecsEntity")

-- ECS Entities
local PlayerECS = require("entities/playerECS")
local PlatformECS = require("entities/platformECS")
local SpringboardECS = require("entities/springboardECS")
local MovingPlatformECS = require("entities/movingPlatformECS")
local BatECS = require("entities/batECS")
local SlimeECS = require("entities/slimeECS")
local XpPelletECS = require("entities/xpPelletECS")
local PowerUpECS = require("entities/powerUpECS")
local EntityFactoryECS = require("entities/entityFactoryECS")

-- Mobile resolution settings
local MOBILE_WIDTH = 390  -- iPhone screen width
local MOBILE_HEIGHT = 844 -- iPhone screen height

-- Game state and managers
local player
local platforms = {}
local springboards = {}
local particleManager
local world
local camera
local distanceFromLava
local enemyManager
local xpManager
local levelUpMenu
local powerUpManager
local transitionManager
local inputManager
local timeManager
local gameSpeed = 50  -- Initial upward game speed (slower for vertical game)
local score = 0
local gameOver = false
local gameOverReason = 'DIED'
local distanceClimbed = 0
local startHeight = 0
local isPaused = false

-- ECS world and factory
local ecsWorld
local entityFactory

-- Mouse/touch tracking variables
local isDragging = false

-- Game settings
local settingsVisible = true  -- Toggle for settings menu visibility
local slowDownWhileDragging = false  -- Option to slow time during drag
local pauseWhileDragging = true  -- Option to pause game during drag
local slowDownFactor = 0.3  -- Game runs at 30% speed when dragging

-- Debug settings
local showCollisionBounds = false
local debugMode = false

-- Debug variables
local showDebugInfo = false
local debugInfoTimer = 0
local debugInfoInterval = 1 -- Update debug info every second
local disableParticles = true -- Debug option to disable particle effects

-- Setup event handlers for player state changes
local function setupEventListeners()
    -- Clear any existing listeners first
    Events.clearAll()
    
    Events.on("dragStart", function(data)
        if pauseWhileDragging then
            timeManager:setTimeScale(0)
            isPaused = true
        elseif slowDownWhileDragging then
            timeManager:setTimeScale(slowDownFactor)
        end
        
        -- Clear any camera shake
        camera:clearShake()

    end)
    
    Events.on("dragEnd", function(data)
        if pauseWhileDragging then
            timeManager:setTimeScale(1, true)
            isPaused = false
        elseif slowDownWhileDragging then
            timeManager:setTimeScale(1, true)
        end
        player:onDragEnd(data)
    end)
    
    Events.on("dragCancel", function()
        if pauseWhileDragging then
            timeManager:setTimeScale(1, true)
            isPaused = false
        elseif slowDownWhileDragging then
            timeManager:setTimeScale(1, true)
        end
    end)
    
    Events.on("playerDashStarted", function(data)
        -- Camera shake
        camera:shake(3, 0.2)
        
        -- Particle effects
        if data.fromGround then
            particleManager:createDustEffect(
                player.x + player.width/2,
                player.y,
                player.height
            )
        else
            particleManager:createDoubleJumpEffect(player)
        end
        
        -- Create dash effect
        particleManager:createDashEffect(
            player,
            -data.direction.x
        )
    end)

    Events.on("playerCollectionRadiusChanged", function(data)
        xpManager:setCollectionRadiusBonus(data.bonus)
    end)

    Events.on("playerSpringboardJump", function(data)
        -- Create extra powerful dust effect
        particleManager:createDustEffect(
            data.x,
            data.y,
            player.height
        )
        particleManager:createDustEffect(
            data.x - 10,
            data.y,
            player.height
        )
        particleManager:createDustEffect(
            data.x + 10,
            data.y,
            player.height
        )
    end)
    -- Handle enemy collisions through events
    Events.on("enemyCollision", function(data)
        player:enemyCollision(data)
    end)
    -- Handle enemy kill events
    Events.on("enemyKill", function(data)
        local comboCount = data.comboCount or 0
        local enemy = data.enemy
        camera:onEnemyKill(data)
        timeManager:onEnemyKill(data)
        
        -- Get the XP pellets created from the enemy kill
        local xpPellets = xpManager:onEnemyKill(data)
        
        -- XP pellets are already added to the collision manager in their constructor
        -- through BaseEntity, so we don't need to add them again
        
        enemy.active = false
        -- Create impact effect
        if enemy and particleManager then
            particleManager:createImpactEffect(
                enemy.x + enemy.width/2, 
                enemy.y + enemy.height/2
            )
            
            -- Add refresh effect
            particleManager:createRefreshEffect(player)
        end
    end)
    Events.on("powerupSelected", function(data)
        -- Resume game after powerup selection
        timeManager:setTimeScale(1)
        
        -- Create particle effect for powerup
        if particleManager and data.player then
            particleManager:createRefreshEffect(data.player)
        end
        
        -- Show temporary text on screen
        -- You can add this functionality if desired
    end)
    -- Debug state changes if debug mode is on
    if debugMode then
        Events.on("playerStateChanged", function(data)
            print("Player state changed from " .. (data.prevState or "nil") .. " to " .. data.newState)
        end)
    end
end

-- Initialize the ECS system
function initializeECS()
    -- Create the ECS world
    ecsWorld = Bridge.createWorld()
    
    -- Set the ECS world for ECSEntity
    ECSEntity.setECSWorld(ecsWorld)
    
    -- Create the entity factory
    entityFactory = EntityFactoryECS.new(ecsWorld)
    
    -- Make ecsWorld globally accessible
    _G.ecsWorld = ecsWorld
    
    -- Set up event handlers
    Events.on("enemyKill", function(data)
        -- Create XP drops using the ECS system
        if xpManager then
            xpManager:onEnemyKill(data)
        end
    end)
    
    Events.on("xpCollected", function(data)
        -- Add XP to player
        if player and player.addExperience then
            player:addExperience(data.value)
        end
    end)
    
    -- Enable collision debug drawing for development
    if debug and debug.collisionDebug then
        Bridge.toggleCollisionDebug(ecsWorld)
    end
    
    print("ECS system initialized")
end

local function initializeWorld()
    -- Reset game state
    gameOver = false
    score = 0
    gameSpeed = 50
    distanceClimbed = 0

    -- Clear all event listeners
    Events.clearAll()

    -- Clear collisions
    CollisionManager.clear()
    
    -- Initialize particle manager
    particleManager = ParticleManager:new()

    -- Initialize world generator
    world = World:new()
    
    -- Generate initial platforms
    platforms = {}
    springboards = {}
    
    -- Initialize player using ECS
    player = entityFactory:createPlayer(MOBILE_WIDTH / 2 - 16, MOBILE_HEIGHT - 200)
    
    -- Initialize Time Manager
    timeManager = TimeManager:new()

    xpManager = XpManager:new()

    levelUpMenu = LevelUpMenu:new(player)

    transitionManager = TransitionManager:new()

    inputManager = InputManager:new() -- Initialize the new InputManager

    -- Initialize enemy manager (with platforms reference)
    enemyManager = EnemyManager:new()
    
    -- Initialize camera
    camera = Camera:new(player)
    startHeight = player.y

    setupEventListeners()
    
    -- Generate initial platforms using ECS entities
    generateInitialPlatformsECS()
end

-- Generate initial platforms using ECS entities
function generateInitialPlatformsECS()
    -- Add the starting platform (wider for easier start)
    local startX = MOBILE_WIDTH / 2 - MOBILE_WIDTH * 0.25
    local startY = MOBILE_HEIGHT - 50
    local startPlatform = entityFactory:createPlatform(startX, startY, MOBILE_WIDTH * 0.5, 20)
    table.insert(platforms, startPlatform)
    
    -- Generate initial set of platforms going upward
    local highestY = startY
    for i = 1, 15 do
        -- Generate random vertical gap
        local verticalGap = love.math.random(80, 150)
        local platformY = highestY - verticalGap
        
        -- Generate random platform width
        local platformWidth = love.math.random(60, MOBILE_WIDTH * 0.5)
        
        -- Generate random X position within screen bounds
        local platformX = love.math.random(0, MOBILE_WIDTH - platformWidth)
        
        -- Create new platform using ECS
        local platform = entityFactory:createPlatform(platformX, platformY, platformWidth, 20)
        table.insert(platforms, platform)
        highestY = platformY
        
        -- Randomly add a springboard to the platform
        if love.math.random() < 0.3 then
            local springX = platformX + platformWidth/2 - 25  -- Center on platform
            local springboard = entityFactory:createSpringboard(springX, platformY - 20, 50, 20)
            table.insert(springboards, springboard)
        end
    end
end

-- Load resources and initialize the game
function love.load()
    -- Check for debug mode in command line arguments
    for _, arg in ipairs(love.arg.parseGameArguments(arg)) do
        if arg == "--debug" then
            debugMode = true
            showCollisionBounds = true
            print("Debug mode enabled")
        end
    end

    -- Set the window dimensions to match mobile resolution
    love.window.setMode(MOBILE_WIDTH, MOBILE_HEIGHT)

    -- Set the window title
    love.window.setTitle("Love2D Vertical Jumper")

    -- Set default background color
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)

    -- Initialize the ECS system
    initializeECS()

    -- Initialize the game world
    initializeWorld()
    
    -- Connect the XP manager to the ECS world
    xpManager:setECSWorld(ecsWorld)
    
    -- Connect the CollisionManager to the ECS world
    CollisionManager.setECSWorld(ecsWorld)
    
    -- Connect the ECSEntity class to the ECS world
    ECSEntity.setECSWorld(ecsWorld)

    -- Set up random seed
    math.randomseed(os.time())
    
    -- Start the game
    startGame()
end

-- Function to start or restart the game
function startGame()
    -- Reset game state
    gameOver = false
    score = 0
    gameSpeed = 50
    distanceClimbed = 0
    
    -- Initialize the world if it hasn't been initialized yet
    if not world then
        initializeWorld()
    end
    
    -- Reset player position
    if player then
        player.x = love.graphics.getWidth() / 2 - player.width / 2
        player.y = love.graphics.getHeight() - 200
    end
    
    -- Reset camera
    if camera then
        camera:reset(player)
        startHeight = player.y
    end
    
    -- Generate initial platforms if needed
    if #platforms == 0 then
        generateInitialPlatformsECS()
    end
    
    -- Reset enemy manager
    if enemyManager then
        enemyManager:reset()
        enemyManager:generateInitialEnemies(platforms)
    end
    
    -- Reset time manager
    if timeManager then
        timeManager:reset()
    end
    
    print("Game started!")
end

local function updatePhysics(dt)
    -- Clean up platforms that are below the view
    world:cleanupPlatforms(camera, platforms, springboards)

    -- Game over if player falls below camera view
    if player.y > camera.y + love.graphics.getHeight() - 50 then
        gameOver = true
        gameOverReason = "FELL INTO LAVA"
    end
    -- Update camera position
    distanceFromLava = camera:update(dt, player, gameSpeed)

    -- Check if player has been caught by lava
    if camera:isPlayerCaughtByLava(player) or distanceFromLava <= 0 then
        -- Player caught by lava - game over
        gameOver = true
        gameOverReason = "CAUGHT BY LAVA"
        
        -- Create some particle effects for burning
        particleManager:createBurnEffect(player.x + player.width/2, player.y + player.height/2)
        
        -- Add some screen shake
        camera:shake(5, 0.5)
    end

    -- Calculate distance climbed (negative y is upward)
    distanceClimbed = startHeight - camera.y

    -- Increase score based on height climbed
    score = math.max(score, math.floor(distanceClimbed / 10))

    -- Gradually increase game speed based on score
    gameSpeed = 50 + math.min(score / 10, 50)  -- Cap at 100

    -- Update player position
    player:update(dt)

    -- Check horizontal screen bounds
    player:checkHorizontalBounds(MOBILE_WIDTH)

    -- Generate new platforms as camera moves upward
    world:updatePlatforms(camera, platforms, springboards)

    xpManager:update(dt, player, camera)

    transitionManager:update(dt)

    -- Update enemies
    enemyManager:update(dt, player, camera)


    -- Handle enemy collisions and get combo info
   -- enemyManager:handleCollisions(player, particleManager)
    
    -- Add combo points to score if player has an active combo of 5 or higher
    if player.comboCount >= 5 and player.affirmationTimer and player.affirmationTimer > player.comboMaxTime - 0.1 then
        -- Add points based on combo level (only when combo is refreshed)
        -- More points for higher combos, with a bonus threshold at 5
        local comboPoints = (player.comboCount - 4) * 10  -- Start counting at 10 points for combo of 5
        score = score + comboPoints
    end

    -- Check for game over
    if player.health <= 0 then
        gameOver = true
    end

    -- Handle collisions
    CollisionManager:update(dt)

    -- Update springboards
    for _, spring in ipairs(springboards) do
        spring:update(dt)
    end
end

-- Update game state (dt is "delta time" - time since last frame)
function love.update(dt)
    if gameOver then
        if love.keyboard.isDown("r") then
            restartGame()
        end
        return
    end
    
    -- Update the ECS world first
    if ecsWorld then
        ecsWorld:update(dt)
    end
    
    -- Update time manager
    local scaledDt = timeManager:update(dt)
    
    -- Update transition manager
    transitionManager:update(dt)
    
    -- Only update game if not paused or transitioning
    if not transitionManager:isTransitioning() and not isPaused then
        -- Update input manager
        inputManager:update(dt)
        
        -- Update player
        if player and player.active then
            player:update(dt)
        end
        
        -- Update camera
        camera:update(dt)
        
        -- Update enemy manager
        enemyManager:update(dt)
        
        -- Update particle manager
        particleManager:update(dt)
        
        -- Update world
        world:update(dt)
        
        -- Update XP manager
        xpManager:update(dt)
        
        -- Update level up menu if active
        if levelUpMenu and levelUpMenu.active then
            levelUpMenu:update(dt)
        end
    end
end


local function transitionToGameOver()
    transitionManager:startTransition("fade", 0.5, "out", function()
        gameState = "gameover"
        -- Additional game over setup
    end)
end

-- Then call setupEventHandlers() in your love.load function
local function restartGame()
    initializeWorld()
end

-- Handle key presses
function love.keypressed(key)
    -- Forward key events to player
    player:keypressed(key, particleManager)

    -- Quit the game when escape is pressed
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        showDebugInfo = not showDebugInfo
    elseif key == "r" then
        -- Reset game
        restartGame()
    elseif key == "p" then
        -- Toggle pause
        if timeManager:getTimeScale() > 0 then
            timeManager:setTimeScale(0)
        else
            timeManager:setTimeScale(1)
        end
    elseif key == "x" and debugMode then
        -- Debug: Spawn test XP pellets
        spawnTestXpPellets()
    elseif key == "f2" and debugMode then
        -- Debug: Toggle particle effects
        disableParticles = not disableParticles
        print("Particle effects " .. (disableParticles and "disabled" or "enabled"))
    elseif key == "f3" and debugMode then
        -- Debug: Toggle collision bounds
        showCollisionBounds = not showCollisionBounds
        
        -- Toggle collision debug in ECS system if available
        if ecsWorld then
            Bridge.toggleCollisionDebug(ecsWorld)
        end
        
        print("Collision bounds " .. (showCollisionBounds and "visible" or "hidden"))
    end

    -- Toggle settings menu with S key
    if key == "s" then
        settingsVisible = not settingsVisible
    end
end

-- Mouse pressed (start drag)
function love.mousepressed(x, y, button)
    -- Check if level-up menu is active first
    if levelUpMenu:isVisible() then
        levelUpMenu:mousepressed(x, y, button)
        return
    end
    -- Check if clicking on settings UI
    if settingsVisible then
        -- Check if clicking on slow down option
        if x >= 10 and x <= 30 and y >= 130 and y <= 150 then
            slowDownWhileDragging = not slowDownWhileDragging
            -- Disable pause if slow down is enabled
            if slowDownWhileDragging then
                pauseWhileDragging = false
            end
            return
        end
        -- Check if clicking on pause option
        if x >= 10 and x <= 30 and y >= 170 and y <= 190 then
            pauseWhileDragging = not pauseWhileDragging
            -- Disable slow down if pause is enabled
            if pauseWhileDragging then
                slowDownWhileDragging = false
            end
            return
        end
        
        -- Check if clicking on disable particles option
        if debugMode and x >= 10 and x <= 30 and y >= 210 and y <= 230 then
            disableParticles = not disableParticles
            return
        end
        
        -- Check if clicking on show collision bounds option
        if debugMode and x >= 10 and x <= 30 and y >= 240 and y <= 260 then
            showCollisionBounds = not showCollisionBounds
            return
        end
    end

    if button == 1 and not gameOver then -- Left mouse button
        inputManager:mousepressed(x, y, button, camera, player)
    end
end

-- Mouse moved (update drag)
function love.mousemoved(x, y)
    if levelUpMenu:isVisible() then
        levelUpMenu:mousemoved(x, y)
        return
    end
    if not gameOver then
        inputManager:mousemoved(x, y, camera, player)
    end
end

-- Mouse released (end drag and jump)
function love.mousereleased(x, y, button)
    if button == 1 and not gameOver then -- Left mouse button
        inputManager:mousereleased(x, y, button, camera, player)
    end
end

-- Touch controls for mobile devices
function love.touchpressed(id, x, y)
    if levelUpMenu:isVisible() then
        levelUpMenu:touchpressed(id, x, y)
        return
    end
    -- Check if clicking on settings UI
    if settingsVisible then
        -- Check if clicking on slow down option
        if x >= 10 and x <= 30 and y >= 130 and y <= 150 then
            slowDownWhileDragging = not slowDownWhileDragging
            -- Disable pause if slow down is enabled
            if slowDownWhileDragging then
                pauseWhileDragging = false
            end
            return
        end
        -- Check if clicking on pause option
        if x >= 10 and x <= 30 and y >= 170 and y <= 190 then
            pauseWhileDragging = not pauseWhileDragging
            -- Disable slow down if pause is enabled
            if pauseWhileDragging then
                slowDownWhileDragging = false
            end
            return
        end
    end

    if not gameOver then
        inputManager:touchpressed(x, y + camera.y - MOBILE_HEIGHT / 2, player)
    end
end

function love.touchmoved(id, x, y)
    if not gameOver then
        inputManager:touchmoved(x, y + camera.y - MOBILE_HEIGHT / 2, player)
    end
end

function love.touchreleased(id, x, y)
    if not gameOver then
        inputManager:touchReleased(particleManager, player)
    end
end

-- Draw the game
function love.draw()
    -- Get camera position including shake
    local cameraPos = camera:getPosition()

    -- Apply camera transformation
    love.graphics.push()
    love.graphics.translate(0, -cameraPos.y + love.graphics.getHeight() / 2 + cameraPos.x)

    -- Draw platforms
    for _, platform in ipairs(platforms) do
        platform:draw()
    end

    -- Draw springboards
    for _, spring in ipairs(springboards) do
        spring:draw()
    end

    enemyManager:draw()

    -- Draw all particle systems (if not disabled)
    if not disableParticles then
        particleManager:draw()
    end

    -- Draw the player
    player:draw()
    
    -- Get bounds from collision manager
    local debugBounds = CollisionManager.getDebugBounds()
    
    -- Draw all collision bounds if enabled
    if showCollisionBounds then
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

    camera:drawLava()

    -- Draw input visualizations (trajectory, etc.)
    inputManager:draw(camera)

    -- Draw UI elements (not affected by camera)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Height: " .. math.floor(distanceClimbed), 10, 30)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 50, 100, 20)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 50, 100 * (player.health / 3), 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health", 15, 52)
    -- Draw game state indicators
    if inputManager:isDraggingActive() then
        if pauseWhileDragging then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("PAUSED", MOBILE_WIDTH - 80, 10)
        elseif slowDownWhileDragging then
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.print("SLOW-MO", MOBILE_WIDTH - 80, 10)
        end
    end
    
    -- Show debug indicators
    if debugMode then
        if disableParticles then
            love.graphics.setColor(0.8, 0.8, 0)
            love.graphics.print("PARTICLES OFF (F2)", MOBILE_WIDTH - 150, 30)
        end
        
        if showCollisionBounds then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("COLLISION BOUNDS ON (F3)", MOBILE_WIDTH - 180, 50)
        end
    end

    -- Settings button
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", MOBILE_WIDTH - 40, 40, 30, 30)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("line", MOBILE_WIDTH - 40, 40, 30, 30)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("S", MOBILE_WIDTH - 30, 45)

    -- Settings menu
    if settingsVisible then
        -- Settings panel background
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", 5, 100, 200, 200)
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("line", 5, 100, 200, 200)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME SETTINGS", 10, 105)

        -- Slow down option
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", 10, 130, 20, 20)
        if slowDownWhileDragging then
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", 13, 133, 14, 14)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Slow down while dragging", 35, 130)

        -- Pause option
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", 10, 170, 20, 20)
        if pauseWhileDragging then
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", 13, 173, 14, 14)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Pause while dragging", 35, 170)
        
        -- Disable particles option (debug)
        if debugMode then
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", 10, 210, 20, 20)
            if disableParticles then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", 13, 213, 14, 14)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Disable particle effects (F2)", 35, 210)
            
            -- Show collision bounds option
            love.graphics.setColor(0.3, 0.3, 0.4)
            love.graphics.rectangle("fill", 10, 240, 20, 20)
            if showCollisionBounds then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", 13, 243, 14, 14)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Show collision bounds (F3)", 35, 240)
        end

        -- Instructions
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Tap checkboxes to toggle options", 10, 270)
        love.graphics.print("Press 'S' to close settings", 10, 290)
    end
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("Lava: " .. math.floor(distanceFromLava or 0) .. "px", 10, 70)
    
    if gameOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf(gameOverReason, 0, love.graphics.getHeight() / 2 - 40, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to restart", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        love.graphics.printf("Final Score: " .. score, 0, love.graphics.getHeight() / 2 + 40, love.graphics.getWidth(), "center")
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Click and drag to jump", 10, 50)
        love.graphics.print("Pull back and release to launch", 10, 70)
        love.graphics.print("Jump in air for double-jump", 10, 90)
    end

    xpManager:draw()
    player:drawXpPopup()

    -- Draw XP bar
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 80, 100, 10)
    
    -- Get player XP data from ECS component
    local xpRatio = 0
    local playerLevel = 1
    
    if player and player.ecsEntity then
        local playerComponent = player.ecsEntity:getComponent("player")
        if playerComponent then
            xpRatio = playerComponent.xp / (playerComponent.xpToNextLevel or 100)
            playerLevel = playerComponent.level or 1
        end
    end
    
    love.graphics.setColor(0.2, 0.8, 1)  -- Light blue
    love.graphics.rectangle("fill", 10, 80, 100 * xpRatio, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level " .. playerLevel, 115, 77)
    
    -- IMPORTANT: Draw level-up menu LAST to ensure it appears on top of everything
    if levelUpMenu:isVisible() then
        levelUpMenu:draw()
    end
    transitionManager:draw()

end

-- Debug function to spawn test XP pellets
function spawnTestXpPellets()
    print("Spawning test XP pellets")
    
    -- Use the ECS system if available
    if ecsWorld then
        -- Create 5 test pellets around the player
        local playerCenterX = player.x + player.width / 2
        local playerCenterY = player.y + player.height / 2
        
        -- Create pellets using the Bridge
        local pellets = Bridge.createXpPellets(ecsWorld, playerCenterX, playerCenterY, 5, 10)
        
        -- Make them immediately collectible and magnetizable
        for _, pellet in ipairs(pellets) do
            local xp = pellet:getComponent("xp")
            xp.collectible = true
            xp.magnetizable = true
        end
        
        print("Created " .. #pellets .. " test XP pellets using ECS")
    else
        -- Fallback to old system
        for i = 1, 5 do
            local offsetX = love.math.random(-50, 50)
            local offsetY = love.math.random(-50, 50)
            
            local pellet = xpManager:spawnXp(
                player.x + player.width/2 + offsetX,
                player.y + player.height/2 + offsetY,
                10
            )
            
            pellet.collectible = true
            pellet.magnetizable = true
            pellet.debug = true
        end
        
        print("Created 5 test XP pellets using legacy system")
    end
end

