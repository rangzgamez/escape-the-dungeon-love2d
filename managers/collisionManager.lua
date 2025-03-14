-- managers/collisionManager.lua
-- DEPRECATED: This module is deprecated and will be removed in a future version.
-- Use the ECS CollisionSystem instead.

local CollisionManager = {}

-- Keep track of entities for backward compatibility
local entities = {}

-- Reference to the ECS world and collision system
local ecsWorld = nil
local collisionSystem = nil

-- Set the ECS world reference
function CollisionManager.setECSWorld(world)
    ecsWorld = world
    if world then
        collisionSystem = world.systemManager:getSystem("CollisionSystem")
    end
end

-- Add an entity to the collision system
function CollisionManager.addEntity(entity)
    table.insert(entities, entity)
    
    -- If the entity has already been converted to ECS, no need to do anything else
    if entity.ecsEntity then
        return
    end
    
    -- If we have an ECS world, convert the entity to ECS
    if ecsWorld and entity.getBounds then
        -- Create or get ECS entity
        local ecsEntity = ecsWorld:createEntity()
        
        -- Add transform component
        local bounds = entity:getBounds()
        ecsEntity:addComponent("transform", {
            x = bounds.x,
            y = bounds.y,
            width = bounds.width,
            height = bounds.height
        })
        
        -- Add collider component
        ecsEntity:addComponent("collider", {
            offsetX = 0,
            offsetY = 0,
            width = bounds.width,
            height = bounds.height,
            layer = entity.collisionLayer or "default",
            collidesWithLayers = entity.collidesWithLayers or {"default"}
        })
        
        -- Add type component
        ecsEntity:addComponent("type", {
            name = entity.type or "entity"
        })
        
        -- Store reference to ECS entity
        entity.ecsEntity = ecsEntity
        
        -- Store reference to original entity
        ecsEntity.originalEntity = entity
    end
end

-- Remove an entity from the collision system
function CollisionManager.removeEntity(entity)
    for i, e in ipairs(entities) do
        if e == entity then
            table.remove(entities, i)
            break
        end
    end
    
    -- If the entity has an ECS entity, remove it from the ECS world
    if entity.ecsEntity and ecsWorld then
        ecsWorld:returnToPool(entity.ecsEntity)
        entity.ecsEntity = nil
    end
end

-- Clear all entities
function CollisionManager.clear()
    entities = {}
    
    -- If we have an ECS world, clear it too
    if ecsWorld then
        -- The ECS world doesn't have a clear method, but we can reset the spatial grid
        if collisionSystem then
            collisionSystem.spatialGrid:clear()
        end
    end
end

-- Get all active entities
function CollisionManager.getActiveEntities()
    local activeEntities = {}
    
    for _, entity in ipairs(entities) do
        if entity.active then
            table.insert(activeEntities, entity)
        end
    end
    
    return activeEntities
end

-- Check if two entities can collide based on their layers
function CollisionManager.canLayersCollide(entityA, entityB)
    -- Check if A can collide with B's layer
    local aCanCollideWithB = false
    for _, layer in ipairs(entityA.collidesWithLayers or {}) do
        if layer == entityB.collisionLayer then
            aCanCollideWithB = true
            break
        end
    end
    
    -- Check if B can collide with A's layer
    local bCanCollideWithA = false
    for _, layer in ipairs(entityB.collidesWithLayers or {}) do
        if layer == entityA.collisionLayer then
            bCanCollideWithA = true
            break
        end
    end
    
    -- If either can collide with the other, we should check collision
    return aCanCollideWithB or bCanCollideWithA
end

-- Process a single collision
function CollisionManager.processCollision(entityA, entityB, dt)
    if not entityA or not entityB then
        return
    end
    
    if not entityA.getBounds or not entityB.getBounds then
        return
    end
    
    -- Skip if entities shouldn't collide based on layers
    if not CollisionManager.canLayersCollide(entityA, entityB) then
        return
    end
    
    -- Get bounds for both entities
    local boundsA = entityA:getBounds()
    local boundsB = entityB:getBounds()
    
    -- Check for actual collision
    if not entityA:checkCollision(entityB) then
        return
    end
    
    -- Calculate collision data with more precise values
    local collisionData = {
        dt = dt,
        dx = boundsA.x - boundsB.x,
        dy = boundsA.y - boundsB.y,
        overlapX = math.min(boundsA.x + boundsA.width - boundsB.x, boundsB.x + boundsB.width - boundsA.x),
        overlapY = math.min(boundsA.y + boundsA.height - boundsB.y, boundsB.y + boundsB.height - boundsA.y),
        fromAbove = boundsA.y + boundsA.height - boundsB.y < 20,  -- Increased threshold to 20 pixels
        fromBelow = boundsB.y + boundsB.height - boundsA.y < 20,  -- Increased threshold to 20 pixels
        fromLeft = boundsA.x + boundsA.width - boundsB.x < 20,    -- Increased threshold to 20 pixels
        fromRight = boundsB.x + boundsB.width - boundsA.x < 20    -- Increased threshold to 20 pixels
    }
    
    -- Let entities handle their own collision response
    entityA:onCollision(entityB, collisionData)
    entityB:onCollision(entityA, collisionData)
end

-- Main update function
function CollisionManager.update(dt)
    -- If we have an ECS world, update entity positions in the ECS world
    if ecsWorld then
        for _, entity in ipairs(entities) do
            if entity.active and entity.ecsEntity and entity.getBounds then
                local bounds = entity:getBounds()
                local transform = entity.ecsEntity:getComponent("transform")
                if transform then
                    transform.x = bounds.x
                    transform.y = bounds.y
                    transform.width = bounds.width
                    transform.height = bounds.height
                    
                    -- Update entity in spatial grid
                    ecsWorld:updateEntityPosition(entity.ecsEntity)
                end
            end
        end
        
        -- Let the ECS world handle collisions
        -- The ECS collision system will be updated as part of the ECS world update
        -- which is called from the XpManager
        return
    end
    
    -- Legacy collision detection (only used if ECS world is not available)
    local activeEntities = CollisionManager.getActiveEntities()
    local count = #activeEntities
    
    -- Check each pair of entities exactly once
    for i = 1, count do
        local entityA = activeEntities[i]
        
        for j = i + 1, count do
            local entityB = activeEntities[j]
            CollisionManager.processCollision(entityA, entityB, dt)
        end
    end
end

function CollisionManager.getDebugBounds()
    local debugInfo = {}
    
    for _, entity in ipairs(entities) do
        if entity.active and entity.getBounds then
            local bounds = entity:getBounds()
            local color
            
            -- Color based on entity type
            if entity.type == "player" then
                color = {0, 1, 0, 0.3}  -- Green
            elseif entity.type == "enemy" then
                color = {1, 0, 0, 0.3}  -- Red
            elseif entity.type == "platform" then
                color = {0.5, 0.5, 0.5, 0.3}  -- Gray
            elseif entity.type == "xpPellet" then
                color = {1, 1, 1, 0.5}  -- White with higher opacity for XP pellets
            else
                color = {0, 0, 1, 0.3}  -- Blue
            end
            
            table.insert(debugInfo, {
                bounds = bounds,
                color = color,
                type = entity.type
            })
        end
    end
    
    return debugInfo
end

return CollisionManager