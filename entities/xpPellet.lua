-- xpPellet.lua - XP collectibles that drop from enemies
local Events = require("lib/events")
local BaseEntity = require("entities/baseEntity")

local XpPellet = setmetatable({}, {__index = BaseEntity})
XpPellet.__index = XpPellet

function XpPellet:new(x, y, value)
    -- Call the parent constructor with entity-specific options
    local self = BaseEntity.new(self, x, y, 10, 10, {
        type = "xpPellet",
        collisionLayer = "collectible",
        collidesWithLayers = {"player"}, -- Only collide with player
        solid = false -- Non-solid entity
    })
    
    -- XP-specific properties
    self.value = value or 1 -- XP value
    
    -- Generate random angle and speed for the "explosion" effect
    local angle = love.math.random() * math.pi * 2  -- Random angle in radians
    local speed = love.math.random(1000, 2200)        -- Higher initial speed
    
    -- Apply initial velocity based on angle and speed
    self.velocity = {
        x = math.cos(angle) * speed,
        y = math.sin(angle) * speed
    }
    
    -- Physics properties
    self.gravity = 0  -- Remove gravity for floaty feel
    self.friction = 2.0  -- Higher friction to slow down quickly
    self.initialMovementDuration = 0.5  -- Duration of initial movement
    self.movementTimer = self.initialMovementDuration  -- Timer for movement phase
    
    -- Visual properties
    self.rotation = 0
    self.rotationSpeed = love.math.random(-3, 3)
    self.color = {0.2, 0.8, 1} -- Light blue for XP
    self.scale = 1.0
    self.pulseDirection = 1
    self.pulseSpeed = love.math.random(2, 4)
    
    -- Sparkle effect
    self.sparkleTimer = 0
    self.sparkleInterval = love.math.random(0.5, 1.5)
    self.sparkles = {}
    
    -- Gameplay properties
    self.collectible = false -- Start as not collectible
    self.collectionDelay = 0.3 -- Slightly longer delay so pellets have time to move
    self.lifetime = 15.0 -- Lifetime
    self.magnetizable = false -- Not magnetizable until collectible
    
    setmetatable(self, XpPellet)
    return self
end

function XpPellet:update(dt)
    -- Update lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.active = false
        return
    end
    
    -- Update initial movement phase
    if self.movementTimer > 0 then
        self.movementTimer = self.movementTimer - dt
        
        -- Apply friction to gradually slow down
        self.velocity.x = self.velocity.x * (1 - self.friction * dt)
        self.velocity.y = self.velocity.y * (1 - self.friction * dt)
        
        -- If movement phase is over, stop completely
        if self.movementTimer <= 0 then
            self.velocity.x = 0
            self.velocity.y = 0
        end
    end
    
    -- Update collection delay
    if not self.collectible then
        self.collectionDelay = self.collectionDelay - dt
        if self.collectionDelay <= 0 then
            self.collectible = true
            self.magnetizable = true -- Now it can be pulled
            
            -- Add a burst of sparkles when becoming collectible
            for i = 1, 8 do
                table.insert(self.sparkles, {
                    x = love.math.random(-self.width, self.width),
                    y = love.math.random(-self.height, self.height),
                    size = love.math.random(3, 6),
                    life = 0.7,
                    maxLife = 0.7
                })
            end
        end
    end
    
    -- Update rotation
    self.rotation = self.rotation + self.rotationSpeed * dt
    
    -- Enhanced pulsing effect
    self.scale = self.scale + self.pulseDirection * self.pulseSpeed * dt * 0.25
    if self.scale > 1.3 then
        self.scale = 1.3
        self.pulseDirection = -1
    elseif self.scale < 0.7 then
        self.scale = 0.7
        self.pulseDirection = 1
    end
    
    -- Update sparkle effect
    self.sparkleTimer = self.sparkleTimer - dt
    if self.sparkleTimer <= 0 then
        -- Create a new sparkle
        table.insert(self.sparkles, {
            x = love.math.random(-self.width, self.width),
            y = love.math.random(-self.height, self.height),
            size = love.math.random(2, 5),
            life = 0.5,
            maxLife = 0.5
        })
        self.sparkleTimer = self.sparkleInterval
    end
    
    -- Update existing sparkles
    for i = #self.sparkles, 1, -1 do
        local sparkle = self.sparkles[i]
        sparkle.life = sparkle.life - dt
        if sparkle.life <= 0 then
            table.remove(self.sparkles, i)
        end
    end
    
    -- Call parent update to apply velocity and position
    BaseEntity.update(self, dt)
end

function XpPellet:draw()
    if not self.active then return end
    
    -- Draw outer glow first (always visible) - make it larger and more vibrant
    -- love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.4)
    -- love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 1.1)
    
    -- love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.6)
    -- love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 1.2)
    
    -- Draw sparkles
    for _, sparkle in ipairs(self.sparkles) do
        local alpha = sparkle.life / sparkle.maxLife
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", 
            self.x + self.width/2 + sparkle.x, 
            self.y + self.height/2 + sparkle.y, 
            sparkle.size * alpha
        )
    end
    
    -- Save current transformation state
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2)
    love.graphics.rotate(self.rotation)
    love.graphics.scale(self.scale, self.scale)
    
    -- Draw gem shape for XP pellet - make it brighter
    -- If not collectible yet, make it slightly darker
    if self.collectible then
        love.graphics.setColor(self.color[1] + 0.2, self.color[2] + 0.2, self.color[3] + 0.2)
    else
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    end
    
    love.graphics.polygon("fill", 
        0, -self.height/2,  -- Top point
        self.width/2, 0,    -- Right point
        0, self.height/2,   -- Bottom point
        -self.width/2, 0    -- Left point
    )
    
    -- Draw border - make it more visible
    if self.collectible then
        love.graphics.setColor(1, 1, 1, 0.9)
    else
        love.graphics.setColor(1, 1, 1, 0.6)  -- Less visible when not collectible
    end
    
    love.graphics.setLineWidth(2) -- Thicker line
    love.graphics.polygon("line", 
        0, -self.height/2,  -- Top point
        self.width/2, 0,    -- Right point
        0, self.height/2,   -- Bottom point
        -self.width/2, 0    -- Left point
    )
    love.graphics.setLineWidth(1) -- Reset line width
    
    -- Draw highlight - make it brighter
    love.graphics.setColor(1, 1, 1, self.collectible and 1.0 or 0.7)
    love.graphics.line(
        -self.width/4, -self.height/4,
        0, -self.height/2,
        self.width/4, -self.height/4
    )
    
    -- Restore transformation state
    love.graphics.pop()
    
    -- Debug draw if needed
    -- if self.debug then
    --     local bounds = self:getBounds()
    --     love.graphics.setColor(0, 1, 0, 0.5)
    --     love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    -- end
end

function XpPellet:onCollision(other, collisionData)
    -- Only handle collision with player
    if other.type == "player" and self.collectible then
        -- Mark as collected - the player will handle the actual XP logic
        self.active = false
        return true
    end
    
    -- Let the parent handle any other collisions
    return BaseEntity.onCollision(self, other, collisionData)
end

-- Simplified collect method - just returns the value and marks as inactive
function XpPellet:collect()
    if not self.active or not self.collectible then
        return 0
    end
    
    -- Deactivate
    self.active = false
    
    -- Return the XP value
    return self.value
end

function XpPellet:applyMagneticForce(targetX, targetY, strength)
    if not self.magnetizable or not self.active then return end
    
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    
    -- Calculate distance to target
    local dx = targetX - centerX
    local dy = targetY - centerY
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Apply force if within range
    if distance > 0 then
        -- Normalize direction vector
        local nx = dx / distance
        local ny = dy / distance
        
        -- Calculate force (stronger when closer)
        local force = strength * (1 - math.min(1, distance / 200))
        
        -- Apply force to velocity
        self.velocity.x = self.velocity.x + nx * force
        self.velocity.y = self.velocity.y + ny * force
    end
end

return XpPellet