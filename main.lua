-- main.lua - Entry point for Love2D Vertical Jumper

local Player = require("entities/player")
local ParticleManager = require("managers/particleManager")
local CollisionManager = require("managers/collisionManager")
local World = require("managers/world")
local Camera = require("managers/camera")
local EnemyManager = require("managers/enemyManager")
local Events = require("lib/events")
local TimeManager = require("lib/timeManager")
local PowerUpManager = require('managers/powerUpManager')
local TransitionManager = require("managers/transitionManager")
local InputManager = require('managers/inputManager')
-- Mobile resolution settings
local MOBILE_WIDTH = 390  -- iPhone screen width
local MOBILE_HEIGHT = 844 -- iPhone screen height

-- Game state and managers
local player
local platforms = {}
local springboards = {}
local particleManager
local collisionManager
local world
local camera
local enemyManager
local powerUpManager
local transitionManager
local inputManager
local timeManager
local gameSpeed = 50  -- Initial upward game speed (slower for vertical game)
local score = 0
local gameOver = false
local distanceClimbed = 0
local startHeight = 0

-- Mouse/touch tracking variables
local isDragging = false

-- Game settings
local settingsVisible = true  -- Toggle for settings menu visibility
local slowDownWhileDragging = false  -- Option to slow time during drag
local pauseWhileDragging = true  -- Option to pause game during drag
local slowDownFactor = 0.3  -- Game runs at 30% speed when dragging

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
        local enemy = data.enemy
        local playerState = data.playerState
        
        -- Handle collision based on player state
        if playerState == "Dashing" then
            -- Player dashing into enemy - stun the enemy
            if enemy.state ~= "stunned" and enemy.stun then
                enemy:stun()
                data.result.enemyHit = true
                
                -- Fire enemy kill event with combo count
                Events.fire("enemyKill", {
                    comboCount = player.comboCount,
                    enemy = enemy
                })
                
                -- Refresh the player's dash
                player:refreshJumps() -- CORRECTED METHOD NAME
                
                -- Increment combo counter
                player:incrementCombo()
            end
        elseif enemy.state ~= "stunned" then
            -- Enemy hits player - player takes damage
            player:takeDamage()
            
            -- Reset combo when hit
            player:resetCombo()
            
            data.result.playerHit = true
        end
    end)
    -- Handle enemy kill events
    Events.on("enemyKill", function(data)
        local comboCount = data.comboCount or 0
        local enemy = data.enemy
        camera:onEnemyKill(data)
        timeManager:onEnemyKill(data)
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
    
    -- Debug state changes if debug mode is on
    if debugMode then
        Events.on("playerStateChanged", function(data)
            print("Player state changed from " .. (data.prevState or "nil") .. " to " .. data.newState)
        end)
    end
end

-- Load resources and initialize the game
function love.load()
    -- Set the window dimensions to match mobile resolution
    love.window.setMode(MOBILE_WIDTH, MOBILE_HEIGHT)

    -- Set the window title
    love.window.setTitle("Love2D Vertical Jumper")

    -- Set default background color
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)

    -- Initialize particle manager
    particleManager = ParticleManager:new()

    -- Initialize world generator
    world = World:new()

    -- Generate initial platforms
    world:generateInitialPlatforms(platforms, springboards)

    -- Initialize player
    player = Player:new()

    -- Initialize Time Manager
    timeManager = TimeManager:new()

    transitionManager = TransitionManager:new()

    inputManager = InputManager:new() -- Initialize the new InputManager

    -- Initialize enemy manager (with platforms reference)
    enemyManager = EnemyManager:new()
    enemyManager:generateInitialEnemies(platforms) -- Pass platforms here

    -- Initialize camera
    camera = Camera:new(player)
    startHeight = player.y

    powerUpManager = PowerUpManager:new()

    -- Initialize collision manager
    collisionManager = CollisionManager:new(player, platforms, springboards, particleManager)
    setupEventListeners()
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
            particleManager:update(0)
            
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

    -- Update camera position
    camera:update(dt, player, gameSpeed)

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
    
    
    transitionManager:update(dt)

    -- Update enemies
    enemyManager:update(dt, player, camera)

    powerUpManager:update(dt, player, camera)
    local powerUpMessage = powerUpManager:handleCollisions(player)
    powerUpManager:cleanupPowerUps(camera)

    -- Handle enemy collisions and get combo info
    local enemyHit = enemyManager:handleCollisions(player, particleManager)
    
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
    collisionManager:handleCollisions(dt)

    -- Update springboards
    for _, spring in ipairs(springboards) do
        spring:update(dt)
    end

    -- Update particle systems
    particleManager:update(dt)

    -- Clean up platforms that are below the view
    world:cleanupPlatforms(camera, platforms, springboards)

    -- Game over if player falls below camera view
    if player.y > camera.y + MOBILE_HEIGHT then
        gameOver = true
    end
end

function transitionToGameOver()
    transitionManager:startTransition("fade", 0.5, "out", function()
        gameState = "gameover"
        -- Additional game over setup
    end)
end

-- Then call setupEventHandlers() in your love.load function
local function restartGame()
    -- Reset game state
    gameOver = false
    score = 0
    gameSpeed = 50
    distanceClimbed = 0

    -- Reset player
    player = Player:new()
    startHeight = player.y
    -- Clear all event listeners
    Events.clearAll()
    
    -- Initialize time manager again
    timeManager = TimeManager:new()
    
    -- Reset camera
    camera = Camera:new(player)

    -- Clear and regenerate platforms
    platforms = {}
    springboards = {}
    world:generateInitialPlatforms(platforms, springboards)
    -- Reset enemy manager
    enemyManager = EnemyManager:new()
    enemyManager:generateInitialEnemies()
    -- Update collision manager with new objects
    collisionManager = CollisionManager:new(player, platforms, springboards, particleManager)
    setupEventListeners()

end

-- Handle key presses
function love.keypressed(key)
    -- Forward key events to player
    player:keypressed(key, particleManager)

    -- Quit the game when escape is pressed
    if key == "escape" then
        love.event.quit()
    end

    -- Restart when R is pressed
    if key == "r" and gameOver then
        restartGame()
    end

    -- Toggle settings menu with S key
    if key == "s" then
        settingsVisible = not settingsVisible
    end
end

-- Mouse pressed (start drag)
function love.mousepressed(x, y, button)
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

    if button == 1 and not gameOver then -- Left mouse button
        inputManager:mousepressed(x, y, button, camera, player)
    end
end

-- Mouse moved (update drag)
function love.mousemoved(x, y)
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
    love.graphics.translate(0, -cameraPos.y + MOBILE_HEIGHT / 2 + cameraPos.x)

    -- Draw platforms
    for _, platform in ipairs(platforms) do
        platform:draw()
    end

    -- Draw springboards
    for _, spring in ipairs(springboards) do
        spring:draw()
    end

    enemyManager:draw()

    -- Draw all particle systems
    particleManager:draw()

    -- Draw the player
    player:draw()

    love.graphics.pop()

    -- Draw input visualizations (trajectory, etc.)
    inputManager:draw()

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

        -- Instructions
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Tap checkboxes to toggle options", 10, 210)
        love.graphics.print("Press 'S' to close settings", 10, 230)
    end

    if gameOver then
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("GAME OVER", 0, MOBILE_HEIGHT / 2 - 40, MOBILE_WIDTH, "center")
        love.graphics.printf("Press R to restart", 0, MOBILE_HEIGHT / 2, MOBILE_WIDTH, "center")
        love.graphics.printf("Final Score: " .. score, 0, MOBILE_HEIGHT / 2 + 40, MOBILE_WIDTH, "center")
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Click and drag to jump", 10, 50)
        love.graphics.print("Pull back and release to launch", 10, 70)
        love.graphics.print("Jump in air for double-jump", 10, 90)
    end
    transitionManager:draw()

end

