-- camera.lua - Camera system for Love2D Vertical Jumper


local Events = require("lib/events")

local Camera = {}
Camera.__index = Camera

function Camera:new(player)
    local self = setmetatable({}, Camera)
    
    self.x = 0
    self.y = player.y
    self.smoothness = 0.1 -- Lower = smoother camera follow
    
    -- Track the highest point reached by the player
    self.highestY = player.y
    
    -- Automatic scrolling properties
    self.autoScrollSpeed = 40 -- Base speed of automatic scrolling (pixels per second)
    self.autoScrollActive = true -- Whether auto-scrolling is active
    self.minDistanceFromLava = 200 -- Minimum distance player should be from lava
    
    -- Difficulty scaling
    self.initialScrollSpeed = 40 -- Starting scroll speed
    self.maxScrollSpeed = 100 -- Maximum scroll speed
    self.scrollSpeedIncreaseRate = 0.5 -- How much to increase per second
    self.currentScrollSpeed = self.initialScrollSpeed
    self.timeSinceStart = 0
    
    -- Lava properties
    self.lavaY = player.y + 300 -- Start lava below the player
    self.lavaHeight = 32 -- Height of the lava visual effect
    
    -- Camera shake properties
    self.shakeAmount = 0
    self.shakeDuration = 0
    self.shakeOffsetX = 0
    self.shakeOffsetY = 0
    self.shakeDecay = 5
    
    -- Register event listeners
    Events.on("playerDash", function(data) self:onPlayerDash(data) end)
    Events.on("enemyKill", function(data) self:onEnemyKill(data) end)
    Events.on("playerHit", function(data) self:onPlayerHit(data) end)
    
    return self
end

function Camera:update(dt, player, gameSpeed)
    -- If player is nil, just update time and return
    if not player then
        -- Update time for difficulty scaling
        self.timeSinceStart = self.timeSinceStart + dt
        
        -- Calculate current scroll speed
        self.currentScrollSpeed = math.min(
            self.initialScrollSpeed + self.timeSinceStart * self.scrollSpeedIncreaseRate,
            self.maxScrollSpeed
        )
        
        -- Apply auto-scrolling directly
        self.y = self.y - self.currentScrollSpeed * dt
        
        -- Update lava position to follow camera
        self.lavaY = self.y + love.graphics.getHeight()
        
        -- Update camera shake
        self:updateShake(dt)
        
        return 0 -- Return 0 as distance from lava
    end
    
    -- Update time for difficulty scaling
    self.timeSinceStart = self.timeSinceStart + dt
    
    -- Calculate current scroll speed (keep this as is - it should be a significant number)
    self.currentScrollSpeed = math.min(
        self.initialScrollSpeed + self.timeSinceStart * self.scrollSpeedIncreaseRate,
        self.maxScrollSpeed
    )
    
    -- DIRECT AUTO-SCROLLING - This ensures the minimum speed is always applied
    -- Apply auto-scrolling directly first without smoothing
    self.y = self.y - self.currentScrollSpeed * dt
    
    -- THEN check if we need to follow the player
    -- Calculate the position where the player would be on screen
    local playerScreenPosition = player.y - self.y + love.graphics.getHeight() / 2
    
    -- If player is too high in the view, adjust camera to follow
    if playerScreenPosition < 450 then
        -- Calculate the target Y to keep player at the desired height
        local targetY = player.y - 450 + love.graphics.getHeight() / 2
        
        -- Only apply smoothing for player following, not for base scrolling
        self.y = self.y + (targetY - self.y) * self.smoothness
    end
    
    -- Track the highest point reached by player
    if player.y < self.highestY then
        self.highestY = player.y
    end
    
    -- Update lava position to follow camera
    self.lavaY = self.y + love.graphics.getHeight()
    
    -- Update camera shake
    self:updateShake(dt)
    
    -- Check if player is about to be caught by lava
    local distanceFromLava = self.lavaY - player.y - player.height
    
    -- If player is too close to lava, slow the lava down a bit to give them a chance
    if distanceFromLava < self.minDistanceFromLava then
        -- Give the player a small breathing room by slowing lava
        local slowFactor = math.max(0.1, distanceFromLava / self.minDistanceFromLava)
        self.lavaY = self.lavaY - (10 * (1 - slowFactor)) * dt
    end
    
    return distanceFromLava
end

function Camera:isPlayerCaughtByLava(player)
    if not player then
        return false
    end
    return (player.y + player.height) >= self.lavaY
end

-- Draw the lava effect at the bottom of the screen
function Camera:drawLava()
    -- Get the screen dimensions
    local screenHeight = love.graphics.getHeight()
    local screenWidth = love.graphics.getWidth()
    
    -- Calculate lava position in screen coordinates
    local lavaScreenY = screenHeight - self.lavaHeight
    
    -- Create a gradient effect for the lava
    for i = 0, self.lavaHeight, 2 do
        local ratio = i / self.lavaHeight
        
        -- Gradient from bright orange at top to dark red at bottom
        local r = 1.0
        local g = 0.5 - (ratio * 0.3)
        local b = 0.0
        
        love.graphics.setColor(r, g, b, 1.0)
        love.graphics.rectangle("fill", 0, lavaScreenY + i, screenWidth, 2)
    end
    
    -- Add flowing effect by using sine waves
    local time = love.timer.getTime()
    
    -- Draw the top of the lava with a wavy pattern
    love.graphics.setColor(1, 0.7, 0.1, 0.8)
    
    local waveHeight = 5
    local segments = 20
    local points = {}
    
    for i = 0, segments do
        local x = (i / segments) * screenWidth
        local y = lavaScreenY + math.sin(time * 2 + i * 0.5) * waveHeight
        table.insert(points, x)
        table.insert(points, y)
    end
    
    -- Add two points at the bottom to complete the polygon
    table.insert(points, screenWidth)
    table.insert(points, lavaScreenY + 15)
    table.insert(points, 0)
    table.insert(points, lavaScreenY + 15)
    
    love.graphics.polygon("fill", unpack(points))
    
    -- Add bubbling effect
    love.graphics.setColor(1, 0.8, 0.2, 0.7)
    for i = 1, 8 do
        local bubbleX = (love.math.random() * screenWidth)
        local bubbleY = lavaScreenY + love.math.random(5, self.lavaHeight - 10)
        local bubbleSize = 2 + love.math.random() * 6
        love.graphics.circle("fill", bubbleX, bubbleY, bubbleSize)
    end
    
    -- Add glow effect at the top
    love.graphics.setColor(1, 0.7, 0, 0.3)
    love.graphics.rectangle("fill", 0, lavaScreenY - 15, screenWidth, 20)
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

-- Apply camera transformation
function Camera:apply()
    love.graphics.push()
    love.graphics.translate(-self.shakeOffsetX, -self.y + self.shakeOffsetY)
end

-- Reset camera transformation
function Camera:clear()
    love.graphics.pop()
end

-- Reset camera to initial state
function Camera:reset(player)
    if player then
        self.y = player.y
        self.highestY = player.y
        self.lavaY = player.y + 300
    else
        -- Default reset if no player is provided
        self.y = love.graphics.getHeight() - 200
        self.highestY = self.y
        self.lavaY = self.y + 300
    end
    
    -- Reset other properties
    self.x = 0
    self.shakeAmount = 0
    self.shakeDuration = 0
    self.shakeOffsetX = 0
    self.shakeOffsetY = 0
    self.timeSinceStart = 0
    self.currentScrollSpeed = self.initialScrollSpeed
    self.autoScrollActive = true
    
    print("Camera reset")
end

return Camera