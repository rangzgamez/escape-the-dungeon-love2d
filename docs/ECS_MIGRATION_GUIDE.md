# ECS Migration Guide

This guide outlines the process of migrating from the traditional entity system to the new Entity Component System (ECS) architecture in Escape the Dungeon.

## Why Migrate to ECS?

The ECS architecture offers several advantages:

1. **Better Performance**: ECS allows for more efficient processing of entities by organizing them by components.
2. **Improved Modularity**: Components can be added or removed from entities without changing their core functionality.
3. **Enhanced Flexibility**: New entity types can be created by combining existing components.
4. **Easier Debugging**: Component-based architecture makes it easier to isolate and fix issues.
5. **Better Code Organization**: Clear separation of data (components) and behavior (systems).

## Migration Steps

### 1. Initialize the ECS World

The ECS world must be initialized at the start of the game:

```lua
-- Create the ECS world
ecsWorld = Bridge.createWorld()

-- Set the ECS world for ECSEntity
ECSEntity.setECSWorld(ecsWorld)

-- Make ecsWorld globally accessible
_G.ecsWorld = ecsWorld
```

### 2. Replace Entity Creation

Instead of creating entities directly, use the EntityFactoryECS:

```lua
-- Old way
local player = Player:new(400, 300)

-- New way
local entityFactory = EntityFactoryECS.new(ecsWorld)
local player = entityFactory:createPlayer(400, 300)
```

### 3. Update Entity References

When working with ECS entities, remember that:

- Entity properties are now organized into components
- Access components using `entity.ecsEntity:getComponent("componentName")`
- Update components using the same method

Example:

```lua
-- Old way
player.x = 100
player.velocity.y = -500

-- New way
local transform = player.ecsEntity:getComponent("transform")
transform.position.x = 100

local physics = player.ecsEntity:getComponent("physics")
physics.velocity.y = -500
```

### 4. Handle Collisions

Collision detection is now handled by the CollisionSystem:

```lua
-- Old way
if player:checkCollision(enemy) then
    player:onCollision(enemy)
end

-- New way
-- This is handled automatically by the CollisionSystem
-- Just implement the onCollision method in your entity classes
```

### 5. Update Event Handling

Events are still used for communication, but now they often include ECS entities:

```lua
-- Old way
Events.fire("playerJump", {x = player.x, y = player.y})

-- New way
Events.fire("playerJump", {
    entity = player.ecsEntity,
    x = player.x, 
    y = player.y
})
```

### 6. Implement ECS Versions of Entities

For each entity type, create an ECS version that:

1. Inherits from ECSEntity
2. Defines appropriate components
3. Implements necessary methods (update, draw, onCollision, etc.)

Example:

```lua
local EnemyECS = {}
EnemyECS.__index = EnemyECS
setmetatable(EnemyECS, {__index = ECSEntity})

function EnemyECS.new(x, y, enemyType)
    -- Create options
    local options = {
        type = "enemy",
        collisionLayer = "enemy",
        collidesWithLayers = {"player", "platform"},
        isSolid = true
    }
    
    -- Create entity
    local enemy = ECSEntity.new(x, y, 32, 32, options)
    setmetatable(enemy, {__index = EnemyECS})
    
    -- Add components
    if enemy.ecsEntity then
        enemy.ecsEntity:addComponent("enemy", {
            health = 3,
            damage = 1,
            -- Other enemy properties
        })
    end
    
    return enemy
end
```

### 7. Update Managers

Managers should be updated to work with ECS entities:

```lua
-- Old way
enemyManager:spawnEnemy(x, y, "basic")

-- New way
local entityFactory = EntityFactoryECS.new(ecsWorld)
local enemy = entityFactory:createEnemy(x, y, "basic")
enemyManager:addEnemy(enemy)
```

## Component Reference

Here are the main components used in the ECS architecture:

### Transform Component
```lua
{
    position = {x = 0, y = 0},
    size = {width = 32, height = 32}
}
```

### Physics Component
```lua
{
    velocity = {x = 0, y = 0},
    acceleration = {x = 0, y = 0},
    gravity = 800,
    friction = 0.8,
    mass = 1,
    affectedByGravity = true
}
```

### Collider Component
```lua
{
    layer = "default",
    collidesWithLayers = {"default"},
    isSolid = true,
    isStatic = false,
    isTrigger = false
}
```

### Type Component
```lua
{
    type = "entity"
}
```

### Player Component
```lua
{
    health = 3,
    maxHealth = 3,
    lives = 3,
    experience = 0,
    level = 1,
    xpToNextLevel = 10,
    isInvulnerable = false,
    invulnerabilityTimer = 0,
    invulnerabilityDuration = 1.5
}
```

### Movement Component
```lua
{
    moveSpeed = 200,
    jumpForce = 500,
    maxFallSpeed = 800,
    midairJumps = 1,
    maxMidairJumps = 1,
    isGrounded = false,
    isDashing = false,
    canDash = true,
    dashSpeed = 500,
    dashDuration = 0.2,
    dashTimer = 0,
    dashDirection = {x = 1, y = 0},
    facingDirection = 1
}
```

## System Reference

The ECS architecture includes the following systems:

1. **CollisionSystem**: Handles collision detection and response
2. **PhysicsSystem**: Updates entity positions based on physics properties
3. **RenderSystem**: Draws entities to the screen
4. **XpSystem**: Manages XP pellets and player progression

## Troubleshooting

### Common Issues

1. **Entity not appearing**: Check if the entity has a transform component and is active.
2. **No collision detection**: Verify that the entity has a collider component with the correct layers.
3. **Physics not working**: Ensure the entity has a physics component and is affected by gravity if needed.
4. **Component not found**: Make sure you're adding all required components when creating the entity.

### Debugging Tips

1. Use `Bridge.toggleCollisionDebug(ecsWorld)` to visualize collision boxes.
2. Print component values to debug issues: `print(inspect(entity.ecsEntity:getComponent("transform")))`.
3. Check if entities are active: `print(entity.active)`.
4. Verify that the ECS world is properly initialized: `print(ecsWorld ~= nil)`.

## Migration Checklist

- [ ] Initialize ECS world in main.lua
- [ ] Create ECS versions of all entity classes
- [ ] Update entity creation to use EntityFactoryECS
- [ ] Update managers to work with ECS entities
- [ ] Update UI to reference ECS components
- [ ] Test all game systems with ECS entities
- [ ] Remove old entity classes once migration is complete 