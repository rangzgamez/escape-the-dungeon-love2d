-- PlayerECS.lua
-- ECS version of player

local Events = require("lib/events")
local StateMachine = require("states/stateMachine")
local GroundedState = require("states/groundedState")
local FallingState = require("states/fallingState")
local DashingState = require("states/dashingState")
local ECSEntity = require("entities/ecsEntity")

-- Create the PlayerECS class with proper inheritance
local PlayerECS = {}
PlayerECS.__index = PlayerECS
setmetatable(PlayerECS, {__index = ECSEntity})

function PlayerECS.new(x, y)
    -- Create options for the player
    local options = {
        type = "player",
        collisionLayer = "player",
        collidesWithLayers = {"solid", "enemy", "collectible", "springboard"}, -- Collide with these layers
        isSolid = true, -- Solid entity
        color = {0, 0.7, 0, 1}, -- Green for player
        affectedByGravity = true -- Player is affected by gravity
    }
    
    -- Create the entity using ECSEntity constructor
    local player = ECSEntity.new(x, y, 32, 48, options)
    
    -- Set up PlayerECS metatable
    setmetatable(player, {__index = PlayerECS})
    
    -- Player-specific properties
    player.health = 100
    player.maxHealth = 100
    player.xp = 0
    player.level = 1
    player.speed = 200
    player.jumpForce = 500
    player.maxJumps = 2
    player.jumpsRemaining = player.maxJumps
    player.dashForce = 500
    player.dashSpeed = 800 -- Add dash speed property
    player.dashCooldown = 1
    player.dashTimer = 0
    player.gravity = 980 -- Add gravity property
    player.invulnerable = false
    player.invulnerabilityTimer = 0
    player.invulnerabilityDuration = 1.5
    player.magnetActive = false
    player.magnetTimer = 0
    player.magnetDuration = 10
    
    -- Add dash duration properties
    player.minDashDuration = 0.001 -- Minimum dash time
    player.maxDashDuration = 0.2 -- Maximum dash time
    
    -- Add components to ECS entity
    if player.ecsEntity then
        -- Add player component
        player.ecsEntity:addComponent("player", {
            health = player.health,
            maxHealth = player.maxHealth,
            xp = player.xp,
            level = player.level,
            jumpsRemaining = player.jumpsRemaining,
            maxJumps = player.maxJumps,
            invulnerable = player.invulnerable,
            magnetActive = player.magnetActive
        })
        
        -- Add movement component
        player.ecsEntity:addComponent("movement", {
            speed = player.speed,
            jumpForce = player.jumpForce,
            dashForce = player.dashForce,
            dashSpeed = player.dashSpeed,
            dashCooldown = player.dashCooldown,
            dashTimer = player.dashTimer,
            minDashDuration = player.minDashDuration,
            maxDashDuration = player.maxDashDuration,
            dashDuration = 0.2, -- Default dash duration
            gravity = player.gravity,
            isGrounded = true,
            velocityX = 0,
            velocityY = 0,
            isDashing = false,
            dashDirection = {x = 0, y = 0}
        })
    end
    
    -- Initialize state machine
    player.stateMachine = StateMachine:new()
    
    -- Create and add states - make sure to pass the player instance
    player.stateMachine:add("grounded", GroundedState:new(player))
    player.stateMachine:add("falling", FallingState:new(player))
    player.stateMachine:add("dashing", DashingState:new(player))
    
    -- Set initial state
    player.stateMachine:change("grounded")
    
    return player
end

function PlayerECS:update(dt)
    -- Call parent update method to update ECS entity
    ECSEntity.update(self, dt)
    
    -- Update the current state
    self.stateMachine:getCurrentState():update(dt)
    
    -- Update invulnerability timer (common across all states)
    if self.ecsEntity then
        local playerComponent = self.ecsEntity:getComponent("player")
        if playerComponent.isInvulnerable then
            playerComponent.invulnerabilityTimer = playerComponent.invulnerabilityTimer - dt
            
            if playerComponent.invulnerabilityTimer <= 0 then
                playerComponent.isInvulnerable = false
            end
        end
        
        -- Update combo text animations
        self:updateComboAnimations(dt)
        
        -- Update movement based on state machine
        local movementComponent = self.ecsEntity:getComponent("movement")
        
        -- Apply gravity if not dashing and not grounded
        if not movementComponent.isDashing and not movementComponent.isGrounded then
            movementComponent.velocityY = movementComponent.velocityY + movementComponent.gravity * dt
        end
        
        -- Update position based on velocity
        self:setPosition(self.x + movementComponent.velocityX * dt, self.y + movementComponent.velocityY * dt)
    end
end

function PlayerECS:draw()
    -- Check for invulnerability flicker
    if self.ecsEntity then
        local playerComponent = self.ecsEntity:getComponent("player")
        local shouldDraw = true
        if playerComponent.isInvulnerable then
            -- Flash effect - visible every other 0.1 seconds
            shouldDraw = playerComponent.invulnerabilityTimer > 0.05
        end
        
        if shouldDraw then
            -- Let the current state handle drawing
            self.stateMachine:getCurrentState():draw()
        end
    else
        -- Default drawing if no ECS entity
        love.graphics.setColor(0.2, 0.6, 1, 1) -- Blue player
        if self.x and self.y and self.width and self.height then
            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        end
    end
    
    -- Draw debug info
    if self.debug then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("State: " .. self.stateMachine.current:getName(), self.x, self.y - 60)
        
        -- Draw collision bounds
        local bounds = self:getBounds()
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

function PlayerECS:onDragEnd(data)
    -- Only perform action if the drag was significant
    if data.isSignificantDrag then
        -- Handle the jump/dash based on current state
        self.stateMachine.current:onDragEnd(data)
    end
end

-- Handle collision response for the player
function PlayerECS:onCollision(other, collisionData)
    -- Call parent onCollision to fire events
    ECSEntity.onCollision(self, other, collisionData)
    
    -- Get the type of the other entity
    local otherType = other.type
    
    -- Debug output
    -- print("Player collision with " .. otherType)
    
    -- Determine if collision is from above
    local fromAbove = false
    if collisionData and collisionData.normal then
        fromAbove = collisionData.normal.y < 0
    end
    
    -- Handle collision based on the other entity type
    if otherType == "platform" or otherType == "movingPlatform" then
        -- Handle platform collision
        if fromAbove and self.ecsEntity then
            local movementComponent = self.ecsEntity:getComponent("movement")
            if movementComponent then
                -- Land on platform
                movementComponent.isGrounded = true
                movementComponent.velocityY = 0
                
                -- Refresh jumps
                movementComponent.midairJumps = movementComponent.maxMidairJumps
                
                -- Change to grounded state if falling
                if self.stateMachine:getCurrentState().name == "falling" then
                    self.stateMachine:change("grounded")
                end
            end
        end
    elseif otherType == "springboard" then
        -- Handle springboard collision
        if fromAbove and self.ecsEntity then
            local movementComponent = self.ecsEntity:getComponent("movement")
            if movementComponent then
                -- Apply springboard boost
                movementComponent.velocityY = -1200 -- Strong upward boost
                
                -- Change to falling state
                self.stateMachine:change("falling")
                
                -- Fire jump event
                Events.fire("playerJump", {
                    x = self.x + self.width/2,
                    y = self.y + self.height/2,
                    isSpringboardJump = true
                })
            end
        end
    elseif otherType == "enemy" or otherType == "slime" then
        -- Handle enemy collision
        if not self.ecsEntity then return end
        
        local playerComponent = self.ecsEntity:getComponent("player")
        if not playerComponent then return end
        
        -- Check if player is invulnerable
        if playerComponent.isInvulnerable then
            return
        end
        
        -- Check if player is dashing (can damage enemies while dashing)
        local movementComponent = self.ecsEntity:getComponent("movement")
        if movementComponent and movementComponent.isDashing then
            -- Damage the enemy instead
            if other.takeDamage then
                other:takeDamage(1)
            end
            return
        end
        
        -- Take damage from enemy
        self:takeDamage(1)
    elseif otherType == "collectible" or otherType == "xpPellet" then
        -- Handle collectible collision
        if other.collectible and other.value then
            -- Add experience
            self:addExperience(other.value)
            
            -- Deactivate the collectible
            other.active = false
        end
    end
    
    return true
end

-- Set the player's position and update the ECS entity
function PlayerECS:setPosition(x, y)
    -- Update the entity's position
    self.x = x
    self.y = y
    
    -- Update the ECS entity's transform component
    if self.ecsEntity then
        local transform = self.ecsEntity:getComponent("transform")
        if transform and transform.position then
            transform.position.x = x
            transform.position.y = y
        end
    end
end

-- Check if player is out of horizontal bounds and wrap around
function PlayerECS:checkHorizontalBounds(screenWidth)
    if self.x < -self.width then
        self:setPosition(screenWidth, self.y)
    elseif self.x > screenWidth then
        self:setPosition(-self.width, self.y)
    end
end

function PlayerECS:jump()
    local movementComponent = self.ecsEntity:getComponent("movement")
    
    -- Apply jump velocity
    movementComponent.velocityY = -movementComponent.jumpForce
    
    -- Change to falling state
    self.stateMachine:change("falling")
    
    -- Fire jump event
    Events.fire("playerJump", {
        x = self.x + self.width/2,
        y = self.y + self.height
    })
end

function PlayerECS:midairJump()
    local movementComponent = self.ecsEntity:getComponent("movement")
    
    -- Check if we have midair jumps left
    if movementComponent.midairJumps > 0 then
        -- Deduct a midair jump
        movementComponent.midairJumps = movementComponent.midairJumps - 1
        
        -- Apply jump velocity
        movementComponent.velocityY = -movementComponent.jumpForce * 0.8
        
        -- Fire midair jump event
        Events.fire("playerMidairJump", {
            x = self.x + self.width/2,
            y = self.y + self.height
        })
        
        return true
    end
    
    return false
end

function PlayerECS:dash(direction)
    local movementComponent = self.ecsEntity:getComponent("movement")
    
    -- Set dash properties
    movementComponent.isDashing = true
    movementComponent.dashDirection = {
        x = direction.x,
        y = direction.y
    }
    
    -- Calculate dash duration based on power (using 1.0 as default power)
    local power = 1.0
    movementComponent.dashDuration = movementComponent.minDashDuration + power * (movementComponent.maxDashDuration - movementComponent.minDashDuration)
    movementComponent.dashTimer = movementComponent.dashDuration
    
    -- Set velocity based on dash direction
    movementComponent.velocityX = direction.x * movementComponent.dashSpeed
    movementComponent.velocityY = direction.y * movementComponent.dashSpeed
    
    -- Change to dashing state with dash data
    self.stateMachine:change("dashing", {
        direction = direction,
        power = power
    })
    
    -- Fire dash event
    Events.fire("playerDash", {
        x = self.x + self.width/2,
        y = self.y + self.height/2,
        direction = direction
    })
end

function PlayerECS:takeDamage(amount)
    local playerComponent = self.ecsEntity:getComponent("player")
    
    -- Check if player is invulnerable
    if playerComponent.isInvulnerable then
        return false
    end
    
    -- Apply damage
    playerComponent.health = playerComponent.health - (amount or 1)
    
    -- Make player invulnerable
    playerComponent.isInvulnerable = true
    playerComponent.invulnerabilityTimer = playerComponent.invulnerabilityDuration
    
    -- Fire damage event
    Events.fire("playerDamage", {
        x = self.x + self.width/2,
        y = self.y + self.height/2,
        health = playerComponent.health
    })
    
    -- Check if player is dead
    if playerComponent.health <= 0 then
        self:die()
    end
    
    return true
end

function PlayerECS:die()
    -- Fire death event
    Events.fire("playerDeath", {
        x = self.x + self.width/2,
        y = self.y + self.height/2
    })
    
    -- Mark as inactive
    self.active = false
end

function PlayerECS:addExperience(amount)
    local playerComponent = self.ecsEntity:getComponent("player")
    
    -- Add experience
    playerComponent.xp = playerComponent.xp + amount
    
    -- Check for level up
    if playerComponent.xp >= playerComponent.xpToNextLevel then
        playerComponent.level = playerComponent.level + 1
        playerComponent.xp = playerComponent.xp - playerComponent.xpToNextLevel
        playerComponent.xpToNextLevel = math.floor(playerComponent.xpToNextLevel * 1.5) -- Increase XP needed for next level
        
        -- Fire level up event
        Events.fire("playerLevelUp", {
            level = playerComponent.level
        })
    end
    
    -- Fire XP gain event
    Events.fire("playerXpGain", {
        amount = amount,
        total = playerComponent.xp,
        nextLevel = playerComponent.xpToNextLevel
    })
    
    -- Show XP popup
    self:showXpPopup(amount)
end

function PlayerECS:showXpPopup(amount)
    local visualEffects = self.ecsEntity:getComponent("visualEffects")
    
    visualEffects.xpPopupText = "+" .. amount .. " XP"
    visualEffects.xpPopupTimer = 1.5
    visualEffects.xpPopupX = self.x + self.width/2
    visualEffects.xpPopupY = self.y - 20
    visualEffects.xpPopupScale = 1.5
end

-- Draw XP popup text
function PlayerECS:drawXpPopup()
    if not self.ecsEntity then return end
    
    local visualEffects = self.ecsEntity:getComponent("visualEffects")
    if not visualEffects then return end
    
    -- Draw XP popup if active
    if visualEffects.xpPopupText and visualEffects.xpPopupTimer > 0 then
        -- Calculate alpha based on remaining time
        local alpha = math.min(1, visualEffects.xpPopupTimer)
        
        -- Set color with alpha
        love.graphics.setColor(0.2, 0.8, 1, alpha)
        
        -- Draw text with scaling
        love.graphics.push()
        love.graphics.translate(visualEffects.xpPopupX, visualEffects.xpPopupY)
        love.graphics.scale(visualEffects.xpPopupScale, visualEffects.xpPopupScale)
        love.graphics.print(visualEffects.xpPopupText, -30, 0)
        love.graphics.pop()
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function PlayerECS:updateComboAnimations(dt)
    -- Check if the entity exists and has the visualEffects component
    if not self.ecsEntity then
        return
    end
    
    local visualEffects = self.ecsEntity:getComponent("visualEffects")
    if not visualEffects then
        -- Add the visualEffects component if it doesn't exist
        self.ecsEntity:addComponent("visualEffects", {
            comboText = nil,
            comboTimer = 0,
            comboScale = 1,
            comboAngle = 0,
            xpPopupText = nil,
            xpPopupTimer = 0,
            xpPopupX = self.x + self.width/2,
            xpPopupY = self.y - 20,
            xpPopupScale = 1
        })
        visualEffects = self.ecsEntity:getComponent("visualEffects")
    end
    
    -- Update combo text animation
    if visualEffects.comboText then
        visualEffects.comboTimer = visualEffects.comboTimer - dt
        
        -- Animate the combo text
        visualEffects.comboScale = 1 + math.sin(visualEffects.comboTimer * 10) * 0.2
        visualEffects.comboAngle = math.sin(visualEffects.comboTimer * 5) * 0.1
        
        -- Fade out at the end
        if visualEffects.comboTimer <= 0.5 then
            visualEffects.comboScale = visualEffects.comboScale * (visualEffects.comboTimer / 0.5)
        end
        
        -- Remove when timer expires
        if visualEffects.comboTimer <= 0 then
            visualEffects.comboText = nil
        end
    end
    
    -- Update XP popup animation
    if visualEffects.xpPopupText then
        visualEffects.xpPopupTimer = visualEffects.xpPopupTimer - dt
        
        -- Move the popup upward
        visualEffects.xpPopupY = visualEffects.xpPopupY - 30 * dt
        
        -- Scale down over time
        visualEffects.xpPopupScale = 1.5 - (1.5 - 0.8) * (1 - visualEffects.xpPopupTimer / 1.5)
        
        if visualEffects.xpPopupTimer <= 0 then
            visualEffects.xpPopupText = nil
        end
    end
end

function PlayerECS:refreshJumps()
    local movementComponent = self.ecsEntity:getComponent("movement")
    movementComponent.midairJumps = movementComponent.maxMidairJumps
end

-- Add keyboard input handling methods
function PlayerECS:keypressed(key)
    local movementComponent = self.ecsEntity:getComponent("movement")
    
    if key == "space" or key == "w" or key == "up" then
        -- Jump logic
        if movementComponent.isGrounded then
            -- Regular jump
            movementComponent.velocity.y = -movementComponent.jumpForce
            movementComponent.isGrounded = false
            Events.fire("playerJump", {x = self.x, y = self.y})
        elseif movementComponent.midairJumps > 0 then
            -- Midair jump
            movementComponent.velocity.y = -movementComponent.jumpForce * 0.8
            movementComponent.midairJumps = movementComponent.midairJumps - 1
            Events.fire("playerMidairJump", {x = self.x, y = self.y})
        end
    elseif key == "lshift" or key == "rshift" then
        -- Dash logic
        if not movementComponent.isDashing and movementComponent.canDash then
            local direction = {x = 0, y = 0}
            
            -- Determine dash direction based on movement keys
            if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
                direction.x = -1
            elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
                direction.x = 1
            end
            
            if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
                direction.y = -1
            elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
                direction.y = 1
            end
            
            -- If no direction keys are pressed, dash horizontally based on facing
            if direction.x == 0 and direction.y == 0 then
                direction.x = movementComponent.facingDirection
            end
            
            -- Normalize direction
            local length = math.sqrt(direction.x * direction.x + direction.y * direction.y)
            if length > 0 then
                direction.x = direction.x / length
                direction.y = direction.y / length
            else
                direction.x = movementComponent.facingDirection
                direction.y = 0
            end
            
            -- Apply dash
            movementComponent.isDashing = true
            movementComponent.dashDirection = direction
            movementComponent.dashTimer = movementComponent.dashDuration
            movementComponent.canDash = false
            
            -- Fire event
            Events.fire("playerDash", {direction = direction})
        end
    end
end

function PlayerECS:keyreleased(key)
    -- Handle key releases if needed
end

-- Destroy the player
function PlayerECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to player
    self.active = false
end

return PlayerECS
