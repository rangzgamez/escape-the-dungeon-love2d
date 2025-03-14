-- lib/ecs/systemManager.lua
-- System Manager for the Entity Component System

local SystemManager = {}
SystemManager.__index = SystemManager

function SystemManager.create()
    local self = setmetatable({}, SystemManager)
    
    -- All systems in the manager
    self.systems = {}
    
    -- Systems by name for quick lookup
    self.systemsByName = {}
    
    return self
end

-- Add a system to the manager
function SystemManager:addSystem(system)
    -- Store in main systems list
    table.insert(self.systems, system)
    
    -- Store by name for quick lookup
    self.systemsByName[system.name] = system
    
    -- Sort systems by priority
    table.sort(self.systems, function(a, b)
        return a.priority < b.priority
    end)
    
    return system
end

-- Get a system by name
function SystemManager:getSystem(name)
    return self.systemsByName[name]
end

-- Update all systems
function SystemManager:update(dt, entityManager)
    for _, system in ipairs(self.systems) do
        if system.active and system.update then
            system:update(dt, entityManager)
        end
    end
end

-- Draw all systems
function SystemManager:draw(entityManager)
    for _, system in ipairs(self.systems) do
        if system.active and system.draw then
            system:draw(entityManager)
        end
    end
end

-- Activate a system by name
function SystemManager:activateSystem(name)
    local system = self:getSystem(name)
    if system then
        system:activate()
    end
end

-- Deactivate a system by name
function SystemManager:deactivateSystem(name)
    local system = self:getSystem(name)
    if system then
        system:deactivate()
    end
end

return SystemManager 