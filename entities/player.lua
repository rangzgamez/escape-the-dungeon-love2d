-- player.lua - Player class for Love2D Vertical Jumper (FSM version)
local Events = require("lib/events")
local StateMachine = require("states/stateMachine")
local GroundedState = require("states/groundedState")
local FallingState = require("states/fallingState")
local DashingState = require("states/dashingState")

local Player = {}
Player.__index = Player

function Player:new(x, y)
    local self = setmetatable({}, Player)
    
    -- Position and dimensions (smaller for mobile screens)
    self.x = x or love.graphics.getWidth() / 2 - 12  -- Center horizontally
    self.y = y or love.graphics.getHeight() - 100    -- Start near bottom
    self.width = 24  -- Smaller for mobile
    self.height = 48 -- Smaller for mobile
    
    -- Movement
    self.xVelocity = 0
    self.yVelocity = 0
    self.horizontalSpeed = 300
    
    -- Dash properties
    self.dashSpeed = 1500 -- Much faster dash
    self.minDashDuration = 0.001 -- Minimum dash time
    self.maxDashDuration = 0.2 -- Maximum dash time
    self.dashTimeLeft = 0 -- Current dash timer
    self.dashDirection = {x = 0, y = 0} -- Direction of current dash
    self.gravityAfterDash = 1800 -- Stronger gravity after dash ends
    self.gravity = 1800 -- Default gravity
    
    -- Original jump mechanics (keeping for reference)
    self.jumpStrength = 600
    self.springJumpStrength = 1000
    
    -- State tracking (for FSM reference/compatibility)
    self.onGround = false
    
    -- Midair jumps system
    self.maxMidairJumps = 1  -- Default: one midair jump (can be increased by powerups)
    self.midairJumps = self.maxMidairJumps  -- Current available midair jumps
    
    -- Trajectory preview
    self.trajectoryPoints = {}
    self.trajectoryPointCount = 20  -- Number of points to calculate for trajectory
    self.trajectoryTimeStep = 0.1   -- Time between trajectory points
    
    -- Player damage
    self.health = 3 -- Player health
    self.invulnerableTime = 0 -- Invulnerability timer
    self.invulnerableDuration = 1.5 -- Time invulnerable after taking damage
    self.isInvulnerable = false -- Invulnerability flag
    self.damageFlashTimer = 0 -- For damage flash effect
    
    -- After-image effect for dashing
    self.afterImagePositions = {} -- Initialize this array at creation
    
    -- Combo system
    self.comboCount = 0
    self.lastComboY = 0 -- Track Y position for combo
    
    -- Combo display variables
    self.comboText = nil -- Text to display
    self.comboTimer = 0 -- Timer for combo text display
    self.comboMaxTime = 2 -- How long to show combo text
    self.comboScale = 1 -- Size scaling for animation
    self.comboAngle = 0 -- Rotation angle for animation
    self.comboX = 0 -- X position for text
    self.comboY = 0 -- Y position for text
    self.comboOffsetX = 0 -- Animation offset X
    self.comboOffsetY = 0 -- Animation offset Y
    
    -- Affirmation text variables
    self.affirmationText = nil -- Random affirmation to display
    self.affirmationTimer = 0
    self.affirmationScale = 1
    self.affirmationAngle = 0
    self.affirmationX = 0
    self.affirmationY = 0
    self.affirmationOffsetX = 0
    self.affirmationOffsetY = 0

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
    
    -- Start in the grounded state (on ground)
    self.stateMachine:change("Falling")

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
    
    -- Update combo text animations (common across all states)
    self:updateComboAnimations(dt)
end

function Player:deductJump()
    self.midairJumps = self.midairJumps - 1
    return self.midairJumps
end

function Player:enemyCollision(data)
    -- Handle collision based on player state
    local enemy = data.enemy
    self.stateMachine:getCurrentState():enemyCollision(enemy)
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
        
        -- Draw combo text (common across all states)
        self:drawComboText()
    end
end

-- For collision detection
function Player:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
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

-- Increase combo counter
function Player:incrementCombo()
    -- Increase combo counter
    self.comboCount = self.comboCount + 1
    
    -- Set up combo text display
    self.comboText = self.comboCount .. "X"  -- Simple counter
    self.comboTimer = self.comboMaxTime
    self.comboScale = 1.0  -- No scaling for regular counter
    self.comboAngle = 0    -- No rotation for regular counter
    
    -- Position the combo text directly above the player's head
    self.comboX = self.x + self.width/2
    self.comboY = self.y - 60
    
    -- No offset for the counter display - keep it steady
    self.comboOffsetX = 0
    self.comboOffsetY = 0
    
    -- Only show affirmation when reaching 5 or higher
    if self.comboCount == 5 then
        self:showComboAffirmation(true)  -- true indicates this is the first time reaching 5
    end
end

-- Show combo affirmation
function Player:showComboAffirmation(isFirstThreshold)
    -- Only show affirmation for combos of 5 or higher
    if self.comboCount < 5 then
        return
    end
    
    -- Add a random affirmation
    local affirmations = {
        "Nice!",
        "Awesome!",
        "Great!",
        "Wow!",
        "Amazing!",
        "Killer!",
        "Fantastic!",
        "Sweet!",
        "Boom!",
        "Unstoppable!"
    }
    
    -- Different text for first time reaching 5
    local displayText
    if isFirstThreshold then
        displayText = "COMBO STARTED! " .. affirmations[1]
    else
        -- Higher combo = stronger affirmations
        local affirmationIndex = math.min(math.floor((self.comboCount - 5) / 3) + 2, #affirmations)
        displayText = self.comboCount .. "X COMBO! " .. affirmations[affirmationIndex]
    end
    
    self.affirmationText = displayText
    
    -- Position affirmation text slightly above combo text
    self.affirmationX = self.x + self.width/2
    self.affirmationY = self.y - 90
    self.affirmationTimer = self.comboMaxTime
    self.affirmationScale = 1.5  -- Larger initial scale for pop effect
    self.affirmationAngle = love.math.random(-15, 15) * 0.01
    self.affirmationOffsetX = love.math.random(-15, 15)
    self.affirmationOffsetY = -love.math.random(10, 20)
    
    -- Make affirmation effects more dramatic for higher combos
    if self.comboCount >= 8 then
        -- Bigger scale and movement for higher combos
        self.affirmationScale = self.affirmationScale + ((self.comboCount - 5) * 0.1)
        self.affirmationOffsetX = self.affirmationOffsetX * (1 + (self.comboCount - 5) * 0.1)
        self.affirmationOffsetY = self.affirmationOffsetY * (1 + (self.comboCount - 5) * 0.1)
    end
end

-- Reset combo
function Player:resetCombo()
    -- Store the combo count before resetting it
    local oldComboCount = self.comboCount
    
    -- Only show an affirmation if we had a significant combo
    if oldComboCount >= 5 then
        -- Show the combo text with animation as it's ending
        self.comboText = oldComboCount .. "X COMBO!"
        self.comboTimer = self.comboMaxTime
        
        -- Position the combo text directly above the player's head
        self.comboX = self.x + self.width/2
        self.comboY = self.y - 60
        
        -- Add subtle animation
        self.comboOffsetX = 0
        self.comboOffsetY = 0
        
        -- Create an affirmation message for ending the combo
        self.affirmationText = "Combo Ended!"
        
        -- Position affirmation text above combo text
        self.affirmationX = self.x + self.width/2
        self.affirmationY = self.y - 90
        self.affirmationTimer = self.comboMaxTime
        self.affirmationOffsetX = 0
        self.affirmationOffsetY = 0
    else
        -- For minor combos, just clear the display with no animation
        self.comboText = nil
        self.comboTimer = 0
        self.affirmationText = nil
        self.affirmationTimer = 0
    end
    
    -- Now reset the combo count
    self.comboCount = 0
end

-- Update combo animations
function Player:updateComboAnimations(dt)
    -- Update combo text animation
    if self.comboText and self.comboTimer > 0 then
        -- Update timer
        self.comboTimer = self.comboTimer - dt
        
        -- Only animate when combo is reset/ending
        if self.comboCount == 0 then
            -- Subtle left-right movement
            self.comboOffsetX = 5 * math.sin(self.comboTimer * 8)
            
            -- Subtle rotation
            self.comboAngle = 0.05 * math.sin(self.comboTimer * 10)
            
            -- Gradual upward drift
            self.comboOffsetY = self.comboOffsetY - 15 * dt
        else
            -- Static position for active combo counter
            self.comboAngle = 0
            self.comboOffsetX = 0
            -- No vertical animation for active combo counter
        end
        
        -- Fade out when close to expiring
        if self.comboTimer <= 0 then
            self.comboText = nil
        end
    end
    
    -- Update affirmation text animation
    if self.affirmationText and self.affirmationTimer > 0 then
        -- Update timer
        self.affirmationTimer = self.affirmationTimer - dt
        
        -- Simple left-right movement
        self.affirmationOffsetX = 8 * math.sin(self.affirmationTimer * 6)
        
        -- Simple rotation
        self.affirmationAngle = 0.08 * math.sin(self.affirmationTimer * 8)
        
        -- Steady upward movement
        self.affirmationOffsetY = self.affirmationOffsetY - 25 * dt
        
        -- Fade out when close to expiring
        if self.affirmationTimer <= 0 then
            self.affirmationText = nil
        end
    end
    
    -- Update player position to keep combo text above head
    if self.comboText and self.comboTimer > 0 then
        -- Update combo text position to follow player (but keep animation offsets)
        self.comboX = self.x + self.width/2
        self.comboY = self.y - 60
    end
    
    if self.affirmationText and self.affirmationTimer > 0 then
        -- Update affirmation position to follow player (but keep animation offsets)
        self.affirmationX = self.x + self.width/2
        self.affirmationY = self.y - 90
    end
end

-- Draw combo text
function Player:drawComboText()
    -- Draw combo text with simpler effects if active
    if self.comboText and self.comboTimer > 0 then
        -- Calculate opacity based on remaining time
        local opacity = math.min(1, self.comboTimer / (self.comboMaxTime * 0.5))
        
        -- Get text width for centering
        local textWidth = love.graphics.getFont():getWidth(self.comboText)
        
        -- Calculate display position (centered on player)
        local displayX = self.comboX + self.comboOffsetX - textWidth/2
        local displayY = self.comboY + self.comboOffsetY
        
        -- Save current transform state
        love.graphics.push()
        
        -- Apply rotation from center point - simpler transformation
        love.graphics.translate(displayX + textWidth/2, displayY)
        love.graphics.rotate(self.comboAngle)
        
        -- Just a single shadow for active combo counter
        if self.comboCount > 0 then
            -- Simple display for active combo
            love.graphics.setColor(0.5, 0.5, 0.5, opacity * 0.7)
            love.graphics.print(self.comboText, -textWidth/2 + 1, 1)
            
            -- Main text - neutral color for active combo
            love.graphics.setColor(1, 1, 1, opacity)
            love.graphics.print(self.comboText, -textWidth/2, 0)
        else
            -- More visible styling for ended combo animation
            -- Shadow
            love.graphics.setColor(0.6, 0.2, 0.2, opacity * 0.7)
            love.graphics.print(self.comboText, -textWidth/2 + 2, 2)
            
            -- Main text - red tint for ended combo
            love.graphics.setColor(1, 0.4, 0.4, opacity)
            love.graphics.print(self.comboText, -textWidth/2, 0)
        end
        
        -- Restore transform state
        love.graphics.pop()
    end
    
    -- Draw affirmation text with simplified effect if active
    if self.affirmationText and self.affirmationTimer > 0 then
        -- Calculate opacity based on remaining time
        local opacity = math.min(1, self.affirmationTimer / (self.comboMaxTime * 0.5))
        
        -- Get text width for centering
        local textWidth = love.graphics.getFont():getWidth(self.affirmationText)
        
        -- Calculate display position (centered on player)
        local displayX = self.affirmationX + self.affirmationOffsetX - textWidth/2
        local displayY = self.affirmationY + self.affirmationOffsetY
        
        -- Save current transform state
        love.graphics.push()
        
        -- Apply rotation from center point
        love.graphics.translate(displayX + textWidth/2, displayY)
        love.graphics.rotate(self.affirmationAngle)
        
        -- Draw shadow layer
        love.graphics.setColor(0.7, 0.2, 0.2, opacity * 0.7)
        love.graphics.print(self.affirmationText, -textWidth/2 + 2, 2)
        
        -- Draw main text
        love.graphics.setColor(1, 0.6, 0.6, opacity)
        love.graphics.print(self.affirmationText, -textWidth/2, 0)
        
        -- Restore transform state
        love.graphics.pop()
    end
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

-- Level up method
function Player:levelUp()
    -- Increase level
    self.level = self.level + 1
    
    -- Flag that a level-up menu should be shown
    self.levelUpPending = true
    
    -- Reset experience counter and increase requirement for next level
    self.experience = self.experience - self.xpToNextLevel
    self.xpToNextLevel = math.floor(self.xpToNextLevel * 1.5) -- 50% more XP needed for next level
    
    -- Fire level up event
    Events.fire("playerLevelUp", {
        player = self,
        newLevel = self.level
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
        
    elseif type == "SPEED" then
        -- Increase movement speed
        self.horizontalSpeed = self.horizontalSpeed * 1.15
        
    elseif type == "SHIELD" then
        -- Add or refresh shield
        self.shieldActive = true
        self.shieldHealth = self.powerupLevels[type] -- Shield health scales with level
        
    elseif type == "COMBO_DURATION" then
        -- Increase combo timer duration
        self.comboMaxTime = self.comboMaxTime + 1 -- +1 second per level
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