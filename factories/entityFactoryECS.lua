-- Entity Factory with ECS support
local EntityFactoryECS = {}

-- Import traditional entities
local Player = require("entities/player")
local Platform = require("entities/platform")
local MovingPlatform = require("entities/movingPlatform")
local Springboard = require("entities/springboard")
local Slime = require("entities/slime")
local XpPellet = require("entities/xpPellet")

-- Import ECS entities
local ECSEntity = require("entities/ecsEntity")
local PlayerECS = require("entities/playerECS") -- Now implemented
local PlatformECS = require("entities/platformECS")
local MovingPlatformECS = require("entities/movingPlatformECS")
local SpringboardECS = require("entities/springboardECS")
local SlimeECS = require("entities/slimeECS")
local XpPelletECS = require("entities/xpPelletECS")

-- ECS world reference
local ecsWorld = nil

-- Set the ECS world reference
function EntityFactoryECS.setECSWorld(world)
    ecsWorld = world
    ECSEntity.setECSWorld(world)
end

-- Create an entity (traditional or ECS-based)
function EntityFactoryECS.createEntity(type, x, y, useECS, ...)
    -- Default to traditional entities if useECS is not specified
    useECS = useECS or false
    
    if useECS then
        -- Create ECS-based entities
        if type == "player" then
            -- Player ECS is now implemented
            return PlayerECS:new(x, y, ...)
        elseif type == "platform" then
            local width, height = ...
            return PlatformECS:new(x, y, width or 100, height or 20)
        elseif type == "movingPlatform" then
            local width, height, speed, distance = ...
            return MovingPlatformECS:new(x, y, width or 100, height or 20, speed or 50, distance or 200)
        elseif type == "springboard" then
            local width, height = ...
            return SpringboardECS:new(x, y, width or 50, height or 20)
        elseif type == "slime" then
            local platform = ...
            return SlimeECS:new(x, y, platform)
        elseif type == "xpPellet" then
            local value = ...
            local pellet = XpPelletECS:new(x, y, value or 1)
            pellet.collectible = true
            pellet.magnetizable = true
            return pellet
        else
            error("Unknown entity type: " .. type)
        end
    else
        -- Create traditional entities
        if type == "player" then
            return Player:new(x, y, ...)
        elseif type == "platform" then
            local width, height = ...
            return Platform:new(x, y, width or 100, height or 20)
        elseif type == "movingPlatform" then
            local width, height, speed, distance = ...
            return MovingPlatform:new(x, y, width or 100, height or 20, speed or 50, distance or 200)
        elseif type == "springboard" then
            local width, height = ...
            return Springboard:new(x, y, width or 50, height or 20)
        elseif type == "slime" then
            local platform = ...
            return Slime:new(x, y, platform)
        elseif type == "xpPellet" then
            local value = ...
            return XpPellet:new(x, y, value or 1)
        else
            error("Unknown entity type: " .. type)
        end
    end
end

-- Create multiple entities of the same type
function EntityFactoryECS.createEntities(type, positions, useECS, ...)
    local entities = {}
    for _, pos in ipairs(positions) do
        table.insert(entities, EntityFactoryECS.createEntity(type, pos.x, pos.y, useECS, ...))
    end
    return entities
end

-- Create a batch of entities from a configuration table
function EntityFactoryECS.createBatch(entityConfigs, useECS)
    local entities = {}
    for _, config in ipairs(entityConfigs) do
        local entity = EntityFactoryECS.createEntity(
            config.type, 
            config.x, 
            config.y, 
            useECS or config.useECS, 
            unpack(config.params or {})
        )
        table.insert(entities, entity)
    end
    return entities
end

return EntityFactoryECS 