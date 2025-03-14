-- examples/spatial_partitioning_example.lua
-- Example demonstrating the spatial partitioning system of the ECS architecture

local ECS = require("lib/ecs/ecs")

-- Create a new world with custom spatial partitioning settings
local world = ECS.createWorld({
    cellSize = 100, -- 100 pixel cells
    worldBounds = {
        minX = -1000,
        minY = -1000,
        maxX = 1000,
        maxY = 1000
    }
})

-- Register event listeners for spatial events
print("Registering event listeners...")

world:on("entityCreated", function(data)
    print(string.format("Entity created: ID %d", data.entity.id))
end)

-- Create some entities with positions
print("\nCreating entities with positions...")

-- Create a player entity
local player = world:createEntity()
player:addComponent("position", { x = 0, y = 0 })
player:addComponent("velocity", { x = 0, y = 0 })
player:addComponent("sprite", { width = 32, height = 32 })
player:addTag("player")

-- Create some enemy entities
for i = 1, 20 do
    local enemy = world:createEntity()
    enemy:addComponent("position", {
        x = math.random(-500, 500),
        y = math.random(-500, 500)
    })
    enemy:addComponent("velocity", {
        x = math.random(-50, 50),
        y = math.random(-50, 50)
    })
    enemy:addComponent("sprite", { width = 24, height = 24 })
    enemy:addTag("enemy")
end

-- Create some collectible items
for i = 1, 50 do
    local item = world:createEntity()
    item:addComponent("position", {
        x = math.random(-800, 800),
        y = math.random(-800, 800)
    })
    item:addComponent("sprite", { width = 16, height = 16 })
    item:addTag("item")
end

-- Process events
world.eventSystem:processEvents()

-- Demonstrate spatial queries
print("\nDemonstrating spatial queries...")

-- Query entities in a radius around the player
local playerPos = player:getComponent("position")
local radius = 200
local nearbyEntities = world:getEntitiesInRadius(playerPos.x, playerPos.y, radius)

print(string.format("Found %d entities within %d pixels of the player:", #nearbyEntities, radius))
for _, entity in ipairs(nearbyEntities) do
    local pos = entity:getComponent("position")
    local tags = {}
    for tag, _ in pairs(entity.tags) do
        table.insert(tags, tag)
    end
    print(string.format("- Entity ID %d at position (%.1f, %.1f) with tags: %s", 
        entity.id, pos.x, pos.y, table.concat(tags, ", ")))
end

-- Query entities in a rectangle
local rectX, rectY = -100, -100
local rectWidth, rectHeight = 200, 200
local entitiesInRect = world:getEntitiesInRect(rectX, rectY, rectWidth, rectHeight)

print(string.format("\nFound %d entities in rectangle (%.1f, %.1f, %.1f, %.1f):", 
    #entitiesInRect, rectX, rectY, rectWidth, rectHeight))
for _, entity in ipairs(entitiesInRect) do
    local pos = entity:getComponent("position")
    local tags = {}
    for tag, _ in pairs(entity.tags) do
        table.insert(tags, tag)
    end
    print(string.format("- Entity ID %d at position (%.1f, %.1f) with tags: %s", 
        entity.id, pos.x, pos.y, table.concat(tags, ", ")))
end

-- Get potential collision pairs
local collisionPairs = world:getPotentialCollisionPairs()
print(string.format("\nFound %d potential collision pairs:", #collisionPairs))
for i, pair in ipairs(collisionPairs) do
    if i <= 10 then -- Only show first 10 pairs
        local pos1 = pair[1]:getComponent("position")
        local pos2 = pair[2]:getComponent("position")
        print(string.format("- Pair %d: Entity %d at (%.1f, %.1f) and Entity %d at (%.1f, %.1f)", 
            i, pair[1].id, pos1.x, pos1.y, pair[2].id, pos2.x, pos2.y))
    end
end
if #collisionPairs > 10 then
    print(string.format("... and %d more pairs", #collisionPairs - 10))
end

-- Demonstrate updating entity positions
print("\nDemonstrating entity position updates...")

-- Move the player
playerPos.x = 300
playerPos.y = 200
world:updateEntityPosition(player)

-- Query entities near the new player position
nearbyEntities = world:getEntitiesInRadius(playerPos.x, playerPos.y, radius)
print(string.format("After moving player to (%.1f, %.1f), found %d entities within %d pixels:", 
    playerPos.x, playerPos.y, #nearbyEntities, radius))
for _, entity in ipairs(nearbyEntities) do
    if entity.id ~= player.id then -- Skip the player itself
        local pos = entity:getComponent("position")
        local tags = {}
        for tag, _ in pairs(entity.tags) do
            table.insert(tags, tag)
        end
        print(string.format("- Entity ID %d at position (%.1f, %.1f) with tags: %s", 
            entity.id, pos.x, pos.y, table.concat(tags, ", ")))
    end
end

-- Demonstrate performance comparison
print("\nDemonstrating performance comparison...")

-- Function to measure execution time
local function measureTime(func)
    local startTime = os.clock()
    local result = func()
    local endTime = os.clock()
    return result, endTime - startTime
end

-- Query using spatial partitioning
local spatialResult, spatialTime = measureTime(function()
    return world:getEntitiesInRadius(playerPos.x, playerPos.y, radius)
end)

-- Query using brute force
local bruteForceResult, bruteForceTime = measureTime(function()
    local result = {}
    local radiusSq = radius * radius
    
    for _, entity in ipairs(world.entityManager.entities) do
        if entity.active and entity:hasComponent("position") then
            local pos = entity:getComponent("position")
            local dx = pos.x - playerPos.x
            local dy = pos.y - playerPos.y
            local distSq = dx * dx + dy * dy
            
            if distSq <= radiusSq then
                table.insert(result, entity)
            end
        end
    end
    
    return result
end)

print(string.format("Spatial partitioning query: Found %d entities in %.6f seconds", 
    #spatialResult, spatialTime))
print(string.format("Brute force query: Found %d entities in %.6f seconds", 
    #bruteForceResult, bruteForceTime))
print(string.format("Speedup factor: %.2fx", bruteForceTime / spatialTime))

print("\nSpatial partitioning example complete!") 