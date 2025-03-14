# Entity Component System (ECS) Architecture

## Overview

This document describes the Entity Component System (ECS) architecture implemented in Escape the Dungeon. The ECS pattern is a common architectural pattern in game development that promotes composition over inheritance, leading to more flexible and maintainable code.

## Core Concepts

### Entities

Entities are simple containers for components. They have a unique ID and represent a game object, but they don't contain any game logic or data themselves.

### Components

Components are pure data containers. Each component represents a specific aspect of an entity, such as its position, appearance, or behavior. Components don't contain any game logic.

### Systems

Systems contain the game logic. Each system operates on entities that have a specific set of components. Systems are responsible for updating and manipulating the components of entities.

## Implementation

### Entity

The `Entity` class is a simple container for components. It provides methods for adding, removing, and retrieving components.

```lua
-- Create a new entity
local entity = Entity.create()

-- Add components
entity:addComponent("transform", {
    x = 100,
    y = 200,
    width = 32,
    height = 32
})

entity:addComponent("renderer", {
    type = "rectangle",
    color = {1, 0, 0, 1}
})

-- Check if entity has a component
if entity:hasComponent("transform") then
    -- Get a component
    local transform = entity:getComponent("transform")
    transform.x = transform.x + 10
end

-- Remove a component
entity:removeComponent("renderer")
```

### EntityManager

The `EntityManager` class manages all entities in the game. It provides methods for creating, retrieving, and removing entities.

```lua
-- Create a new entity manager
local entityManager = EntityManager.create()

-- Create a new entity
local entity = entityManager:createEntity()

-- Get all entities with a specific component
local entitiesWithTransform = entityManager:getEntitiesWithComponent("transform")

-- Get all entities with multiple components
local renderableEntities = entityManager:getEntitiesWith("transform", "renderer")
```

### System

The `System` class contains the game logic for a specific aspect of the game. Each system operates on entities that have a specific set of components.

```lua
-- Create a new system
local renderSystem = System.create("RenderSystem")

-- Set required components
renderSystem:requires("transform", "renderer")

-- Process entities
function renderSystem:processEntity(entity, dt)
    local transform = entity:getComponent("transform")
    local renderer = entity:getComponent("renderer")
    
    -- Draw the entity
    love.graphics.setColor(renderer.color)
    love.graphics.rectangle("fill", transform.x, transform.y, transform.width, transform.height)
end
```

### SystemManager

The `SystemManager` class manages all systems in the game. It provides methods for adding, retrieving, and updating systems.

```lua
-- Create a new system manager
local systemManager = SystemManager.create()

-- Add a system
systemManager:addSystem(renderSystem)

-- Update all systems
systemManager:update(dt, entityManager)
```

### ECS World

The `ECS` module provides a convenient way to create and manage an ECS world, which includes an entity manager and a system manager.

```lua
-- Create a new ECS world
local world = ECS.createWorld()

-- Add a system
world:addSystem(renderSystem)

-- Create an entity
local entity = world:createEntity()

-- Update the world
world:update(dt)
```

## Object Pooling

The ECS implementation includes an object pooling system to reduce garbage collection and improve performance. The `EntityManager` class provides methods for getting and returning entities from pools.

```lua
-- Get an entity from a pool
local entity = entityManager:getPooledEntity("bullet")

-- Return an entity to its pool
entityManager:returnToPool(entity)
```

## Spatial Partitioning

The ECS implementation includes a spatial partitioning system to improve collision detection performance. The `SpatialPartition` module provides efficient spatial queries integrated with the ECS architecture.

```lua
-- Create a world with a spatial grid
local world = ECS.createWorld({
    cellSize = 64,
    worldBounds = {
        minX = -1000,
        minY = -1000,
        maxX = 1000,
        maxY = 1000
    }
})

-- Entities with position components are automatically added to the spatial grid

-- Get entities in a radius
local entitiesInRadius = world:getEntitiesInRadius(x, y, radius)

-- Get entities in a rectangle
local entitiesInRect = world:getEntitiesInRect(x, y, width, height)

-- Get potential collision pairs
local collisionPairs = world:getPotentialCollisionPairs()
```

## Bridge to Legacy Code

The `Bridge` module provides a way to integrate the ECS architecture with the existing codebase. It includes methods for converting between the old and new systems.

```lua
-- Convert a BaseEntity to an ECS entity
local ecsEntity = Bridge.convertBaseEntityToECS(baseEntity, world)

-- Update an ECS entity from a BaseEntity
Bridge.updateEntityFromBase(ecsEntity, baseEntity)

-- Update a BaseEntity from an ECS entity
Bridge.updateBaseFromEntity(baseEntity, ecsEntity)
```

## Entity Management

The ECS architecture provides several ways to create and manage entities:

1. **Direct ECS Entities**: Create entities directly using the ECS API:
   ```lua
   local entity = world:createEntity()
   entity:addComponent("transform", { x = 0, y = 0 })
   ```

2. **Component Templates**: Use templates to create entities with predefined components:
   ```lua
   local template = world:getTemplate("enemy")
   local entity = world:createEntityFromTemplate(template)
   ```

3. **ECSEntity Class**: Use the `ECSEntity` class for a more object-oriented approach:
   ```lua
   local entity = ECSEntity:new(x, y, width, height, options)
   ```

### ECSEntity Class

The `ECSEntity` class provides a bridge between the traditional object-oriented entity system and the ECS architecture. It maintains compatibility with the legacy `BaseEntity` API while leveraging the performance benefits of the ECS system.

#### Key Features

- **Compatibility**: Maintains the same API as `BaseEntity` for backward compatibility
- **ECS Integration**: Automatically creates and manages an ECS entity
- **Performance**: Benefits from the ECS spatial partitioning and component-based design
- **Extensibility**: Can be extended to create custom entity types

#### Usage

```lua
-- Require the ECSEntity class
local ECSEntity = require("entities/ecsEntity")

-- Set the ECS world reference (typically done in main.lua)
ECSEntity.setECSWorld(ecsWorld)

-- Create a new entity
local entity = ECSEntity:new(x, y, width, height, {
    type = "customType",
    collisionLayer = "enemies",
    collidesWithLayers = {"player", "projectiles"}
})

-- Use the entity like a traditional object
entity:update(dt)
entity:draw()
entity:setPosition(x, y)
entity:setVelocity(vx, vy)
```

#### Extending ECSEntity

You can create custom entity types by extending the `ECSEntity` class:

```lua
local CustomEntity = {}
CustomEntity.__index = CustomEntity
setmetatable(CustomEntity, {__index = ECSEntity})

function CustomEntity:new(x, y)
    local self = ECSEntity:new(x, y, 32, 32, {
        type = "custom",
        collisionLayer = "custom"
    })
    setmetatable(self, CustomEntity)
    
    -- Add custom properties
    self.customProperty = "value"
    
    -- Add custom components to the ECS entity
    if self.ecsEntity then
        self.ecsEntity:addComponent("customComponent", {
            -- component properties
        })
    end
    
    return self
end

-- Override methods as needed
function CustomEntity:update(dt)
    -- Call parent update
    ECSEntity.update(self, dt)
    
    -- Add custom behavior
    -- ...
end
```

See the `examples/ecs_entity_example.lua` file for a complete example of extending and using the `ECSEntity` class.

## Benefits

The ECS architecture provides several benefits:

1. **Composition over Inheritance**: Entities are composed of components, which makes it easy to create new types of entities without deep inheritance hierarchies.

2. **Data-Oriented Design**: Components are pure data, which makes it easier to optimize for cache locality and parallelism.

3. **Separation of Concerns**: Systems contain the game logic, which makes it easier to reason about and test the code.

4. **Flexibility**: It's easy to add, remove, or modify components and systems without affecting the rest of the codebase.

5. **Performance**: The ECS architecture can be optimized for performance through techniques like object pooling and spatial partitioning.

## Future Improvements

1. **Serialization**: Add support for serializing and deserializing entities and components for save/load functionality.

2. **Editor Integration**: Create a visual editor for creating and editing entities and components.

3. **Event System**: Enhance the event system to support more complex event handling and filtering.

4. **Prefabs**: Add support for entity templates or prefabs to make it easier to create common types of entities.

5. **Scripting**: Add support for scripting entities and components using a higher-level language like Lua.