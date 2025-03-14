-- lib/ecs/serialization.lua
-- Serialization module for the Entity Component System

local Serialization = {}

-- Serialize a single component
function Serialization.serializeComponent(component)
    local serialized = {}
    
    -- Handle special cases for non-serializable data
    for key, value in pairs(component) do
        -- Skip functions
        if type(value) ~= "function" then
            -- Handle special types
            if type(value) == "table" then
                -- Recursively serialize tables
                serialized[key] = Serialization.serializeTable(value)
            else
                -- Directly store primitive values
                serialized[key] = value
            end
        end
    end
    
    return serialized
end

-- Serialize a table (recursive helper)
function Serialization.serializeTable(tbl)
    local serialized = {}
    
    for key, value in pairs(tbl) do
        if type(value) == "function" then
            -- Skip functions
        elseif type(value) == "table" then
            -- Recursively serialize tables
            serialized[key] = Serialization.serializeTable(value)
        else
            -- Directly store primitive values
            serialized[key] = value
        end
    end
    
    return serialized
end

-- Serialize an entity
function Serialization.serializeEntity(entity)
    local serialized = {
        id = entity.id,
        active = entity.active,
        tags = {},
        components = {}
    }
    
    -- Serialize tags
    for tag, _ in pairs(entity.tags) do
        table.insert(serialized.tags, tag)
    end
    
    -- Serialize components
    for componentType, component in pairs(entity.components) do
        serialized.components[componentType] = Serialization.serializeComponent(component)
    end
    
    return serialized
end

-- Serialize multiple entities
function Serialization.serializeEntities(entities)
    local serialized = {}
    
    for _, entity in ipairs(entities) do
        table.insert(serialized, Serialization.serializeEntity(entity))
    end
    
    return serialized
end

-- Serialize component templates
function Serialization.serializeTemplates()
    local ComponentTemplate = require("lib/ecs/componentTemplate")
    local serialized = {}
    
    -- Get all template names
    local templateNames = ComponentTemplate.getTemplateNames()
    
    -- Serialize each template
    for _, name in ipairs(templateNames) do
        serialized[name] = Serialization.serializeTable(ComponentTemplate.getComponents(name))
    end
    
    return serialized
end

-- Serialize an entire ECS world
function Serialization.serializeWorld(world)
    local serialized = {
        entities = {},
        nextEntityId = require("lib/ecs/entity").getNextId(),
        templates = Serialization.serializeTemplates()
    }
    
    -- Serialize all active entities
    for _, entity in ipairs(world.entityManager.entities) do
        if entity.active then
            table.insert(serialized.entities, Serialization.serializeEntity(entity))
        end
    end
    
    return serialized
end

-- Deserialize a component
function Serialization.deserializeComponent(serialized)
    -- Simply return the serialized data, as components are just data tables
    return serialized
end

-- Deserialize an entity
function Serialization.deserializeEntity(serialized, world)
    local Entity = require("lib/ecs/entity")
    
    -- Create a new entity with the same ID
    local entity = Entity.createWithId(serialized.id)
    entity.active = serialized.active
    
    -- Add tags
    for _, tag in ipairs(serialized.tags) do
        entity:addTag(tag)
    end
    
    -- Add components
    for componentType, component in pairs(serialized.components) do
        entity:addComponent(componentType, Serialization.deserializeComponent(component))
    end
    
    return entity
end

-- Deserialize multiple entities
function Serialization.deserializeEntities(serialized, world)
    local entities = {}
    
    for _, entityData in ipairs(serialized) do
        table.insert(entities, Serialization.deserializeEntity(entityData, world))
    end
    
    return entities
end

-- Deserialize component templates
function Serialization.deserializeTemplates(serialized)
    local ComponentTemplate = require("lib/ecs/componentTemplate")
    
    -- Clear existing templates
    ComponentTemplate.clear()
    
    -- Register each template
    for name, components in pairs(serialized) do
        ComponentTemplate.register(name, components)
    end
end

-- Deserialize an entire ECS world
function Serialization.deserializeWorld(serialized, spatialConfig)
    local ECS = require("lib/ecs/ecs")
    local Entity = require("lib/ecs/entity")
    
    -- Set the next entity ID
    Entity.setNextId(serialized.nextEntityId)
    
    -- Deserialize templates
    if serialized.templates then
        Serialization.deserializeTemplates(serialized.templates)
    end
    
    -- Create a new world with spatial config if provided
    local world = ECS.createWorld(spatialConfig)
    
    -- Add all entities to the world
    for _, entityData in ipairs(serialized.entities) do
        local entity = Serialization.deserializeEntity(entityData, world)
        world.entityManager:addEntity(entity)
    end
    
    return world
end

-- Save a world to a file
function Serialization.saveWorldToFile(world, filename)
    local serialized = Serialization.serializeWorld(world)
    local success, message = love.filesystem.write(filename, require("lib/json").encode(serialized))
    return success, message
end

-- Load a world from a file
function Serialization.loadWorldFromFile(filename, spatialConfig)
    if not love.filesystem.getInfo(filename) then
        return nil, "File not found: " .. filename
    end
    
    local contents, size = love.filesystem.read(filename)
    if not contents then
        return nil, "Could not read file: " .. filename
    end
    
    local success, decoded = pcall(function() return require("lib/json").decode(contents) end)
    if not success then
        return nil, "Invalid JSON in file: " .. filename
    end
    
    return Serialization.deserializeWorld(decoded, spatialConfig)
end

return Serialization 