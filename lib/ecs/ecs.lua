-- lib/ecs/ecs.lua
-- Main ECS module that brings everything together

local EntityManager = require("lib/ecs/entityManager")
local SystemManager = require("lib/ecs/systemManager")
local Entity = require("lib/ecs/entity")
local System = require("lib/ecs/system")
local Serialization = require("lib/ecs/serialization")
local EventSystem = require("lib/ecs/eventSystem")
local ComponentTemplate = require("lib/ecs/componentTemplate")
local SpatialPartition = require("lib/ecs/spatialPartition")

local ECS = {}

-- Create a new ECS world
function ECS.createWorld(spatialConfig)
    local world = {}
    
    -- Create the event system first
    world.eventSystem = EventSystem.createEventBus()
    
    -- Create managers with reference to the world
    world.entityManager = EntityManager.create(world)
    world.systemManager = SystemManager.create()
    
    -- Create spatial partitioning grid
    if spatialConfig then
        world.spatialGrid = SpatialPartition.createGrid(
            spatialConfig.cellSize,
            spatialConfig.worldBounds
        )
    else
        -- Create with default settings
        world.spatialGrid = SpatialPartition.createGrid()
    end
    
    -- Update all systems
    world.update = function(self, dt)
        self.systemManager:update(dt, self.entityManager)
        self.entityManager:cleanup()
        self.eventSystem:processEvents() -- Process events after systems have been updated
    end
    
    -- Draw all systems
    world.draw = function(self)
        self.systemManager:draw(self.entityManager)
    end
    
    -- Debug draw the spatial grid
    world.debugDrawSpatialGrid = function(self)
        self.spatialGrid:debugDraw()
    end
    
    -- Create a new entity
    world.createEntity = function(self)
        local entity = self.entityManager:createEntity()
        -- Emit an entity created event
        self.eventSystem:emit("entityCreated", { entity = entity })
        return entity
    end
    
    -- Create an entity from a template
    world.createEntityFromTemplate = function(self, templateName, overrides)
        -- Emit a template entity creation event
        self.eventSystem:emit("entityTemplateCreating", { 
            templateName = templateName,
            overrides = overrides
        })
        
        local entity = ComponentTemplate.createEntity(self, templateName, overrides)
        
        -- Emit a template entity created event
        self.eventSystem:emit("entityTemplateCreated", { 
            entity = entity,
            templateName = templateName,
            overrides = overrides
        })
        
        -- Add to spatial grid if it has a position component
        if entity:hasComponent("position") then
            self.spatialGrid:insertEntity(entity)
        end
        
        return entity
    end
    
    -- Apply a template to an existing entity
    world.applyTemplate = function(self, entity, templateName, overrides)
        -- Emit a template applying event
        self.eventSystem:emit("entityTemplateApplying", { 
            entity = entity,
            templateName = templateName,
            overrides = overrides
        })
        
        ComponentTemplate.applyToEntity(entity, templateName, overrides)
        
        -- Emit a template applied event
        self.eventSystem:emit("entityTemplateApplied", { 
            entity = entity,
            templateName = templateName,
            overrides = overrides
        })
        
        -- Update in spatial grid if it has a position component
        if entity:hasComponent("position") then
            self.spatialGrid:updateEntity(entity)
        end
        
        return entity
    end
    
    -- Register a component template
    world.registerTemplate = function(self, name, components)
        local template = ComponentTemplate.register(name, components)
        
        -- Emit a template registered event
        self.eventSystem:emit("templateRegistered", { 
            name = name,
            components = components,
            template = template
        })
        
        return template
    end
    
    -- Extend a component template
    world.extendTemplate = function(self, baseName, newName, additionalComponents, overrides)
        local template = ComponentTemplate.extend(baseName, newName, additionalComponents, overrides)
        
        -- Emit a template extended event
        self.eventSystem:emit("templateExtended", { 
            baseName = baseName,
            newName = newName,
            additionalComponents = additionalComponents,
            overrides = overrides,
            template = template
        })
        
        return template
    end
    
    -- Get a pooled entity
    world.getPooledEntity = function(self, poolName)
        local entity = self.entityManager:getPooledEntity(poolName)
        if entity then
            -- Emit an entity created event (from pool)
            self.eventSystem:emit("entityCreated", { entity = entity, fromPool = true, poolName = poolName })
            
            -- Add to spatial grid if it has a position component
            if entity:hasComponent("position") then
                self.spatialGrid:insertEntity(entity)
            end
        end
        return entity
    end
    
    -- Return an entity to its pool
    world.returnToPool = function(self, entity)
        -- Remove from spatial grid
        self.spatialGrid:removeEntity(entity)
        
        local result = self.entityManager:returnToPool(entity)
        if result then
            -- Emit an entity returned to pool event
            self.eventSystem:emit("entityReturnedToPool", { entity = entity })
        end
        return result
    end
    
    -- Add a system
    world.addSystem = function(self, system)
        local result = self.systemManager:addSystem(system)
        -- Emit a system added event
        self.eventSystem:emit("systemAdded", { system = system })
        return result
    end
    
    -- Create and add a system
    world.createSystem = function(self, name)
        local system = System.create(name)
        self.systemManager:addSystem(system)
        -- Emit a system created event
        self.eventSystem:emit("systemCreated", { system = system, name = name })
        return system
    end
    
    -- Get entities with components
    world.getEntitiesWith = function(self, ...)
        return self.entityManager:getEntitiesWith(...)
    end
    
    -- Get entities with tag
    world.getEntitiesWithTag = function(self, tag)
        return self.entityManager:getEntitiesWithTag(tag)
    end
    
    -- Get entities created from a specific template
    world.getEntitiesFromTemplate = function(self, templateName)
        return self.entityManager:getEntitiesWithTag("template:" .. templateName)
    end
    
    -- Get entities in a radius around a point
    world.getEntitiesInRadius = function(self, x, y, radius)
        return self.spatialGrid:getEntitiesInRadius(x, y, radius)
    end
    
    -- Get entities in a rectangle
    world.getEntitiesInRect = function(self, x, y, width, height)
        return self.spatialGrid:getEntitiesInRect(x, y, width, height)
    end
    
    -- Get potential collision pairs
    world.getPotentialCollisionPairs = function(self)
        return self.spatialGrid:getPotentialCollisionPairs()
    end
    
    -- Update entity position in spatial grid
    world.updateEntityPosition = function(self, entity)
        if entity:hasComponent("position") then
            self.spatialGrid:updateEntity(entity)
        end
    end
    
    -- Serialize the world to a table
    world.serialize = function(self)
        return Serialization.serializeWorld(self)
    end
    
    -- Save the world to a file
    world.saveToFile = function(self, filename)
        local result, message = Serialization.saveWorldToFile(self, filename)
        if result then
            -- Emit a world saved event
            self.eventSystem:emit("worldSaved", { filename = filename })
        else
            -- Emit a world save failed event
            self.eventSystem:emit("worldSaveFailed", { filename = filename, error = message })
        end
        return result, message
    end
    
    -- Register an event listener
    world.on = function(self, eventType, callback)
        return self.eventSystem.on(eventType, callback)
    end
    
    -- Remove an event listener
    world.off = function(self, handle)
        return self.eventSystem.off(handle)
    end
    
    -- Emit an event
    world.emit = function(self, eventType, data)
        return self.eventSystem.emit(eventType, data)
    end
    
    -- Listen for component changes to update spatial grid
    world:on("componentAdded", function(data)
        if data.componentType == "position" then
            world.spatialGrid:insertEntity(data.entity)
        end
    end)
    
    world:on("componentRemoved", function(data)
        if data.componentType == "position" then
            world.spatialGrid:removeEntity(data.entity)
        end
    end)
    
    world:on("entityRemoved", function(data)
        world.spatialGrid:removeEntity(data.entity)
    end)
    
    return world
end

-- Create a new entity (standalone)
function ECS.createEntity()
    return Entity.create()
end

-- Create a new system (standalone)
function ECS.createSystem(name)
    return System.create(name)
end

-- Load a world from serialized data
function ECS.deserializeWorld(serialized, spatialConfig)
    local world = Serialization.deserializeWorld(serialized, spatialConfig)
    if world then
        -- Set the world reference for all entities
        world.entityManager:setWorld(world)
        
        -- Rebuild spatial grid
        world.spatialGrid:clear()
        for _, entity in ipairs(world.entityManager.entities) do
            if entity:hasComponent("position") then
                world.spatialGrid:insertEntity(entity)
            end
        end
        
        -- Emit a world loaded event
        world.eventSystem:emit("worldLoaded", { serialized = serialized })
    end
    return world
end

-- Load a world from a file
function ECS.loadWorldFromFile(filename, spatialConfig)
    local world, error = Serialization.loadWorldFromFile(filename, spatialConfig)
    if world then
        -- Set the world reference for all entities
        world.entityManager:setWorld(world)
        
        -- Rebuild spatial grid
        world.spatialGrid:clear()
        for _, entity in ipairs(world.entityManager.entities) do
            if entity:hasComponent("position") then
                world.spatialGrid:insertEntity(entity)
            end
        end
        
        -- Emit a world loaded event
        world.eventSystem:emit("worldLoaded", { filename = filename })
    end
    return world, error
end

-- Global event system (for cross-world communication)
ECS.events = EventSystem

-- Component template system
ECS.templates = ComponentTemplate

-- Spatial partitioning system
ECS.spatial = SpatialPartition

return ECS 