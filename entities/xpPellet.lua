-- xpPellet.lua - XP collectibles that drop from enemies
local Events = require("lib/events")
local BaseEntity = require("entities/baseEntity")

local XpPellet = setmetatable({}, {__index = BaseEntity})
XpPellet.__index = XpPellet

function XpPellet:new(x, y, value)
    -- Call the parent constructor with entity-specific options
    local self = BaseEntity.new(self, x, y, 20, 20, {
        type = "xpPellet",
        collisionLayer = "collectible",
        collidesWithLayers = {"player"}, -- Only collide with player
        solid = false -- Non-solid entity
    })
    
    -- XP-specific properties
    self.value = value or 1 -- XP value
    
    -- Initialize velocity (will be set by XpManager)
    self.velocity = {
        x = 0,
        y = 0
    }
    
    -- Physics properties
    self.gravity = 0--400
    
    -- Visual properties
    self.color = {0.2, 0.8, 1} -- Light blue for XP
    
    -- Gameplay properties
    self.collectible = false -- Start as not collectible
    self.collectionDelay = 0.5 -- Delay before pellet can be collected
    self.lifetime = 15.0 -- Longer lifetime
    self.magnetizable = false -- Can't be pulled until collectible
    
    -- Debug label properties
    self.showDebugLabel = true -- Set to false to disable the label
    
    -- Print debug message to confirm creation
    print("XP Pellet created at position:", x, y, "with value:", value)
    
    return self
end

function XpPellet:update(dt)
    -- Update lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.active = false
        return
    end
    
    -- Update collection delay
    if not self.collectible then
        self.collectionDelay = self.collectionDelay - dt
        if self.collectionDelay <= 0 then
            self.collectible = true
            self.magnetizable = true -- Now it can be pulled
            
            -- Stop all movement when becoming collectible
            self.velocity.x = 0
            self.velocity.y = 0
            
            -- Add a burst of sparkles when becoming collectible
            for i = 1, 12 do  -- Increased number of sparkles
                local angle = math.random() * math.pi * 2
                local distance = math.random(5, 20)
                
                table.insert(self.sparkles, {
                    x = math.cos(angle) * distance,
                    y = math.sin(angle) * distance,
                    size = love.math.random(3, 8),  -- Larger sparkles
                    life = 0.8,  -- Longer life
                    maxLife = 0.8
                })
            end
        end
    end
    
    -- Apply gravity only if not collectible
    if not self.collectible then
        self.velocity.y = self.velocity.y + self.gravity * dt
        
        -- Apply dampening to slow down movement
        self.velocity.x = self.velocity.x * 0.95
    end
    
    -- Call parent update to apply velocity and position
    BaseEntity.update(self, dt)
end

function XpPellet:draw()
    if not self.active then return end
    
    -- Draw outer glow first (always visible) - make it larger and more vibrant
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.4)
    love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 2.5)
    
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.6)
    love.graphics.circle("fill", self.x + self.width/2, self.y + self.height/2, self.width * 1.8)
        
    -- Save current transformation state
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2)
    
    -- Draw gem shape for XP pellet - make it brighter
    -- If not collectible yet, make it slightly darker
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    
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
    
    -- Add a small "XP" text in the center for clarity
    love.graphics.setColor(1, .5, .5, self.collectible and 0.9 or 0.6)
    local font = love.graphics.getFont()
    local text = "XP"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, -textWidth/2, -textHeight/2, 0, 0.7, 0.7)
    
    -- Restore transformation state
    love.graphics.pop()
    
    -- Draw debug label above the pellet
    if self.showDebugLabel then
        local labelText = "XP Pellet"
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(labelText)
        
        -- Draw background for better visibility - make it more opaque and larger
        love.graphics.setColor(0, 0, 0, 0.9)  -- More opaque background
        love.graphics.rectangle("fill", 
            self.x + self.width/2 - textWidth/2 - 4, 
            self.y - 30,  -- Position higher above the pellet
            textWidth + 8,  -- Wider background
            20)  -- Taller background
            
        -- Draw text - make it larger and brighter
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(
            labelText, 
            self.x + self.width/2 - textWidth/2, 
            self.y - 28,  -- Adjust text position to match new background
            0,  -- Rotation
            1.2, 1.2  -- Scale text to make it larger
        )
        
        -- Add position info to the debug label
        local posText = string.format("Pos: %.0f, %.0f", self.x, self.y)
        local posWidth = font:getWidth(posText)
        
        -- Draw background for position text
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 
            self.x + self.width/2 - posWidth/2 - 4, 
            self.y - 10,  -- Position below the main label
            posWidth + 8,
            20)
            
        -- Draw position text
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow for position
        love.graphics.print(
            posText, 
            self.x + self.width/2 - posWidth/2, 
            self.y - 8,
            0,
            1.0, 1.0
        )
        
        -- Print debug info to console
        if love.timer.getTime() % 2 < 0.1 then  -- Only print occasionally to avoid spam
            print("Drawing XP Pellet label at:", self.x, self.y)
        end
    end
    
    -- Always draw visual bounds indicator (red) to show where the pellet thinks it is
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- Debug draw collision bounds (white) if needed
    if self.debug then
        local bounds = self:getBounds()
        love.graphics.setColor(1, 1, 1, 0.7)  -- White with higher opacity
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

function XpPellet:onCollision(other, collisionData)
    -- Only handle collision with player
    if other.type == "player" and self.collectible then
        print('hello??')
        -- Mark as collected - the player will handle the actual XP logic
        self.active = false
        return true
    end
    
    -- Let the parent handle any other collisions
    --return BaseEntity.onCollision(self, other, collisionData)
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
        
        -- Apply force to velocity (only if collectible)
        if self.collectible then
            self.velocity.x = nx * force
            self.velocity.y = ny * force
        end
    end
end

-- Override getBounds to ensure it returns the correct collision area
function XpPellet:getBounds()
    -- Return the actual position and size without any offsets
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return XpPellet