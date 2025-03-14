-- entities/baseEntity.lua
local Events = require("lib/events")
local CollisionManager = require("managers/collisionManager")

local BaseEntity = {}
BaseEntity.__index = BaseEntity

function BaseEntity:new(x, y, width, height, options)
    local self = setmetatable({}, BaseEntity)
    
    -- Basic position and dimensions
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    self.gravity = 0
    -- Movement properties
    self.velocity = {x = 0, y = 0}
        
    -- Collision properties
    self.solid = options and options.solid ~= nil and options.solid or false
    self.collisionLayer = options and options.collisionLayer or "default"
    self.collidesWithLayers = options and options.collidesWithLayers or {"default"}
    self.onGround = false
    
    -- Active state
    self.active = true
    
    -- Entity type (used for collision event filtering)
    self.type = options and options.type or "entity"
    
    -- Custom collision bounds offset (for hitboxes smaller than visual)
    self.boundingBoxOffset = options and options.boundingBoxOffset or {
        x = 0, y = 0, width = 0, height = 0
    }
    -- Register with collision manager
    CollisionManager.addEntity(self)
    return self
end

-- Update entity position based on velocity
function BaseEntity:update(dt)
    if not self.active then return end
    
    -- Apply gravity if specified
    if self.gravity ~= 0 then
        self.velocity.y = self.velocity.y + self.gravity * dt
    end
    
    -- Apply friction if on ground
    if self.onGround then
        -- Gradually reduce horizontal velocity
        self.velocity.x = self.velocity.x
        
        -- Stop completely if very slow (avoid floating point creep)
        if math.abs(self.velocity.x) < 0.1 then
            self.velocity.x = 0
        end
    end
    
    -- Apply velocity to position
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
end

-- Draw the entity (basic implementation - intended to be overridden)
function BaseEntity:draw()
    if not self.active then return end
    
    -- Default drawing with white color
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw collision box in debug mode
    if self.debug then
        love.graphics.setColor(1, 0, 0, 0.5)
        local bounds = self:getBounds()
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

-- Get collision bounds (used for collision detection)
function BaseEntity:getBounds()
    return {
        x = self.x + self.boundingBoxOffset.x,
        y = self.y + self.boundingBoxOffset.y,
        width = self.width + self.boundingBoxOffset.width,
        height = self.height + self.boundingBoxOffset.height
    }
end

-- Set entity position
function BaseEntity:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set entity velocity
function BaseEntity:setVelocity(vx, vy)
    self.velocity.x = vx
    self.velocity.y = vy
end

-- Check if this entity collides with another entity
function BaseEntity:checkCollision(other)
    if not self.active or not other.active then
        return false
    end
    
    -- Get collision bounds
    local bounds1 = self:getBounds()
    local bounds2 = other:getBounds()
    
    -- Check if layers can collide in both directions
    local layersCanCollide = false
    
    -- Check if self can collide with other's layer
    for _, layer in ipairs(self.collidesWithLayers) do
        if layer == other.collisionLayer then
            layersCanCollide = true
            break
        end
    end
    
    -- Also check if other can collide with self's layer
    if not layersCanCollide then
        for _, layer in ipairs(other.collidesWithLayers) do
            if layer == self.collisionLayer then
                layersCanCollide = true
                break
            end
        end
    end
    
    if not layersCanCollide then
        return false
    end
    
    -- Check for AABB collision
    local collision = bounds1.x < bounds2.x + bounds2.width and
                     bounds1.x + bounds1.width > bounds2.x and
                     bounds1.y < bounds2.y + bounds2.height and
                     bounds1.y + bounds1.height > bounds2.y
    
    return collision
end

-- Handle collision response (basic implementation - can be overridden)
function BaseEntity:onCollision(other, collisionData)
    local selfEvent = "collision:" .. self.type
    local otherEvent = "collision:" .. self.type .. ":" .. other.type
    -- Fire entity-specific collision event
    Events.fire(selfEvent, {
        entity = self,
        other = other,
        collisionData = collisionData
    })
    
    -- Fire collision event with specific entity types
    Events.fire(otherEvent, {
        entityA = self,
        entityB = other,
        collisionData = collisionData
    })
    
    -- Return true if handled, false to let physics manager handle it
    return false
end

-- Destroy this entity
function BaseEntity:destroy()
    self.active = false
    Events.fire("entityDestroyed", {entity = self})
end

return BaseEntity