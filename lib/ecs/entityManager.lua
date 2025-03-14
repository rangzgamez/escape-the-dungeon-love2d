-- lib/ecs/entityManager.lua
-- Entity Manager for the Entity Component System

local Entity = require("lib/ecs/entity")

local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.create(world)
    local self = setmetatable({}, EntityManager)
    
    -- All entities in the system
    self.entities = {}
    
    -- Entities by tag for quick lookup
    self.entitiesByTag = {}
    
    -- Entity pools for reuse
    self.entityPools = {}
    
    -- Reference to the world
    self.world = world
    
    return self
end

-- Create a new entity
function EntityManager:createEntity()
    local entity = Entity.create()
    
    -- Set the world reference
    if self.world then
        entity:setWorld(self.world)
    end
    
    table.insert(self.entities, entity)
    return entity
end

-- Add an existing entity to the manager
function EntityManager:addEntity(entity)
    -- Set the world reference
    if self.world then
        entity:setWorld(self.world)
    end
    
    table.insert(self.entities, entity)
    
    -- Register entity with its tags
    for tag, _ in pairs(entity.tags) do
        if not self.entitiesByTag[tag] then
            self.entitiesByTag[tag] = {}
        end
        table.insert(self.entitiesByTag[tag], entity)
    end
    
    return entity
end

-- Get an entity from a pool or create a new one
function EntityManager:getPooledEntity(poolName)
    -- Create the pool if it doesn't exist
    if not self.entityPools[poolName] then
        self.entityPools[poolName] = {}
    end
    
    -- Get an entity from the pool or create a new one
    local entity
    if #self.entityPools[poolName] > 0 then
        entity = table.remove(self.entityPools[poolName])
        entity:reset()
    else
        entity = self:createEntity()
        entity:addTag(poolName) -- Tag with pool name for identification
    end
    
    return entity
end

-- Return an entity to its pool
function EntityManager:returnToPool(entity)
    -- Find which pool this entity belongs to
    for tag, _ in pairs(entity.tags) do
        if self.entityPools[tag] then
            -- Deactivate and add to pool
            entity:deactivate()
            table.insert(self.entityPools[tag], entity)
            return true
        end
    end
    
    -- If no pool found, just deactivate
    entity:deactivate()
    return false
end

-- Register an entity with a tag
function EntityManager:registerEntityWithTag(entity, tag)
    -- Add the tag to the entity
    entity:addTag(tag)
    
    -- Create the tag group if it doesn't exist
    if not self.entitiesByTag[tag] then
        self.entitiesByTag[tag] = {}
    end
    
    -- Add to the tag group
    table.insert(self.entitiesByTag[tag], entity)
end

-- Get all entities with a specific tag
function EntityManager:getEntitiesWithTag(tag)
    return self.entitiesByTag[tag] or {}
end

-- Get all entities with a specific component
function EntityManager:getEntitiesWithComponent(componentType)
    local result = {}
    
    for _, entity in ipairs(self.entities) do
        if entity.active and entity:hasComponent(componentType) then
            table.insert(result, entity)
        end
    end
    
    return result
end

-- Get all entities with all of the specified components
function EntityManager:getEntitiesWith(...)
    local componentTypes = {...}
    local result = {}
    
    for _, entity in ipairs(self.entities) do
        if entity.active then
            local hasAllComponents = true
            
            for _, componentType in ipairs(componentTypes) do
                if not entity:hasComponent(componentType) then
                    hasAllComponents = false
                    break
                end
            end
            
            if hasAllComponents then
                table.insert(result, entity)
            end
        end
    end
    
    return result
end

-- Remove an entity from the manager
function EntityManager:removeEntity(entity)
    -- Emit entity removed event if we have a world reference
    if self.world then
        self.world:emit("entityRemoved", {
            entity = entity
        })
    end
    
    -- Remove from main entities list
    for i, e in ipairs(self.entities) do
        if e.id == entity.id then
            table.remove(self.entities, i)
            break
        end
    end
    
    -- Remove from tag groups
    for tag, entities in pairs(self.entitiesByTag) do
        for i, e in ipairs(entities) do
            if e.id == entity.id then
                table.remove(entities, i)
                break
            end
        end
    end
end

-- Clean up inactive entities
function EntityManager:cleanup()
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        if not entity.active then
            self:removeEntity(entity)
        end
    end
end

-- Set the world reference
function EntityManager:setWorld(world)
    self.world = world
    
    -- Update all existing entities
    for _, entity in ipairs(self.entities) do
        entity:setWorld(world)
    end
    
    -- Update all pooled entities
    for _, pool in pairs(self.entityPools) do
        for _, entity in ipairs(pool) do
            entity:setWorld(world)
        end
    end
    
    return self
end

return EntityManager 