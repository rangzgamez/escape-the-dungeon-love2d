-- examples/serialization_example.lua
-- Example demonstrating the serialization functionality of the ECS system

local ECS = require("lib/ecs/ecs")

-- Create a new world
local world = ECS.createWorld()

-- Create some entities with components
local player = world:createEntity()
player:addComponent("position", { x = 100, y = 100 })
player:addComponent("velocity", { x = 0, y = 0 })
player:addComponent("sprite", { image = "player.png", width = 32, height = 32 })
player:addComponent("health", { current = 100, max = 100 })
player:addTag("player")

local enemy1 = world:createEntity()
enemy1:addComponent("position", { x = 200, y = 150 })
enemy1:addComponent("velocity", { x = -10, y = 0 })
enemy1:addComponent("sprite", { image = "enemy.png", width = 24, height = 24 })
enemy1:addComponent("health", { current = 50, max = 50 })
enemy1:addTag("enemy")

local enemy2 = world:createEntity()
enemy2:addComponent("position", { x = 300, y = 200 })
enemy2:addComponent("velocity", { x = -5, y = 5 })
enemy2:addComponent("sprite", { image = "enemy.png", width = 24, height = 24 })
enemy2:addComponent("health", { current = 50, max = 50 })
enemy2:addTag("enemy")

-- Create a simple movement system
local movementSystem = world:createSystem("movement")
movementSystem:addComponentRequirement("position")
movementSystem:addComponentRequirement("velocity")
movementSystem:setUpdateFunction(function(dt, entity)
    local position = entity:getComponent("position")
    local velocity = entity:getComponent("velocity")
    
    position.x = position.x + velocity.x * dt
    position.y = position.y + velocity.y * dt
end)

-- Simulate a few updates
print("Simulating game updates...")
for i = 1, 5 do
    world:update(0.1)
    
    -- Print player position
    local playerPos = player:getComponent("position")
    print(string.format("Player position: (%.1f, %.1f)", playerPos.x, playerPos.y))
end

-- Save the world state to a file
print("\nSaving world state...")
local success, message = world:saveToFile("save_game.json")
if success then
    print("World saved successfully!")
else
    print("Failed to save world: " .. message)
end

-- Create a new world and load the saved state
print("\nLoading world state...")
local loadedWorld = ECS.loadWorldFromFile("save_game.json")
if loadedWorld then
    print("World loaded successfully!")
    
    -- Find the player in the loaded world
    local loadedPlayers = loadedWorld:getEntitiesWithTag("player")
    if #loadedPlayers > 0 then
        local loadedPlayer = loadedPlayers[1]
        local loadedPlayerPos = loadedPlayer:getComponent("position")
        print(string.format("Loaded player position: (%.1f, %.1f)", loadedPlayerPos.x, loadedPlayerPos.y))
    end
    
    -- Find enemies in the loaded world
    local loadedEnemies = loadedWorld:getEntitiesWithTag("enemy")
    print("Loaded " .. #loadedEnemies .. " enemies")
    for i, enemy in ipairs(loadedEnemies) do
        local pos = enemy:getComponent("position")
        print(string.format("Enemy %d position: (%.1f, %.1f)", i, pos.x, pos.y))
    end
    
    -- Continue simulation with loaded world
    print("\nContinuing simulation with loaded world...")
    
    -- Recreate the movement system (systems are not serialized)
    local newMovementSystem = loadedWorld:createSystem("movement")
    newMovementSystem:addComponentRequirement("position")
    newMovementSystem:addComponentRequirement("velocity")
    newMovementSystem:setUpdateFunction(function(dt, entity)
        local position = entity:getComponent("position")
        local velocity = entity:getComponent("velocity")
        
        position.x = position.x + velocity.x * dt
        position.y = position.y + velocity.y * dt
    end)
    
    -- Run a few more updates
    for i = 1, 5 do
        loadedWorld:update(0.1)
        
        -- Print player position
        local loadedPlayers = loadedWorld:getEntitiesWithTag("player")
        if #loadedPlayers > 0 then
            local loadedPlayer = loadedPlayers[1]
            local loadedPlayerPos = loadedPlayer:getComponent("position")
            print(string.format("Player position: (%.1f, %.1f)", loadedPlayerPos.x, loadedPlayerPos.y))
        end
    end
else
    print("Failed to load world")
end 