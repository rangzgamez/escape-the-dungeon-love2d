-- examples/component_template_example.lua
-- Example demonstrating the component template system of the ECS architecture

local ECS = require("lib/ecs/ecs")

-- Create a new world
local world = ECS.createWorld()

-- Register event listeners for template events
print("Registering event listeners...")

world:on("templateRegistered", function(data)
    print(string.format("Template registered: '%s'", data.name))
end)

world:on("templateExtended", function(data)
    print(string.format("Template extended: '%s' from '%s'", data.newName, data.baseName))
end)

world:on("entityTemplateCreated", function(data)
    print(string.format("Entity created from template '%s': ID %d", data.templateName, data.entity.id))
end)

-- Register some basic component templates
print("\nRegistering component templates...")

-- Register a basic physics template
world:registerTemplate("physics", {
    position = { x = 0, y = 0 },
    velocity = { x = 0, y = 0 },
    acceleration = { x = 0, y = 0 }
})

-- Register a basic renderable template
world:registerTemplate("renderable", {
    position = { x = 0, y = 0 },
    sprite = { image = "default.png", width = 32, height = 32 }
})

-- Register a basic health template
world:registerTemplate("health", {
    health = { current = 100, max = 100 },
    damageable = { isInvulnerable = false }
})

-- Extend templates to create more complex ones
print("\nExtending templates...")

-- Create a character template by extending physics and health
world:extendTemplate("physics", "character", {
    -- Additional components
    input = { moveSpeed = 100 },
    animation = { currentAnimation = "idle", frameTime = 0.1 }
}, {
    -- Overrides for existing components
    position = { x = 100, y = 100 }
})

-- Create a player template by extending character
world:extendTemplate("character", "player", {
    -- Additional components
    inventory = { maxItems = 10, items = {} },
    score = { value = 0 }
}, {
    -- Overrides
    health = { current = 200, max = 200 },
    input = { moveSpeed = 150 }
})

-- Create an enemy template by extending character
world:extendTemplate("character", "enemy", {
    -- Additional components
    ai = { type = "aggressive", detectionRadius = 200 },
    loot = { dropChance = 0.5, items = { "coin", "health_potion" } }
}, {
    -- Overrides
    health = { current = 50, max = 50 },
    input = { moveSpeed = 80 }
})

-- Create entities from templates
print("\nCreating entities from templates...")

-- Create a player entity
local player = world:createEntityFromTemplate("player", {
    -- Override some components
    position = { x = 150, y = 150 },
    sprite = { image = "player.png", width = 48, height = 48 }
})

-- Create some enemy entities
local enemy1 = world:createEntityFromTemplate("enemy", {
    position = { x = 300, y = 200 },
    ai = { type = "patrol", patrolRadius = 100 }
})

local enemy2 = world:createEntityFromTemplate("enemy", {
    position = { x = 400, y = 300 },
    health = { current = 75, max = 75 }
})

-- Create a simple item entity using the renderable template
local item = world:createEntityFromTemplate("renderable", {
    position = { x = 250, y = 250 },
    sprite = { image = "item.png", width = 16, height = 16 }
})

-- Process events
world.eventSystem:processEvents()

-- Demonstrate querying entities by template
print("\nQuerying entities by template...")

local playerEntities = world:getEntitiesFromTemplate("player")
print(string.format("Found %d player entities", #playerEntities))

local enemyEntities = world:getEntitiesFromTemplate("enemy")
print(string.format("Found %d enemy entities", #enemyEntities))

local renderableEntities = world:getEntitiesFromTemplate("renderable")
print(string.format("Found %d renderable entities", #renderableEntities))

-- Note that entities created from extended templates also have the base template tags
local characterEntities = world:getEntitiesFromTemplate("character")
print(string.format("Found %d character entities", #characterEntities))

-- Demonstrate applying a template to an existing entity
print("\nApplying a template to an existing entity...")

local genericEntity = world:createEntity()
print(string.format("Created generic entity with ID %d", genericEntity.id))

world:applyTemplate(genericEntity, "health", {
    health = { current = 50, max = 150 }
})

-- Process events
world.eventSystem:processEvents()

-- Demonstrate template inheritance
print("\nDemonstrating template inheritance...")

-- Check if player has components from all parent templates
print("Player entity components:")
for componentType, _ in pairs(player.components) do
    print("- " .. componentType)
end

-- Check if player has tags from all parent templates
print("\nPlayer entity template tags:")
for tag, _ in pairs(player.tags) do
    if tag:find("template:") == 1 then
        print("- " .. tag:sub(10)) -- Remove "template:" prefix
    end
end

print("\nComponent template example complete!") 