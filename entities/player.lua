-- player.lua - Player class for Love2D Vertical Jumper (FSM version)
local Events = require("lib/events")
local StateMachine = require("states/stateMachine")
local GroundedState = require("states/groundedState")
local FallingState = require("states/fallingState")
local DashingState = require("states/dashingState")
local BaseEntity = require("entities/baseEntity")
local LevelUpState = require("states/levelUpState")

local Player = setmetatable({}, {__index = BaseEntity})
Player.__index = Player

function Player:new(x, y)
    -- Create with player-specific options
    local self = BaseEntity.new(self, x, y, 24, 48, {
        type = "player",
        collisionLayer = "player",
        collidesWithLayers = {"platform", "enemy", "powerup", "collectible"}
    })
    self.gravity = 1800
    -- Dash properties
    self.dashSpeed = 1500 -- Much faster dash
    self.minDashDuration = 0.001 -- Minimum dash time
    self.maxDashDuration = 0.2 -- Maximum dash time

    -- Midair jumps system
    self.maxMidairJumps = 1  -- Default: one midair jump (can be increased by powerups)
    self.midairJumps = self.maxMidairJumps  -- Current available midair jumps

    -- Player damage
    self.health = 3 -- Player health
    self.invulnerableTime = 0 -- Invulnerability timer
    self.invulnerableDuration = 1.5 -- Time invulnerable after taking damage
    self.isInvulnerable = false -- Invulnerability flag
    self.damageFlashTimer = 0 -- For damage flash effect

    -- After-image effect for dashing
    self.afterImagePositions = {} -- Initialize this array at creation

    -- Add these properties to Player:new() function
    self.experience = 0
    self.level = 1
    self.levelUpPending = false
    self.xpToNextLevel = 10 -- Base XP needed (will scale with level)
    self.powerups = {} -- Track active powerups
    self.powerupLevels = {} -- Track levels of each powerup

    -- XP text animation properties
    self.xpPopupText = nil
    self.xpPopupTimer = 0
    self.xpPopupX = 0
    self.xpPopupY = 0
    self.xpPopupScale = 1
    self.xpPopupColor = {0.2, 0.8, 1}

    -- Initialize the state machine
    self.stateMachine = StateMachine:new()
    
    -- Add states to the state machine
    self.stateMachine:add("Grounded", GroundedState:new(self))
    self.stateMachine:add("Falling", FallingState:new(self))
    self.stateMachine:add("Dashing", DashingState:new(self))
    self.stateMachine:add("LevelUp", LevelUpState:new(self))

    -- Start in the grounded state (on ground)
    self.stateMachine:change("Falling")
    setmetatable(self, Player)
    return self
end

function Player:onDragEnd(data)
    -- Only perform action if the drag was significant
    if data.isSignificantDrag then
        -- Handle the jump/dash based on current state
        self.stateMachine.current:onDragEnd(data)

    end
end


-- Main update function
function Player:update(dt)
    -- Update the current state
    self.stateMachine:getCurrentState():update(dt)
    
    -- Update invulnerability timer (common across all states)
    if self.isInvulnerable then
        self.invulnerableTime = self.invulnerableTime - dt
        self.damageFlashTimer = self.damageFlashTimer - dt
        
        if self.damageFlashTimer <= 0 then
            self.damageFlashTimer = 0.1 -- Flash every 0.1 seconds
        end
        
        if self.invulnerableTime <= 0 then
            self.isInvulnerable = false
        end
    end
    
end

function Player:deductJump()
    self.midairJumps = self.midairJumps - 1
    return self.midairJumps
end

-- function Player:enemyCollision(data)
--     -- Handle collision based on player state
--     local enemy = data.enemy
--     self.stateMachine:getCurrentState():enemyCollision(enemy)
-- end
-- Add this function to Player class to get color based on midair jumps
function Player:getJumpColor()
    -- Default color if calculations fail
    local defaultColor = {0.2, 0.6, 1}
    
    -- Safety check
    if not self.midairJumps or not self.maxMidairJumps then
        return defaultColor
    end
    
    -- Calculate color based on jumps remaining
    local jumpRatio = self.midairJumps / self.maxMidairJumps
    
    -- Color gradient from red (0 jumps) to yellow (half jumps) to green (full jumps)
    if jumpRatio <= 0 then
        -- No jumps - red
        return {1, 0.2, 0.2}
    elseif jumpRatio < 0.5 then
        -- Less than half - orange to yellow gradient
        local t = jumpRatio * 2 -- Scale to 0-1 range for the first half
        return {
            1,                  -- Red stays at 1
            0.2 + t * 0.8,      -- Green increases from 0.2 to 1
            0.2                 -- Blue stays low
        }
    else
        -- More than half - yellow to green gradient
        local t = (jumpRatio - 0.5) * 2 -- Scale to 0-1 range for the second half
        return {
            1 - t * 0.7,        -- Red decreases from 1 to 0.3
            1,                  -- Green stays at 1
            0.2 + t * 0.3       -- Blue increases slightly
        }
    end
end
-- Draw function
function Player:draw()
    love.graphics.print("State: " .. self.stateMachine.current:getName(), self.x, self.y-100)
    -- Check for invulnerability flicker
    local shouldDraw = true
    if self.isInvulnerable then
        -- Flash effect - visible every other 0.1 seconds
        shouldDraw = self.damageFlashTimer > 0.05
    end
    
    if shouldDraw then
        -- Let the current state handle drawing
        self.stateMachine:getCurrentState():draw()

    end
end

function Player:onCollision(other, collisionData)
    -- Let the current state handle collision if it wants to
    local state = self.stateMachine:getCurrentState()
    
    -- Default behavior for collisions based on entity type
    if other.type == "platform" then
        -- Only handle collision if coming from above and moving downward
        if self.velocity.y > 0 then  -- Player is moving downward
            local playerBottom = self.y + self.height
            local platformTop = other.y
            
            -- Check if player's bottom is close to platform's top
            if math.abs(playerBottom - platformTop) < 20 then  -- Increased threshold for better detection
                -- Snap to platform
                self.y = other.y - self.height
                self.velocity.y = 0
                self.onGround = true
                self:landOnGround()
                return true
            end
        end
    elseif other.type == "enemy" then
        local enemy = other
        self.stateMachine:getCurrentState():enemyCollision(enemy)
    elseif other.type == "xpPellet" then
        -- Handle XP collection
        if other.collectible then
            -- Get the XP value from the pellet
            local xpValue = other.value or 1
            
            -- Add the experience to the player
            self:addExperience(xpValue)
            
            -- The pellet will mark itself as inactive in its own onCollision method
            return true
        end
    end
    
    -- Let base class handle remaining cases
    return BaseEntity.onCollision(self, other, collisionData)
end

-- Handle damage
function Player:takeDamage()
    if not self.isInvulnerable then
        self.health = self.health - 1
        self.isInvulnerable = true
        self.invulnerableTime = self.invulnerableDuration
        self.damageFlashTimer = 0.1 -- Start damage flash effect
        
        -- Fire player hit event
        Events.fire("playerHit")
    end
end

function Player:canJump()
    return self.midairJumps > 0
end
function Player:refreshJumps()
    -- Reset midair jumps when refreshing dash ability (e.g., after killing an enemy)
    self.midairJumps = self.maxMidairJumps
    
    -- Fire an event for the dash refresh
    Events.fire("playerDashRefreshed", {
        x = self.x + self.width/2,
        y = self.y + self.height/2
    })
end

-- Check horizontal bounds (delegate to current state)
function Player:checkHorizontalBounds(screenWidth)
    self.stateMachine:getCurrentState():checkHorizontalBounds(screenWidth)
end

function Player:keypressed(key)
    self.stateMachine:getCurrentState():keypressed(key)
end

function Player:startDrag(x, y)
    -- Don't change state directly, let the current state decide
    local currentState = self.stateMachine:getCurrentState()
    currentState:onDragStart(x, y)
end

function Player:landOnGround()
    -- Let the current state decide what to do when landing
    local currentState = self.stateMachine:getCurrentState()
    currentState:onLandOnGround()
end

function Player:leftGround()
    -- Let the current state decide what to do when leaving the ground
    local currentState = self.stateMachine:getCurrentState()
    currentState:onLeftGround()
end

function Player:addExperience(amount)
    -- Add XP
    self.experience = self.experience + amount
    
    -- Show XP popup text
    if amount > 0 then
        self:showXpPopup(amount)
    end
    
    -- Check for level up
    if self.experience >= self.xpToNextLevel then
        self:levelUp()
    end
    
    -- Fire XP changed event
    Events.fire("playerXpChanged", {
        player = self,
        currentXp = self.experience,
        level = self.level,
        xpToNextLevel = self.xpToNextLevel
    })
    
    return amount
end

function Player:onLevelUpMenuHidden()
    self.stateMachine.current:onLevelUpMenuHidden()
end
-- Level up method
function Player:levelUp()
    -- Increase level
    self.level = self.level + 1
    
    -- Flag that a level-up menu should be shown
    self.levelUpPending = true
    
    -- Reset experience counter and increase requirement for next level
    self.experience = self.experience - self.xpToNextLevel
    self.xpToNextLevel = math.floor(self.xpToNextLevel * 1.5) -- 50% more XP needed for next level
    
    -- Fire level up event - other systems will handle showing the menu
    Events.fire("playerLevelUp", {
        player = self,
        newLevel = self.level,
        requiresMenu = true
    })
    
    -- If we still have enough XP for another level up, recursively level up again
    if self.experience >= self.xpToNextLevel then
        self:levelUp()
    end
end

-- Method to apply a powerup
function Player:applyPowerup(type)
    -- Initialize powerup level if not exists
    if not self.powerupLevels[type] then
        self.powerupLevels[type] = 0
        self.powerups[type] = true
    end
    
    -- Increment powerup level
    self.powerupLevels[type] = self.powerupLevels[type] + 1
    
    -- Apply effect based on type and level
    if type == "HEALTH_MAX" then
        -- Increase max health
        local prevMax = 3 + (self.powerupLevels[type] - 1)
        local newMax = 3 + self.powerupLevels[type]
        -- Also heal the player to the new maximum
        self.health = newMax
        
    elseif type == "DOUBLE_JUMP" then
        -- Increase max midair jumps
        self.maxMidairJumps = self.maxMidairJumps + 1
        self.midairJumps = self.maxMidairJumps -- Refresh jumps
        
    elseif type == "DASH_POWER" then
        -- Increase dash power/speed
        self.dashSpeed = self.dashSpeed * 1.2
        
    elseif type == "DASH_DURATION" then
        -- Increase maximum dash duration
        self.maxDashDuration = self.maxDashDuration * 1.2
        
    elseif type == "COLLECTION_RADIUS" then
        -- Increase XP collection radius (handled by XpManager)
        Events.fire("playerCollectionRadiusChanged", {
            player = self,
            bonus = self.powerupLevels[type] * 20 -- +20 per level
        })
        
    elseif type == "SHIELD" then
        -- Add or refresh shield
        self.shieldActive = true
        self.shieldHealth = self.powerupLevels[type] -- Shield health scales with level

    end
    
    -- Fire powerup applied event
    Events.fire("playerPowerupApplied", {
        player = self,
        type = type,
        level = self.powerupLevels[type]
    })
    
    return self.powerupLevels[type]
end

-- Method to show XP popup text
function Player:showXpPopup(amount)
    self.xpPopupText = "+" .. amount .. " XP"
    self.xpPopupTimer = 1.5 -- Duration in seconds
    self.xpPopupX = self.x + self.width/2
    self.xpPopupY = self.y - 20
    self.xpPopupScale = 1.5 -- Initial scale
    
    -- Fire XP popup event for sound effects
    Events.fire("xpPopup", {
        amount = amount,
        x = self.xpPopupX,
        y = self.xpPopupY
    })
end

-- Update XP popup animation (add to existing Player:update method)
-- Add this inside the Player:update method
function Player:updateXpPopup(dt)
    if self.xpPopupText and self.xpPopupTimer > 0 then
        -- Update timer
        self.xpPopupTimer = self.xpPopupTimer - dt
        
        -- Update position (float upward)
        self.xpPopupY = self.xpPopupY - 30 * dt
        
        -- Update scale (shrink slightly)
        self.xpPopupScale = math.max(1, self.xpPopupScale - 0.5 * dt)
        
        -- Clear when timer expires
        if self.xpPopupTimer <= 0 then
            self.xpPopupText = nil
        end
    end
end

-- Draw XP popup text (add to existing Player:draw method)
-- Add this at the end of the Player:draw method
function Player:drawXpPopup()
    if self.xpPopupText and self.xpPopupTimer > 0 then
        -- Calculate opacity based on remaining time
        local opacity = math.min(1, self.xpPopupTimer)
        
        -- Get text width for centering
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(self.xpPopupText)
        
        -- Draw shadow
        love.graphics.setColor(0, 0, 0, opacity * 0.5)
        love.graphics.print(
            self.xpPopupText, 
            self.xpPopupX - textWidth*self.xpPopupScale/2 + 2, 
            self.xpPopupY + 2, 
            0, 
            self.xpPopupScale, 
            self.xpPopupScale
        )
        
        -- Draw text
        love.graphics.setColor(self.xpPopupColor[1], self.xpPopupColor[2], self.xpPopupColor[3], opacity)
        love.graphics.print(
            self.xpPopupText, 
            self.xpPopupX - textWidth*self.xpPopupScale/2, 
            self.xpPopupY, 
            0, 
            self.xpPopupScale, 
            self.xpPopupScale
        )
    end
end
return Player