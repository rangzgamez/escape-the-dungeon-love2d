-- entities/ecsEntity.lua
-- A replacement for BaseEntity that uses the ECS system directly

local Events = require("lib/events")
local ECS = require("lib/ecs/ecs")

local ECSEntity = {}
ECSEntity.__index = ECSEntity

-- Static ECS world reference
local ecsWorld = nil

-- Set the ECS world reference
function ECSEntity.setECSWorld(world)
    ecsWorld = world
end

-- Create a new entity
function ECSEntity.new(x, y, width, height, options)
    local entity = {}
    setmetatable(entity, ECSEntity)
    
    -- Initialize basic properties
    entity.x = x or 0
    entity.y = y or 0
    entity.width = width or 32
    entity.height = height or 32
    entity.active = true
    
    -- Set options
    options = options or {}
    entity.type = options.type or "entity"
    entity.collisionLayer = options.collisionLayer or "default"
    entity.collidesWithLayers = options.collidesWithLayers or {"default"}
    entity.isSolid = options.isSolid ~= nil and options.isSolid or true
    entity.color = options.color or {1, 1, 1, 1}
    
    -- Create ECS entity if world is set
    if ecsWorld then
        entity.ecsEntity = ecsWorld:createEntity()
        
        -- Add transform component
        entity.ecsEntity:addComponent("transform", {
            position = {x = entity.x, y = entity.y},
            size = {width = entity.width, height = entity.height},
            rotation = 0,
            scale = {x = 1, y = 1}
        })
        
        -- Add collider component
        entity.ecsEntity:addComponent("collider", {
            layer = entity.collisionLayer,
            collidesWithLayers = entity.collidesWithLayers,
            isSolid = entity.isSolid,
            isStatic = options.isStatic or false,
            isTrigger = options.isTrigger or false,
            offsetX = 0,
            offsetY = 0,
            width = entity.width,
            height = entity.height
        })
        
        -- Add physics component
        entity.ecsEntity:addComponent("physics", {
            velocity = {x = 0, y = 0},
            acceleration = {x = 0, y = 0},
            gravity = options.gravity or 800,
            friction = options.friction or 0.8,
            mass = options.mass or 1,
            affectedByGravity = options.affectedByGravity ~= nil and options.affectedByGravity or true
        })
        
        -- Add type component
        entity.ecsEntity:addComponent("type", {
            type = entity.type
        })
        
        -- Store reference to original entity
        entity.ecsEntity:addComponent("originalEntity", {
            entity = entity
        })
    else
        print("Warning: ECS world not set. Entity will not be added to ECS.")
    end
    
    return entity
end

-- Update entity position from ECS
function ECSEntity:update(dt)
    if self.ecsEntity then
        -- Get updated position from ECS
        local transform = self.ecsEntity:getComponent("transform")
        if transform then
            self.x = transform.position.x
            self.y = transform.position.y
        end
    end
end

-- Draw the entity
function ECSEntity:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle collision with another entity
function ECSEntity:onCollision(other, collisionData)
    -- Base collision handling
    -- Can be overridden by derived entities
end

-- Destroy the entity
function ECSEntity:destroy()
    if self.ecsEntity then
        self.ecsEntity:destroy()
    end
    self.active = false
end

return ECSEntity 