-- lib/ecs/system.lua
-- System class for the Entity Component System

local System = {}
System.__index = System

function System.create(name)
    local self = setmetatable({}, System)
    
    -- System name
    self.name = name or "UnnamedSystem"
    
    -- Required components for this system
    self.requiredComponents = {}
    
    -- System priority (lower numbers run first)
    self.priority = 0
    
    -- Active state
    self.active = true
    
    return self
end

-- Set the required components for this system
function System:requires(...)
    self.requiredComponents = {...}
    return self
end

-- Set the system priority
function System:setPriority(priority)
    self.priority = priority
    return self
end

-- Process a single entity
function System:processEntity(entity, dt)
    -- Override in derived systems
end

-- Update all matching entities
function System:update(dt, entityManager)
    if not self.active then return end
    
    -- Get all entities with the required components
    local entities = entityManager:getEntitiesWith(unpack(self.requiredComponents))
    
    -- Process each entity
    for _, entity in ipairs(entities) do
        self:processEntity(entity, dt)
    end
end

-- Draw all matching entities
function System:draw(entityManager)
    if not self.active then return end
    
    -- Get all entities with the required components
    local entities = entityManager:getEntitiesWith(unpack(self.requiredComponents))
    
    -- Draw each entity
    for _, entity in ipairs(entities) do
        self:drawEntity(entity)
    end
end

-- Draw a single entity
function System:drawEntity(entity)
    -- Override in derived systems
end

-- Activate the system
function System:activate()
    self.active = true
    return self
end

-- Deactivate the system
function System:deactivate()
    self.active = false
    return self
end

return System 