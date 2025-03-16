-- states/levelUpState.lua - LevelUp state for the player
-- Player enters this state after leveling up and selecting an upgrade
-- Game is paused in this state until player performs a dash to continue

local BaseState = require("states/baseState")
local Events = require("lib/events")

local LevelUpState = setmetatable({}, BaseState)
LevelUpState.__index = LevelUpState

function LevelUpState:new(player)
    local self = BaseState.new(self, player)
    
    -- Visual effect properties
    self.glowTimer = 0
    self.glowIntensity = 0
    self.glowDirection = 1 -- 1 for increasing, -1 for decreasing
    
    -- Text message
    self.message = "DASH TO CONTINUE!"
    self.messageScale = 1.0
    self.messageAlpha = 0
    self.messageFadeDirection = 1
    
    -- Particle effect timer
    self.particleTimer = 0
    self.particleInterval = 0.1
    
    return self
end

function LevelUpState:enter(prevState)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    
    -- Store previous state to return to
    self.previousState = prevState
    
    -- Refresh midair jumps
    self.player:refreshJumps()
    
    -- Start with zero velocity
    self.player.velocity.x = 0
    self.player.velocity.y = 0
    
    -- Initialize visual effects
    self.glowTimer = 0
    self.glowIntensity = 0
    self.glowDirection = 1
    self.messageAlpha = 0
    self.messageFadeDirection = 1
    self.messageScale = 1.0
    
    -- Fire event for level up state entered
    self.events.fire("playerEnterLevelUpState", {
        player = self.player
    })
end

function LevelUpState:update(dt)
    -- No physics updates in this state - player is paused
    
    -- Update glow effect
    self.glowTimer = self.glowTimer + dt
    self.glowIntensity = self.glowIntensity + self.glowDirection * dt * 1.5
    
    if self.glowIntensity > 1 then
        self.glowIntensity = 1
        self.glowDirection = -1
    elseif self.glowIntensity < 0.2 then
        self.glowIntensity = 0.2
        self.glowDirection = 1
    end
    
    -- Update message fade effect
    self.messageAlpha = self.messageAlpha + self.messageFadeDirection * dt
    if self.messageAlpha > 1 then
        self.messageAlpha = 1
        self.messageFadeDirection = -1
    elseif self.messageAlpha < 0.3 then
        self.messageAlpha = 0.3
        self.messageFadeDirection = 1
    end
    
    -- Update message scale with subtle pulsing
    self.messageScale = 1.0 + 0.1 * math.sin(self.glowTimer * 3)
    
    -- Update particle timer for occasional particle bursts
    self.particleTimer = self.particleTimer - dt
    if self.particleTimer <= 0 then
        self.particleTimer = self.particleInterval
        
        -- Fire event for particle effect
        self.events.fire("levelUpStateParticle", {
            x = self.player.x + self.player.width/2 + love.math.random(-30, 30),
            y = self.player.y + self.player.height/2 + love.math.random(-30, 30),
            color = {0.2, 0.8, 1} -- Light blue like XP
        })
    end
end

function LevelUpState:draw()
    -- Draw player with glow effect
    love.graphics.setColor(0.3, 0.7, 1, self.glowIntensity) -- Outer glow
    love.graphics.rectangle("fill", 
        self.player.x - 10, 
        self.player.y - 10, 
        self.player.width + 20, 
        self.player.height + 20,
        10, 10 -- Rounded corners
    )
    
    -- Draw player base
    love.graphics.setColor(0.2, 0.5, 1) -- Blue color for level-up state
    love.graphics.rectangle("fill", 
        self.player.x, 
        self.player.y, 
        self.player.width, 
        self.player.height
    )
    
    -- Draw inner highlight
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("fill", 
        self.player.x + self.player.width * 0.25, 
        self.player.y + self.player.height * 0.25, 
        self.player.width * 0.5, 
        self.player.height * 0.5
    )
    
    -- Draw prompt message
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.message)
    
    -- Text shadow
    love.graphics.setColor(0, 0, 0, self.messageAlpha * 0.7)
    love.graphics.print(
        self.message,
        self.player.x + self.player.width/2 - textWidth * self.messageScale/2 + 2,
        self.player.y - 50 + 2,
        0,
        self.messageScale,
        self.messageScale
    )
    
    -- Main text
    love.graphics.setColor(1, 1, 1, self.messageAlpha)
    love.graphics.print(
        self.message,
        self.player.x + self.player.width/2 - textWidth * self.messageScale/2,
        self.player.y - 50,
        0,
        self.messageScale,
        self.messageScale
    )
end

function LevelUpState:onDragEnd(data)
    -- Exit level up state and transition directly to dashing
    self.player.stateMachine:change("Dashing", data)
    -- Fire event for transition
    self.events.fire("playerExitLevelUpState", {
        player = self.player
    })
end

function LevelUpState:getName()
    return "LevelUp"
end

function LevelUpState:checkHorizontalBounds(screenWidth)
    -- No movement in level up state, so nothing to check
end

function LevelUpState:enemyCollision(enemy)
    -- Invulnerable in level up state, so do nothing
end

return LevelUpState