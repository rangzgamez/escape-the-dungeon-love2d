-- managers/collisionManager.lua
local CollisionManager = {}

local entities = {}
-- Add an entity to the collision system
function CollisionManager.addEntity(entity)
    table.insert(entities, entity)
end

-- Remove an entity from the collision system
function CollisionManager.removeEntity(entity)
    for i, e in ipairs(entities) do
        if e == entity then
            table.remove(entities, i)
            break
        end
    end
end

-- Clear all entities
function CollisionManager.clear()
    entities = {}
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