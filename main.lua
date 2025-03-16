-- main.lua - Entry point for Love2D Vertical Jumper

local Player = require("entities/player")
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
--local KillFloor = require("entities/killFloor")
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

-- Mouse/touch tracking variables
local isDragging = false

-- Game settings
local settingsVisible = false  -- Toggle for settings menu visibility
local slowDownWhileDragging = false  -- Option to slow time during drag
local pauseWhileDragging = true  -- Option to pause game during drag
local slowDownFactor = 0.3  -- Game runs at 30% speed when dragging

-- Debug variables
local showDebugInfo = false
local debugInfoTimer = 0
local debugInfoInterval = 1 -- Update debug info every second
local debugMode = true -- Enable debug features
local disableParticles = false -- Debug option to disable particle effects
local showCollisionBounds = false -- Debug option to show collision bounds

-- Setup event handlers for player state changes
local function setupEventListeners()
    -- Clear any existing listeners first
    Events.clearAll()
    
    Events.on("dragStart", function(data)
        if pauseWhileDragging then
            timeManager:setTimeScale(0)
        elseif slowDownWhileDragging then
            timeManager:setTimeScale(slowDownFactor)
        end
        
        -- Clear any camera shake
        camera:clearShake()

    end)
    
    Events.on("dragEnd", function(data)
        if pauseWhileDragging or slowDownWhileDragging then
            timeManager:setTimeScale(1, true)
        end
        player:onDragEnd(data)
    end)
    
    Events.on("dragCancel", function()
        if pauseWhileDragging or slowDownWhileDragging then
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
        xpManager:onEnemyKill(data)
        
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
    Events.on("levelUpStateParticle", function(data)
        if particleManager then
            particleManager:createLevelUpEffect(data.x, data.y)
        end
    end)
    
    Events.on("levelUpMenuHidden", function()
        player:onLevelUpMenuHidden()
    end)
    
    -- Add this event handler to properly show the level-up menu when needed
    Events.on("playerLevelUp", function(data)
        if data.requiresMenu and levelUpMenu and not levelUpMenu:isVisible() then
            -- Pause the game during level-up
            timeManager:setTimeScale(0)
            -- Show the level-up menu
            levelUpMenu:show()
        end
    end)
    
    Events.on("playerExitLevelUpState", function(data)
        -- Resume normal game speed when exiting level up state
        timeManager:setTimeScale(1)
    end)
    -- Debug state changes if debug mode is on
    if debugMode then
        Events.on("playerStateChanged", function(data)
            print("Player state changed from " .. (data.prevState or "nil") .. " to " .. data.newState)
        end)
    end
end

local function initializeWorld()
    -- Reset game state
    gameOver = false
    score = 0
    gameSpeed = 50
    distanceClimbed = 0

    -- Clear all event listeners
    Events.clearAll()

    --clear collisions
    CollisionManager.clear()
    -- Initialize particle manager
    particleManager = ParticleManager:new()

    -- Initialize world generator
    world = World:new()
    -- Generate initial platforms
    platforms = {}
    springboards = {}
    world:generateInitialPlatforms(platforms, springboards)
    -- Initialize player
    player = Player:new()
    
    -- Initialize Time Manager
    timeManager = TimeManager:new()

    xpManager = XpManager:new()

    levelUpMenu = LevelUpMenu:new(player)

    transitionManager = TransitionManager:new()

    inputManager = InputManager:new() -- Initialize the new InputManager

    -- Initialize enemy manager (with platforms reference)
    enemyManager = EnemyManager:new()
    enemyManager:generateInitialEnemies(platforms) -- Pass platforms here

    -- Initialize camera
    camera = Camera:new(player)
    startHeight = player.y
  --  killFloor = KillFloor:new(MOBILE_WIDTH)

    setupEventListeners()
end

-- Load resources and initialize the game
function love.load()
    -- Set the window dimensions to match mobile resolution
    love.window.setMode(MOBILE_WIDTH, MOBILE_HEIGHT)

    -- Set the window title
    love.window.setTitle("Love2D Vertical Jumper")

    -- Set default background color
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)

   initializeWorld()
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

 --   killFloor.y = camera.y + MOBILE_HEIGHT *.75 -- 50px below the visible area
    
    -- Update kill floor
  --  killFloor:update(dt)
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
    
    -- Apply time effects from time manager
    dt = timeManager:update(dt)
    
    -- Store original dt for animations that should run regardless of pause
    local realDt = dt

    inputManager:update(dt, camera)

    -- Handle player dragging regardless of pause state
    if isDragging then
        -- No need to call player:calculateTrajectory() here!
        -- DraggingState:update will handle its own trajectory calculation
        
        if pauseWhileDragging then
            -- Instead of completely skipping updates, just update minimal elements
            -- Only allow UI and visual updates, but pause gameplay
            
            -- Update camera to ensure proper display
            camera:update(0, player, 0)  -- Zero dt to prevent movement
            
            -- Update particle systems with zero dt to prevent animation
            if not disableParticles then
                particleManager:update(0)
            end
            
            -- Special case: update combo text animations with the real dt
            player:updateComboAnimations(realDt)
            
            return  -- Skip the rest of the game updates
        elseif slowDownWhileDragging then
            -- Apply slow-motion effect
            dt = dt * slowDownFactor
        end
    end
    -- Cap dt to prevent tunneling through objects at low framerates
    dt = math.min(dt, 0.016)

    -- Check if we need to show level-up menu
    if player.levelUpPending and not levelUpMenu:isVisible() then
        -- Pause the game during level-up
        timeManager:setTimeScale(0)
        -- Show the level-up menu
        levelUpMenu:show()
    end


    

    -- Always update the player's XP popup text (it's just visual)
    player:updateXpPopup(dt)
    -- Update particle systems (if not disabled)
    if not disableParticles then
        particleManager:update(dt)
    end
    -- Update level-up menu if visible
    if levelUpMenu:isVisible() then
        levelUpMenu:update(dt)
    elseif player.stateMachine:getCurrentState():getName() == "LevelUp" then
        -- When in LevelUp state but game is paused, still update the player state
        player:update(dt)
        
        -- Also update particle manager to show effects
        if not disableParticles then
            particleManager:update(dt)
        end
    else
        updatePhysics(dt)
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
        print("Collision bounds " .. (showCollisionBounds and "visible" or "hidden"))
    end

    -- Toggle settings menu with S key
    if key == "s" then
        settingsVisible = not settingsVisible
    end
end
-- Replace the existing mouse/touch handlers with these unified versions
function love.mousepressed(x, y, button)
    handleInputStart(x, y, button)
end

function love.mousemoved(x, y)
    handleInputMove(x, y)
end

function love.mousereleased(x, y, button)
    handleInputEnd(x, y, button)
end

function love.touchpressed(id, x, y)
    -- Touch ID is ignored - we're treating all touches the same
    handleInputStart(x, y, 1) -- Use button 1 (left mouse button) for touches
end

function love.touchmoved(id, x, y)
    handleInputMove(x, y)
end

function love.touchreleased(id, x, y)
    handleInputEnd(x, y, 1) -- Use button 1 (left mouse button) for touches
end
function handleInputStart(x, y, button)
    -- First check if level-up menu is visible
    if levelUpMenu:isVisible() then
        levelUpMenu:handleInputStart(x, y, button)
        return
    end
    
    -- Check if clicking on settings UI
    if settingsVisible then
        -- Handle settings UI interactions
        if handleSettingsUIClick(x, y) then
            return -- Input was handled by settings
        end
    end

    -- Only handle left mouse button (or any touch)
    if (button == 1 or button == nil) and not gameOver then
        -- For touch input on mobile, adjust for camera position
        if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
            inputManager:mousepressed(x, y, 1, camera, player)
        else
            inputManager:mousepressed(x, y, 1, camera, player)
        end
    end
end

function handleInputMove(x, y)
    -- Check if level-up menu is handling input
    if levelUpMenu:isVisible() then
        levelUpMenu:handleInputMove(x, y)
        return
    end
    
    if not gameOver then
        -- For touch input on mobile, adjust for camera position
        if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
            inputManager:mousemoved(x, y, camera)
        else
            inputManager:mousemoved(x, y, camera)
        end
    end
end

function handleInputEnd(x, y, button)
    -- Only handle left mouse button (or any touch)
    if (button == 1 or button == nil) and not gameOver then
        -- For touch input on mobile, adjust for camera position
        if love.system.getOS() == "iOS" or love.system.getOS() == "Android" then
            inputManager:mousereleased(x, y, 1, camera)
        else
            inputManager:mousereleased(x, y, 1, camera)
        end
    end
end

-- Helper function to handle settings UI interactions
function handleSettingsUIClick(x, y)
    -- Check if clicking on slow down option
    if x >= 10 and x <= 30 and y >= 130 and y <= 150 then
        slowDownWhileDragging = not slowDownWhileDragging
        -- Disable pause if slow down is enabled
        if slowDownWhileDragging then
            pauseWhileDragging = false
        end
        return true
    end
    
    -- Check if clicking on pause option
    if x >= 10 and x <= 30 and y >= 170 and y <= 190 then
        pauseWhileDragging = not pauseWhileDragging
        -- Disable slow down if pause is enabled
        if pauseWhileDragging then
            slowDownWhileDragging = false
        end
        return true
    end
    
    -- Check if clicking on debug options
    if debugMode then
        -- Disable particles option
        if x >= 10 and x <= 30 and y >= 210 and y <= 230 then
            disableParticles = not disableParticles
            return true
        end
        
        -- Show collision bounds option
        if x >= 10 and x <= 30 and y >= 240 and y <= 260 then
            showCollisionBounds = not showCollisionBounds
            return true
        end
    end
    
    return false -- Click wasn't on a settings UI element
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
    
   -- killFloor:draw()
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
    xpManager:draw()

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
    love.graphics.print("Lava: " .. math.floor(distanceFromLava) .. "px", 10, 70)
    
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

    player:drawXpPopup()

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 10, 80, 100, 10)
    love.graphics.setColor(0.2, 0.8, 1)  -- Light blue
    love.graphics.rectangle("fill", 10, 80, 100 * (player.experience / player.xpToNextLevel), 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level " .. player.level, 115, 77)
    -- IMPORTANT: Draw level-up menu LAST to ensure it appears on top of everything
    if levelUpMenu:isVisible() then
        levelUpMenu:draw()
    end
    transitionManager:draw()

end

-- Debug function to spawn test XP pellets
function spawnTestXpPellets()
    print("Spawning test XP pellets")
    
    -- Spawn 5 test pellets around the player
    for i = 1, 5 do
        local offsetX = love.math.random(-100, 100)
        local offsetY = love.math.random(-100, 100)
        
        local pellet = xpManager:spawnXp(
            player.x + player.width/2 + offsetX,
            player.y + player.height/2 + offsetY,
            love.math.random(1, 3)
        )
        
        -- Make them immediately collectible
        pellet.collectible = true
        pellet.magnetizable = true
        
        -- Enable debug mode to see collision bounds
        pellet.debug = true
        
        -- XP pellets are already added to the collision manager in their constructor
        -- through BaseEntity, so we don't need to add them again
        
        print("Created test XP pellet at:", pellet.x, pellet.y)
    end
end

