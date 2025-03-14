# Entity Component System (ECS) Architecture

## Overview

The Entity Component System (ECS) is an architectural pattern used in game development that follows the composition over inheritance principle. It allows for greater flexibility, modularity, and performance in game design by separating the data (Components) from the logic (Systems) and the entities that own them.

Our ECS implementation consists of the following core modules:

1. **Entity**: A container for components with a unique ID
2. **Component**: Plain data structures with no behavior
3. **System**: Logic that processes entities with specific components
4. **EntityManager**: Manages entity creation, deletion, and querying
5. **SystemManager**: Manages system registration and execution
6. **Serialization**: Handles saving and loading of entities and their components
7. **EventSystem**: Provides communication between systems and entities
8. **ComponentTemplate**: Provides reusable component configurations for common entity types
9. **SpatialPartition**: Provides efficient spatial queries for entities with position components

## Core Modules

### Entity

Entities are essentially just IDs with a collection of components. They have no behavior of their own and serve as containers for components.

Key features:
- Unique ID generation
- Component management (add, remove, get)
- Tagging system for quick filtering
- Active/inactive state
- Event emission for lifecycle changes

### Component

Components are simple data containers with no behavior. They store the state of various aspects of an entity.

Examples:
- Position (x, y)
- Velocity (x, y)
- Health (current, max)
- Sprite (image, width, height)

### System

Systems contain the game logic that operates on entities with specific components. Each system defines which components it requires and provides update and draw functions.

Key features:
- Component requirements
- Update function for game logic
- Draw function for rendering
- Priority for execution order

### EntityManager

The EntityManager is responsible for creating, tracking, and destroying entities. It also provides methods for querying entities based on their components or tags.

Key features:
- Entity creation and destruction
- Entity pooling for performance
- Entity queries by component or tag
- Cleanup of inactive entities

### SystemManager

The SystemManager handles the registration and execution of systems. It ensures that systems are updated and drawn in the correct order.

Key features:
- System registration
- Update and draw execution
- System prioritization

### Serialization

The Serialization module handles saving and loading the state of entities and their components. This is essential for features like save/load functionality, level persistence, and game state management.

Key features:
- Entity serialization and deserialization
- Component serialization and deserialization
- World state saving and loading
- JSON encoding/decoding

### EventSystem

The EventSystem provides a way for different parts of the game to communicate without direct dependencies. It implements a publish-subscribe pattern where components can emit events and systems can listen for them.

Key features:
- Event registration and emission
- Event queuing and processing
- Multiple event buses for isolation
- Automatic event emission for entity lifecycle events

### ComponentTemplate

The ComponentTemplate module provides a way to define reusable component configurations for common entity types. This allows for easier creation of entities with consistent component sets and reduces code duplication.

Key features:
- Template registration and retrieval
- Template inheritance and extension
- Component overriding
- Entity creation from templates
- Template-based entity querying

### SpatialPartition

The SpatialPartition module provides efficient spatial queries for entities with position components. It implements a grid-based spatial partitioning system that divides the world into cells and tracks which entities are in each cell. This allows for much faster spatial queries than brute force approaches.

Key features:
- Grid-based spatial partitioning
- Efficient radius-based entity queries
- Efficient rectangle-based entity queries
- Automatic entity tracking based on position components
- Potential collision pair generation
- Debug visualization

## Usage

### Creating a World

```lua
local ECS = require("lib/ecs/ecs")
local world = ECS.createWorld()
```

### Creating Entities

```lua
local player = world:createEntity()
player:addComponent("position", { x = 100, y = 100 })
player:addComponent("velocity", { x = 0, y = 0 })
player:addTag("player")
```

### Creating Systems

```lua
local movementSystem = world:createSystem("movement")
movementSystem:addComponentRequirement("position")
movementSystem:addComponentRequirement("velocity")
movementSystem:setUpdateFunction(function(dt, entity)
    local position = entity:getComponent("position")
    local velocity = entity:getComponent("velocity")
    
    position.x = position.x + velocity.x * dt
    position.y = position.y + velocity.y * dt
end)
```

### Updating the World

```lua
function love.update(dt)
    world:update(dt)
end

function love.draw()
    world:draw()
end
```

### Querying Entities

```lua
-- Get all entities with position and sprite components
local renderables = world:getEntitiesWith("position", "sprite")

-- Get all entities with the "enemy" tag
local enemies = world:getEntitiesWithTag("enemy")
```

### Serialization and Persistence

```lua
-- Save the world state to a file
world:saveToFile("save_game.json")

-- Load a world from a file
local loadedWorld = ECS.loadWorldFromFile("save_game.json")
```

### Using the Event System

```lua
-- Register an event listener
world:on("entityCreated", function(data)
    print("Entity created: " .. data.entity.id)
end)

-- Emit a custom event
world:emit("playerDied", { position = { x = 100, y = 200 }, cause = "enemy" })

-- Listen for a custom event
world:on("playerDied", function(data)
    spawnExplosion(data.position.x, data.position.y)
    showGameOverScreen(data.cause)
end)

-- Remove an event listener
local handle = world:on("someEvent", function() end)
world:off(handle)
```

### Using Component Templates

```lua
-- Register a component template
world:registerTemplate("enemy", {
    position = { x = 0, y = 0 },
    velocity = { x = 0, y = 0 },
    health = { current = 50, max = 50 },
    ai = { type = "aggressive", detectionRadius = 200 }
})

-- Extend a template
world:extendTemplate("enemy", "boss", {
    -- Additional components
    specialAttack = { damage = 20, cooldown = 5 }
}, {
    -- Overrides for existing components
    health = { current = 200, max = 200 },
    ai = { type = "boss", detectionRadius = 300 }
})

-- Create an entity from a template
local enemy = world:createEntityFromTemplate("enemy", {
    -- Override some components
    position = { x = 200, y = 150 }
})

-- Apply a template to an existing entity
local entity = world:createEntity()
world:applyTemplate(entity, "enemy")

-- Query entities by template
local enemies = world:getEntitiesFromTemplate("enemy")
```

### Using the Spatial Partitioning System

```lua
-- Create a world with custom spatial partitioning settings
local world = ECS.createWorld({
    cellSize = 100, -- 100 pixel cells
    worldBounds = {
        minX = -1000,
        minY = -1000,
        maxX = 1000,
        maxY = 1000
    }
})

-- Query entities in a radius around a point
local nearbyEntities = world:getEntitiesInRadius(x, y, radius)

-- Query entities in a rectangle
local entitiesInRect = world:getEntitiesInRect(x, y, width, height)

-- Get potential collision pairs
local collisionPairs = world:getPotentialCollisionPairs()

-- Update an entity's position in the spatial grid
world:updateEntityPosition(entity)

-- Debug draw the spatial grid
world:debugDrawSpatialGrid()
```

## Built-in Events

The ECS system automatically emits the following events:

- **entityCreated**: When a new entity is created
- **entityRemoved**: When an entity is removed from the world
- **entityActivated**: When an entity is activated
- **entityDeactivated**: When an entity is deactivated
- **entityReset**: When an entity is reset (for pooling)
- **componentAdded**: When a component is added to an entity
- **componentRemoved**: When a component is removed from an entity
- **tagAdded**: When a tag is added to an entity
- **tagRemoved**: When a tag is removed from an entity
- **systemAdded**: When a system is added to the world
- **systemCreated**: When a system is created
- **worldSaved**: When the world is saved to a file
- **worldSaveFailed**: When saving the world fails
- **worldLoaded**: When a world is loaded
- **templateRegistered**: When a component template is registered
- **templateExtended**: When a component template is extended
- **entityTemplateCreating**: Before an entity is created from a template
- **entityTemplateCreated**: After an entity is created from a template
- **entityTemplateApplying**: Before a template is applied to an entity
- **entityTemplateApplied**: After a template is applied to an entity

## Best Practices

1. **Keep components small and focused**: Each component should represent a single aspect of an entity.
2. **Use tags for quick filtering**: Tags are more efficient than component checks for simple categorization.
3. **Pool entities for performance**: Use entity pooling for frequently created/destroyed entities.
4. **Prioritize systems appropriately**: Systems should be executed in a logical order.
5. **Handle serialization edge cases**: Be careful with non-serializable data like functions or userdata.
6. **Use events for loose coupling**: Systems should communicate through events rather than direct references.
7. **Create isolated event buses**: Use separate event buses for unrelated subsystems.
8. **Use component templates for consistency**: Define templates for common entity types to ensure consistency and reduce code duplication.
9. **Leverage template inheritance**: Build complex templates by extending simpler ones.
10. **Use spatial partitioning for spatial queries**: Use the spatial partitioning system for efficient spatial queries instead of brute force approaches.
11. **Update entity positions in the spatial grid**: When manually changing an entity's position, make sure to update it in the spatial grid using `world:updateEntityPosition(entity)`.
12. **Choose appropriate cell sizes**: The cell size for spatial partitioning should be based on the typical query radius and entity density. Too small cells increase memory usage, while too large cells reduce efficiency.

## Future Improvements

1. **System Dependencies**: Allow systems to specify dependencies on other systems.
2. **Network Synchronization**: Add support for network synchronization of entity states.
3. **Event Filtering**: Add support for filtering events by entity or component type.
4. **Template Versioning**: Add support for versioning templates to handle changes in component structure.
5. **Quadtree/Octree**: Implement more advanced spatial partitioning structures for varying entity densities.

## Examples

See the `examples` directory for practical demonstrations of the ECS architecture:

- `basic_example.lua`: Simple demonstration of entities, components, and systems
- `pooling_example.lua`: Example of entity pooling for performance
- `serialization_example.lua`: Example of saving and loading game state
- `event_system_example.lua`: Example of using the event system for communication
- `component_template_example.lua`: Example of using component templates for entity creation
- `spatial_partitioning_example.lua`: Example of using the spatial partitioning system for efficient spatial queries 