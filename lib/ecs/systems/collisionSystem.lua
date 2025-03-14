-- lib/ecs/systems/collisionSystem.lua
-- Collision System using spatial partitioning

local System = require("lib/ecs/system")
local SpatialPartition = require("lib/ecs/spatialPartition")
local Events = require("lib/events")

local CollisionSystem = setmetatable({}, {__index = System})
CollisionSystem.__index = CollisionSystem

function CollisionSystem.create()
    local self = setmetatable(System.create("CollisionSystem"), CollisionSystem)
    
    -- Set required components
    self:requires("transform", "collider")
    
    -- Set priority (run before physics)
    self:setPriority(10)
    
    -- Create spatial grid
    self.spatialGrid = SpatialPartition.createGrid(64, {
        minX = -10000,
        minY = -10000,
        maxX = 10000,
        maxY = 10000
    })
    
    -- Debug drawing
    self.debugDraw = false
    
    return self
end

-- Update the collision system
function CollisionSystem:update(dt, entityManager)
    -- Get all entities with transform and collider components
    local entities = entityManager:getEntitiesWith("transform", "collider")
    
    -- Check for collisions between entities
    for i = 1, #entities do
        local entityA = entities[i]
        
        -- Skip inactive entities
        if not entityA.active then goto continue end
        
        -- Get components
        local transformA = entityA:getComponent("transform")
        local colliderA = entityA:getComponent("collider")
        
        -- Skip entities without proper components
        if not transformA or not transformA.position or not colliderA then goto continue end
        
        -- Check collision with other entities
        for j = i + 1, #entities do
            local entityB = entities[j]
            
            -- Skip inactive entities
            if not entityB.active then goto continue_inner end
            
            -- Get components
            local transformB = entityB:getComponent("transform")
            local colliderB = entityB:getComponent("collider")
            
            -- Skip entities without proper components
            if not transformB or not transformB.position or not colliderB then goto continue_inner end
            
            -- Check if layers can collide
            if not self:canLayersCollide(colliderA.layer, colliderB.layer, 
                                        colliderA.collidesWithLayers, colliderB.collidesWithLayers) then
                goto continue_inner
            end
            
            -- Check for collision
            local collision = self:checkCollision(
                transformA.position.x, transformA.position.y, 
                transformB.position.x, transformB.position.y,
                transformA.size.width, transformA.size.height,
                transformB.size.width, transformB.size.height
            )
            
            -- Handle collision if detected
            if collision then
                self:handleCollision(entityA, entityB, collision, entityManager)
            end
            
            ::continue_inner::
        end
        
        ::continue::
    end
end

-- Check if two layers can collide
function CollisionSystem:canLayersCollide(layerA, layerB, collidesWithLayersA, collidesWithLayersB)
    -- Check if A can collide with B's layer
    local aCanCollideWithB = false
    for _, layer in ipairs(collidesWithLayersA) do
        if layer == layerB then
            aCanCollideWithB = true
            break
        end
    end
    
    -- Check if B can collide with A's layer
    local bCanCollideWithA = false
    for _, layer in ipairs(collidesWithLayersB) do
        if layer == layerA then
            bCanCollideWithA = true
            break
        end
    end
    
    -- If either can collide with the other, we should check collision
    return aCanCollideWithB or bCanCollideWithA
end

-- Update the checkCollision method to handle AABB collision detection
function CollisionSystem:checkCollision(x1, y1, x2, y2, w1, h1, w2, h2)
    -- Check for AABB collision
    local collision = x1 < x2 + w2 and
                     x1 + w1 > x2 and
                     y1 < y2 + h2 and
                     y1 + h1 > y2
    
    if collision then
        -- Calculate collision normal and penetration depth
        local dx = (x1 + w1/2) - (x2 + w2/2)
        local dy = (y1 + h1/2) - (y2 + h2/2)
        
        -- Calculate penetration depths in each axis
        local px = (w1 + w2)/2 - math.abs(dx)
        local py = (h1 + h2)/2 - math.abs(dy)
        
        -- Determine collision normal based on smallest penetration
        local nx, ny = 0, 0
        if px < py then
            nx = dx < 0 and -1 or 1
            ny = 0
        else
            nx = 0
            ny = dy < 0 and -1 or 1
        end
        
        -- Debug output
        -- print("Collision detected between entities")
        
        -- Calculate collision point
        local pointX = dx < 0 and (x1 + w1) or x2
        local pointY = dy < 0 and (y1 + h1) or y2
        
        -- Determine if collision is from above
        local fromAbove = ny < 0
        
        return {
            normal = {x = nx, y = ny},
            penetration = {x = px * nx, y = py * ny},
            point = {
                x = pointX,
                y = pointY
            },
            fromAbove = fromAbove
        }
    end
    
    return false
end

-- Handle collision between two entities
function CollisionSystem:handleCollision(entityA, entityB, collisionData, entityManager)
    -- Get entity types
    local typeA = entityA:getComponent("type") and entityA:getComponent("type").name or "entity"
    local typeB = entityB:getComponent("type") and entityB:getComponent("type").name or "entity"
    
    -- Debug output
    -- print("Collision between " .. typeA .. " and " .. typeB)
    
    -- Fire general collision event
    Events.fire("collision", {
        entityA = entityA,
        entityB = entityB,
        collisionData = collisionData
    })
    
    -- Fire entity-specific collision events
    Events.fire("collision:" .. typeA, {
        entity = entityA,
        other = entityB,
        collisionData = collisionData
    })
    
    Events.fire("collision:" .. typeA .. ":" .. typeB, {
        entityA = entityA,
        entityB = entityB,
        collisionData = collisionData
    })
    
    -- Get the original entities if they exist
    local originalEntityA = entityA.originalEntity
    local originalEntityB = entityB.originalEntity
    
    -- Call onCollision methods on original entities if they exist
    if originalEntityA and originalEntityA.onCollision then
        originalEntityA:onCollision(originalEntityB or entityB, collisionData)
    end
    
    if originalEntityB and originalEntityB.onCollision then
        -- Flip the normal for the second entity
        local flippedCollisionData = {
            normal = { x = -collisionData.normal.x, y = -collisionData.normal.y },
            penetration = { x = -collisionData.penetration.x, y = -collisionData.penetration.y },
            point = collisionData.point,
            fromAbove = collisionData.normal.y > 0 -- Flip the fromAbove check
        }
        originalEntityB:onCollision(originalEntityA or entityA, flippedCollisionData)
    end
    
    -- Call onCollision methods if they exist on the ECS entities
    if entityA.onCollision then
        entityA:onCollision(entityB, collisionData)
    end
    
    if entityB.onCollision then
        -- Flip the normal for the second entity
        local flippedCollisionData = {
            normal = { x = -collisionData.normal.x, y = -collisionData.normal.y },
            penetration = { x = -collisionData.penetration.x, y = -collisionData.penetration.y },
            point = collisionData.point,
            fromAbove = collisionData.normal.y > 0 -- Flip the fromAbove check
        }
        entityB:onCollision(entityA, flippedCollisionData)
    end
end

-- Update the draw method to handle the entityManager parameter
function CollisionSystem:draw(entityManager)
    -- Only draw if debug mode is enabled
    if not self.debugDraw then
        return
    end
    
    -- Set debug drawing color
    love.graphics.setColor(1, 0, 0, 0.5)
    
    -- Draw all collision bounds
    for _, entity in ipairs(entityManager:getEntitiesWith("transform", "collider")) do
        if entity.active then
            local transform = entity:getComponent("transform")
            local collider = entity:getComponent("collider")
            
            -- Skip if missing required components or if transform doesn't have position
            if not transform or not transform.position or not collider then
                goto continue
            end
            
            -- Draw collision box
            love.graphics.rectangle(
                "line",
                transform.position.x,
                transform.position.y,
                transform.size.width,
                transform.size.height
            )
            
            -- Draw entity type if available
            local typeComponent = entity:getComponent("type")
            if typeComponent and typeComponent.type then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.print(
                    typeComponent.type,
                    transform.position.x,
                    transform.position.y - 15
                )
                love.graphics.setColor(1, 0, 0, 0.5)
            end
            
            ::continue::
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Toggle debug drawing
function CollisionSystem:toggleDebugDraw()
    self.debugDraw = not self.debugDraw
end

return CollisionSystem 