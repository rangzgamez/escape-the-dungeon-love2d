-- camera.lua - Camera system for Love2D Vertical Jumper

local Events = require("lib/events") -- Add events require

local Camera = {}
Camera.__index = Camera

function Camera:new(player)
    local self = setmetatable({}, Camera)
    
    self.x = 0
    self.y = player.y
    self.smoothness = 0.1 -- Lower = smoother camera follow
    self.highestY = player.y  -- Track the highest point reached
    
    -- Camera shake properties
    self.shakeAmount = 0     -- Current shake intensity
    self.shakeDuration = 0   -- How long the shake lasts
    self.shakeOffsetX = 0    -- Current X offset from shake
    self.shakeOffsetY = 0    -- Current Y offset from shake
    self.shakeDecay = 5      -- How quickly shake decreases (higher = faster decay)
    
    -- Register event listeners
    Events.on("playerDash", function(data) self:onPlayerDash(data) end)
    Events.on("enemyKill", function(data) self:onEnemyKill(data) end)
    Events.on("playerHit", function(data) self:onPlayerHit(data) end)
    
    return self
end

function Camera:clearShake()
    self.shakeAmount = 0
    self.shakeDuration = 0
    self.shakeOffsetX = 0
    self.shakeOffsetY = 0
end

-- Event handler for player dash
function Camera:onPlayerDash(data)
    local power = data and data.power or 1
    self:shake(3 * power, 0.2)
end

-- Event handler for enemy kill
function Camera:onEnemyKill(data)
    local comboCount = data and data.comboCount or 0
    local intensity = math.min(2 + comboCount * 0.3, 5)
    self:shake(intensity, 0.25)
end

-- Event handler for player taking damage
function Camera:onPlayerHit(data)
    self:shake(3, 0.3)
end

function Camera:update(dt, player, gameSpeed)
    -- Track the highest point the player has reached
    if player.y < self.highestY then
        self.highestY = player.y
    end
    
    -- Camera follows player vertically with some lag
    -- In a vertical jumper, the camera should move upward as the player climbs
    local targetY = math.min(player.y, self.highestY)
    
    -- Add smoothing to camera movement
    self.y = self.y + (targetY - self.y) * self.smoothness
    
    -- Add automatic upward camera movement based on game speed
    self.y = self.y - gameSpeed * dt
    
    -- Don't let the camera go too far below the player
    local maxDistanceBelow = love.graphics.getHeight() * 0.6
    if self.y > player.y + maxDistanceBelow then
        self.y = player.y + maxDistanceBelow
    end
    
    -- Update camera shake
    self:updateShake(dt)
end

-- Add shake to the camera
function Camera:shake(amount, duration)
    -- Only override if new shake is stronger
    if amount > self.shakeAmount then
        self.shakeAmount = amount
        self.shakeDuration = duration
    end
end

-- Update the camera shake effect
function Camera:updateShake(dt)
    if self.shakeDuration > 0 then
        -- Decrease shake duration
        self.shakeDuration = self.shakeDuration - dt
        
        -- Calculate random shake offset
        self.shakeOffsetX = love.math.random(-self.shakeAmount, self.shakeAmount)
        self.shakeOffsetY = love.math.random(-self.shakeAmount, self.shakeAmount)
        
        -- Gradually decrease shake amount based on decay rate
        self.shakeAmount = math.max(0, self.shakeAmount - self.shakeDecay * dt)
        
        -- Reset shake when duration ends
        if self.shakeDuration <= 0 then
            self:clearShake()
        end
    end
end

-- Get the final camera position including shake
function Camera:getPosition()
    return {
        x = self.x + self.shakeOffsetX,
        y = self.y + self.shakeOffsetY
    }
end

return Camera