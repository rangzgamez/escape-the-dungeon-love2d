-- lib/ecs/entity.lua
-- Entity class for the Entity Component System

local Entity = {}
Entity.__index = Entity

-- Entity ID counter
local nextEntityId = 1

-- Create a new entity
function Entity.create()
    local self = setmetatable({}, Entity)
    
    -- Unique identifier
    self.id = nextEntityId
    nextEntityId = nextEntityId + 1
    
    -- Components table - stores all components by type
    self.components = {}
    
    -- Tags for quick filtering
    self.tags = {}
    
    -- Active state
    self.active = true
    
    -- World reference (set when added to a world)
    self.world = nil
    
    return self
end

-- Create a new entity with a specific ID (for deserialization)
function Entity.createWithId(id)
    local self = setmetatable({}, Entity)
    
    -- Set the provided ID
    self.id = id
    
    -- Update the next ID if necessary to avoid collisions
    if id >= nextEntityId then
        nextEntityId = id + 1
    end
    
    -- Components table - stores all components by type
    self.components = {}
    
    -- Tags for quick filtering
    self.tags = {}
    
    -- Active state
    self.active = true
    
    -- World reference (set when added to a world)
    self.world = nil
    
    return self
end

-- Get the next entity ID (for serialization)
function Entity.getNextId()
    return nextEntityId
end

-- Set the next entity ID (for deserialization)
function Entity.setNextId(id)
    nextEntityId = id
end

-- Set the world reference
function Entity:setWorld(world)
    self.world = world
    return self
end

-- Add a component to this entity
function Entity:addComponent(componentType, data)
    -- Create a copy of the data to avoid reference issues
    local component = {}
    for k, v in pairs(data or {}) do
        component[k] = v
    end
    
    -- Store the component
    local oldComponent = self.components[componentType]
    self.components[componentType] = component
    
    -- Emit component added event if we have a world reference
    if self.world then
        self.world:emit("componentAdded", {
            entity = self,
            componentType = componentType,
            component = component,
            oldComponent = oldComponent
        })
    end
    
    return self
end

-- Get a component by type
function Entity:getComponent(componentType)
    return self.components[componentType]
end

-- Check if entity has a component
function Entity:hasComponent(componentType)
    return self.components[componentType] ~= nil
end

-- Remove a component
function Entity:removeComponent(componentType)
    local component = self.components[componentType]
    self.components[componentType] = nil
    
    -- Emit component removed event if we have a world reference
    if component and self.world then
        self.world:emit("componentRemoved", {
            entity = self,
            componentType = componentType,
            component = component
        })
    end
    
    return self
end

-- Add a tag to this entity
function Entity:addTag(tag)
    local hadTag = self.tags[tag]
    self.tags[tag] = true
    
    -- Emit tag added event if we have a world reference and the tag wasn't already there
    if not hadTag and self.world then
        self.world:emit("tagAdded", {
            entity = self,
            tag = tag
        })
    end
    
    return self
end

-- Check if entity has a tag
function Entity:hasTag(tag)
    return self.tags[tag] == true
end

-- Remove a tag
function Entity:removeTag(tag)
    local hadTag = self.tags[tag]
    self.tags[tag] = nil
    
    -- Emit tag removed event if we have a world reference and the tag was there
    if hadTag and self.world then
        self.world:emit("tagRemoved", {
            entity = self,
            tag = tag
        })
    end
    
    return self
end

-- Deactivate this entity
function Entity:deactivate()
    local wasActive = self.active
    self.active = false
    
    -- Emit entity deactivated event if we have a world reference and it was active
    if wasActive and self.world then
        self.world:emit("entityDeactivated", {
            entity = self
        })
    end
    
    return self
end

-- Activate this entity
function Entity:activate()
    local wasInactive = not self.active
    self.active = true
    
    -- Emit entity activated event if we have a world reference and it was inactive
    if wasInactive and self.world then
        self.world:emit("entityActivated", {
            entity = self
        })
    end
    
    return self
end

-- Reset this entity (for pooling)
function Entity:reset()
    -- Emit entity reset event if we have a world reference
    if self.world then
        self.world:emit("entityReset", {
            entity = self,
            oldComponents = self.components,
            oldTags = self.tags
        })
    end
    
    self.components = {}
    self.tags = {}
    self.active = true
    
    return self
end

-- Destroy this entity
function Entity:destroy()
    -- Deactivate first
    self:deactivate()
    
    -- Emit entity destroyed event if we have a world reference
    if self.world then
        self.world:emit("entityDestroyed", {
            entity = self
        })
    end
    
    return self
end

return Entity 