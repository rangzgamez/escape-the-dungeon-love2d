-- xpPellet.lua - XP collectibles that drop from enemies
local Events = require("lib/events")

local XpPellet = {}
XpPellet.__index = XpPellet

function XpPellet:new(x, y, value)
    local self = setmetatable({}, XpPellet)
    
    -- Position and dimensions
    self.x = x
    self.y = y
    self.width = 15  -- Larger size
    self.height = 15 -- Larger size
    self.value = value or 1 -- XP value
    
    -- Movement properties
    self.xVelocity = love.math.random(-50, 50)
    self.yVelocity = -love.math.random(50, 100) -- Initial upward velocity
    self.gravity = 400
    
    -- Visual properties
    self.rotation = 0
    self.rotationSpeed = love.math.random(-3, 3)
    self.color = {0.2, 0.8, 1} -- Light blue for XP
    self.scale = 1.0
    self.pulseDirection = 1
    self.pulseSpeed = love.math.random(1, 3)
    
    -- Gameplay properties
    self.active = true
    self.collectible = true -- Make immediately collectible
    self.lifetime = 15.0 -- Longer lifetime
    self.magnetizable = true -- Can be pulled by magnet effects
    
    return self
end

function XpPellet:update(dt)
    -- Update lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.active = false
        return
    end
    
    -- Apply gravity
    self.yVelocity = self.yVelocity + self.gravity * dt
    
    -- Apply velocities
    self.x = self.x + self.xVelocity * dt
    self.y = self.y + self.yVelocity * dt
    
    -- Damping to slow down movement
    self.xVelocity = self.xVelocity * 0.95
    
    -- Can be collected after settling down a bit
    if not self.collectible and math.abs(self.xVelocity) < 10 and math.abs(self.yVelocity) < 50 then
        self.collectible = true
    end
    
    -- Update rotation
    self.rotation = self.rotation + self.rotationSpeed * dt
    
    -- Pulsing effect
    self.scale = self.scale + self.pulseDirection * self.pulseSpeed * dt * 0.2
    if self.scale > 1.2 then
        self.scale = 1.2
        self.pulseDirection = -1
    elseif self.scale < 0.8 then
        self.scale = 0.8
        self.pulseDirection = 1
    end
end

function XpPellet:draw()
    -- Draw outer glow first (always visible)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 2)
    
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.5)
    love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 1.5)
    
    -- Save current transformation state
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2)
    love.graphics.rotate(self.rotation)
    love.graphics.scale(self.scale, self.scale)
    
    -- Draw gem shape for XP pellet
    love.graphics.setColor(self.color)
    love.graphics.polygon("fill", 
        0, -self.height/2,  -- Top point
        self.width/2, 0,    -- Right point
        0, self.height/2,   -- Bottom point
        -self.width/2, 0    -- Left point
    )
    
    -- Draw border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.polygon("line", 
        0, -self.height/2,  -- Top point
        self.width/2, 0,    -- Right point
        0, self.height/2,   -- Bottom point
        -self.width/2, 0    -- Left point
    )
    
    -- Draw highlight
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.line(
        -self.width/4, -self.height/4,
        0, -self.height/2,
        self.width/4, -self.height/4
    )
    
    -- Restore transformation state
    love.graphics.pop()
end

function XpPellet:collect()
    if not self.active or not self.collectible then
        return 0
    end
    
    -- Deactivate
    self.active = false
    
    -- Fire collection event
    Events.fire("xpPelletCollected", {
        x = self.x + self.width/2,
        y = self.y + self.height/2,
        value = self.value
    })
    
    return self.value
end

function XpPellet:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return XpPellet