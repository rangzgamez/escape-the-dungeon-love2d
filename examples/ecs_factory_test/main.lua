-- examples/ecs_factory_test/main.lua
-- Test script for the ECS entity factory

-- Add the parent directory to the package path so we can require modules from the main project
package.path = package.path .. ";../../?.lua"

local ECS = require("lib/ecs/ecs")
local Bridge = require("lib/ecs/bridge")
local EntityFactoryECS = require("factories/entityFactoryECS")
local Events = require("lib/events")

-- Example instance
local world
local entities = {}
local useECS = true -- Toggle between traditional and ECS entities

function love.load()
    -- Create an ECS world
    world = Bridge.createWorld()
    
    -- Set the ECS world for the entity factory
    EntityFactoryECS.setECSWorld(world)
    
    -- Create entities using the factory
    local entityConfigs = {
        { type = "platform", x = 100, y = 400, params = {300, 20} },
        { type = "movingPlatform", x = 500, y = 300, params = {100, 20, 50, 200} },
        { type = "springboard", x = 250, y = 380, params = {50, 20} },
        { type = "slime", x = 200, y = 380, params = {} }
    }
    
    -- Create a batch of entities
    local batchEntities = EntityFactoryECS.createBatch(entityConfigs, useECS)
    for _, entity in ipairs(batchEntities) do
        table.insert(entities, entity)
    end
    
    -- Create some XP pellets individually
    for i = 1, 5 do
        local x = love.math.random(50, 750)
        local y = love.math.random(50, 250)
        local value = love.math.random(1, 5)
        
        local pellet = EntityFactoryECS.createEntity("xpPellet", x, y, useECS, value)
        table.insert(entities, pellet)
    end
    
    -- Set up collision event handler
    Events.on("collision", function(data)
        print("Collision between entities!")
    end)
end

function love.update(dt)
    -- Update the ECS world if using ECS entities
    if useECS then
        world:update(dt)
    end
    
    -- Update entities
    for _, entity in ipairs(entities) do
        entity:update(dt)
    end
end

function love.draw()
    -- Draw entities
    for _, entity in ipairs(entities) do
        entity:draw()
    end
    
    -- Draw debug info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ECS Factory Test", 10, 10)
    love.graphics.print("Entities: " .. #entities, 10, 30)
    love.graphics.print("Using ECS: " .. tostring(useECS), 10, 50)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 70)
    
    -- Draw entity types
    local y = 90
    for i, entity in ipairs(entities) do
        love.graphics.print(i .. ": " .. entity.type, 10, y)
        y = y + 20
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "space" then
        -- Create a new XP pellet at a random position
        local x = love.math.random(50, 750)
        local y = love.math.random(50, 250)
        local value = love.math.random(1, 5)
        
        local pellet = EntityFactoryECS.createEntity("xpPellet", x, y, useECS, value)
        table.insert(entities, pellet)
    elseif key == "t" then
        -- Toggle between traditional and ECS entities
        useECS = not useECS
        
        -- Clear existing entities
        entities = {}
        
        -- Recreate entities with the new mode
        local entityConfigs = {
            { type = "platform", x = 100, y = 400, params = {300, 20} },
            { type = "movingPlatform", x = 500, y = 300, params = {100, 20, 50, 200} },
            { type = "springboard", x = 250, y = 380, params = {50, 20} },
            { type = "slime", x = 200, y = 380, params = {} }
        }
        
        -- Create a batch of entities
        local batchEntities = EntityFactoryECS.createBatch(entityConfigs, useECS)
        for _, entity in ipairs(batchEntities) do
            table.insert(entities, entity)
        end
        
        -- Create some XP pellets individually
        for i = 1, 5 do
            local x = love.math.random(50, 750)
            local y = love.math.random(50, 250)
            local value = love.math.random(1, 5)
            
            local pellet = EntityFactoryECS.createEntity("xpPellet", x, y, useECS, value)
            table.insert(entities, pellet)
        end
    end
end 