-- xpPelletECS.lua - XP collectibles that drop from enemies (ECS version)
local Events = require("lib/events")
local ECSEntity = require("entities/ecsEntity")

local XpPelletECS = {}
XpPelletECS.__index = XpPelletECS

function XpPelletECS.new(x, y, value)
    -- Create options for the XP pellet
    local options = {
        type = "xpPellet",
        collisionLayer = "collectible",
        collidesWithLayers = {"player"}, -- Only collide with player
        isSolid = false, -- Non-solid entity
        color = {0.2, 0.8, 1, 1}, -- Light blue for XP
        affectedByGravity = false -- XP pellets float
    }
    
    -- Create the entity using ECSEntity constructor
    local pellet = ECSEntity.new(x, y, 16, 16, options)
    
    -- Set up XpPelletECS metatable
    setmetatable(pellet, {__index = XpPelletECS})
    
    -- XP-specific properties
    pellet.value = value or 1 -- XP value
    pellet.lifetime = 10 -- Seconds before disappearing
    pellet.magnetizable = true -- Can be pulled toward player
    
    -- Add components to ECS entity
    if pellet.ecsEntity then
        -- Add XP component
        pellet.ecsEntity:addComponent("xp", {
            value = pellet.value,
            lifetime = pellet.lifetime,
            magnetizable = pellet.magnetizable
        })
        
        -- Add physics component with custom settings
        local physics = pellet.ecsEntity:getComponent("physics")
        if physics then
            physics.gravity = 0
            physics.friction = 0.95
        end
    end
    
    return pellet
end

-- Handle collision with another entity
function XpPelletECS:onCollision(other, collisionData)
    -- Check if colliding with player
    if other.type == "player" then
        -- Fire XP collected event
        Events.fire("xpCollected", {value = self.value})
        
        -- Destroy this pellet
        self:destroy()
    end
end

-- Update the XP pellet
function XpPelletECS:update(dt)
    -- Call parent update
    ECSEntity.update(self, dt)
    
    -- Update lifetime if using ECS
    if self.ecsEntity then
        local xpComponent = self.ecsEntity:getComponent("xp")
        if xpComponent then
            xpComponent.lifetime = xpComponent.lifetime - dt
            
            -- Destroy if lifetime is up
            if xpComponent.lifetime <= 0 then
                self:destroy()
            end
        end
    end
end

-- Destroy the XP pellet
function XpPelletECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to XP pellets
    self.active = false
end

function XpPelletECS:draw()
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

function XpPelletECS:collect()
    if not self.active or not self.collectible then
        return 0
    end
    
    -- Deactivate
    self.active = false
    
    -- Return the XP value
    return self.value
end

function XpPelletECS:applyMagneticForce(targetX, targetY, strength)
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
            
            -- Update ECS entity if available
            if self.ecsEntity and self.ecsEntity:hasComponent("physics") then
                local physics = self.ecsEntity:getComponent("physics")
                physics.velocityX = self.velocity.x
                physics.velocityY = self.velocity.y
            end
        end
    end
end

return XpPelletECS 