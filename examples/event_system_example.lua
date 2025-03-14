-- examples/event_system_example.lua
-- Example demonstrating the event system functionality of the ECS system

local ECS = require("lib/ecs/ecs")

-- Create a new world
local world = ECS.createWorld()

-- Register event listeners
print("Registering event listeners...")

-- Listen for entity created events
local entityCreatedHandle = world:on("entityCreated", function(data)
    print(string.format("Entity created: ID %d", data.entity.id))
end)

-- Listen for component added events
world:on("componentAdded", function(data)
    print(string.format("Component '%s' added to entity %d", data.componentType, data.entity.id))
end)

-- Listen for tag added events
world:on("tagAdded", function(data)
    print(string.format("Tag '%s' added to entity %d", data.tag, data.entity.id))
end)

-- Listen for entity deactivated events
world:on("entityDeactivated", function(data)
    print(string.format("Entity %d deactivated", data.entity.id))
end)

-- Create some entities with components and tags
print("\nCreating entities...")
local player = world:createEntity()
player:addComponent("position", { x = 100, y = 100 })
player:addComponent("velocity", { x = 0, y = 0 })
player:addTag("player")

local enemy = world:createEntity()
enemy:addComponent("position", { x = 200, y = 200 })
enemy:addComponent("velocity", { x = -10, y = 0 })
enemy:addTag("enemy")

-- Process events (normally this would happen automatically in world:update())
print("\nProcessing events...")
world.eventSystem:processEvents()

-- Remove an event listener
print("\nRemoving 'entityCreated' listener...")
world:off(entityCreatedHandle)

-- Create another entity (this won't trigger the entityCreated listener)
print("\nCreating another entity...")
local item = world:createEntity()
item:addComponent("position", { x = 150, y = 150 })
item:addTag("item")

-- Process events again
print("\nProcessing events...")
world.eventSystem:processEvents()

-- Demonstrate custom events
print("\nEmitting custom events...")
world:emit("gameStarted", { level = 1, difficulty = "normal" })
world:emit("playerScored", { points = 100, combo = 2 })

-- Listen for custom events
world:on("gameStarted", function(data)
    print(string.format("Game started: Level %d, Difficulty: %s", data.level, data.difficulty))
end)

world:on("playerScored", function(data)
    print(string.format("Player scored: %d points (combo: %dx)", data.points, data.combo))
end)

-- Process events again
print("\nProcessing events...")
world.eventSystem:processEvents()

-- Demonstrate event bus isolation
print("\nDemonstrating event bus isolation...")

-- Create a separate event bus
local privateBus = ECS.events.createEventBus()

-- Register a listener on the private bus
privateBus.on("privateEvent", function(data)
    print(string.format("Private event received: %s", data.message))
end)

-- Emit events on both buses
world:emit("globalEvent", { message = "This is a global event" })
privateBus.emit("privateEvent", { message = "This is a private event" })

-- Listen for the global event
world:on("globalEvent", function(data)
    print(string.format("Global event received: %s", data.message))
end)

-- Process events on both buses
print("\nProcessing events on both buses...")
world.eventSystem:processEvents()
privateBus.processEvents()

-- Demonstrate entity lifecycle events
print("\nDemonstrating entity lifecycle events...")

-- Listen for entity deactivation
world:on("entityDeactivated", function(data)
    print(string.format("Entity %d was deactivated", data.entity.id))
end)

-- Listen for entity removal
world:on("entityRemoved", function(data)
    print(string.format("Entity %d was removed", data.entity.id))
end)

-- Deactivate an entity
enemy:deactivate()

-- Process events
world.eventSystem:processEvents()

-- Clean up (this will remove the deactivated entity)
print("\nCleaning up entities...")
world.entityManager:cleanup()

-- Process events again
world.eventSystem:processEvents()

print("\nEvent system example complete!") 