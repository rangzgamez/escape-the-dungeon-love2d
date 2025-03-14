# ECS Collision System

## Overview

The Entity Component System (ECS) Collision System is responsible for detecting and handling collisions between entities in the game. It uses spatial partitioning techniques to efficiently detect potential collisions and provides debug visualization capabilities for development and troubleshooting.

## Components

### Collider Component

The `collider` component defines the collision properties of an entity:

```lua
entity:addComponent("collider", {
    offsetX = 0,           -- X offset from entity position
    offsetY = 0,           -- Y offset from entity position
    width = 32,            -- Width of collision box
    height = 32,           -- Height of collision box
    layer = "player",      -- Collision layer
    collidesWithLayers = {"enemy", "platform"}  -- Layers this entity collides with
})
```

### Transform Component

The `transform` component defines the position and dimensions of an entity:

```lua
entity:addComponent("transform", {
    x = 100,               -- X position
    y = 200,               -- Y position
    width = 32,            -- Visual width
    height = 32,           -- Visual height
    rotation = 0,          -- Rotation in radians
    scaleX = 1,            -- X scale
    scaleY = 1             -- Y scale
})
```

## Collision System

The `CollisionSystem` is responsible for detecting and handling collisions between entities. It uses a spatial partitioning grid to divide the game world into cells. Entities are inserted into the cells they overlap, allowing for efficient collision detection by only checking entities in the same or adjacent cells.

### Spatial Partitioning

The system uses a spatial partitioning grid to divide the game world into cells. Entities are inserted into the cells they overlap, allowing for efficient collision detection by only checking entities in the same or adjacent cells.

```lua
-- Create spatial grid with cell size of 64 pixels
self.spatialGrid = SpatialPartition.createGrid(64, {
    minX = -10000,
    minY = -10000,
    maxX = 10000,
    maxY = 10000
})

-- Insert entity into spatial grid
self.spatialGrid:insertEntity(entity)

-- Get potential collision pairs
local potentialPairs = self.spatialGrid:getPotentialCollisionPairs()
```

### Collision Detection

The system uses Axis-Aligned Bounding Box (AABB) collision detection to determine if two entities are colliding:

```lua
function CollisionSystem:checkCollision(boundsA, boundsB)
    return boundsA.x < boundsB.x + boundsB.width and
           boundsA.x + boundsA.width > boundsB.x and
           boundsA.y < boundsB.y + boundsB.height and
           boundsA.y + boundsA.height > boundsB.y
end
```

### Collision Response

When a collision is detected, the system calculates collision data and fires events to notify interested systems:

```lua
-- Calculate collision data
local collisionData = self:calculateCollisionData(boundsA, boundsB, dt)

-- Fire entity-specific collision events
Events.fire("collision:" .. typeA, {
    entity = entityA,
    other = entityB,
    collisionData = collisionData
})

Events.fire("collision:" .. typeA .. ":" .. typeB, {
    entityA = entityA,
    entityB = entityB,
    collisionData = collisionData
})
```

## Debug Visualization

The collision system includes debug visualization capabilities to help with development and troubleshooting:

### Toggling Debug Visualization

Debug visualization can be toggled on and off:

```lua
-- Toggle debug drawing
function CollisionSystem:toggleDebugDraw()
    self.debugDraw = not self.debugDraw
end
```

### Drawing Collision Bounds

When debug visualization is enabled, the system draws the collision bounds of all entities:

```lua
-- Draw collision bounds
love.graphics.setColor(color)
love.graphics.rectangle("line", 
    transform.x + collider.offsetX, 
    transform.y + collider.offsetY, 
    collider.width, 
    collider.height)
```

### Color Coding

Entities are color-coded based on their type to make it easier to identify them:

- Player: Green
- Enemies: Red
- Platforms: Gray
- XP Pellets: White
- Other entities: Blue

## Integration with Legacy System

The ECS collision system is integrated with the legacy collision system through the `Bridge` module:

```lua
-- Toggle collision debug in ECS system
function Bridge.toggleCollisionDebug(world)
    local collisionSystem = world.systemManager:getSystem("CollisionSystem")
    collisionSystem:toggleDebugDraw()
end
```

## Usage

### Creating an Entity with Collision

```lua
-- Create an entity with collision
local entity = world:createEntity()

-- Add transform component
entity:addComponent("transform", {
    x = 100,
    y = 200,
    width = 32,
    height = 32
})

-- Add collider component
entity:addComponent("collider", {
    offsetX = 0,
    offsetY = 0,
    width = 32,
    height = 32,
    layer = "player",
    collidesWithLayers = {"enemy", "platform"}
})
```

### Handling Collisions

```lua
-- Set up collision event handlers
Events.on("collision:player:enemy", function(data)
    -- Handle player-enemy collision
    local player = data.entityA
    local enemy = data.entityB
    local collisionData = data.collisionData
    
    -- Player takes damage
    player:takeDamage()
end)
```

### Toggling Debug Visualization

```lua
-- Toggle collision debug visualization
if key == "f3" and debugMode then
    -- Toggle collision bounds
    showCollisionBounds = not showCollisionBounds
    
    -- Toggle collision debug in ECS system if available
    if ecsWorld then
        Bridge.toggleCollisionDebug(ecsWorld)
    end
    
    print("Collision bounds " .. (showCollisionBounds and "visible" or "hidden"))
end
```

## Performance Considerations

- The spatial partitioning grid significantly improves collision detection performance by reducing the number of entity pairs that need to be checked.
- The cell size of the spatial partitioning grid can be adjusted to balance between memory usage and performance.
- Debug visualization should be disabled in production builds to avoid unnecessary rendering overhead.

## Future Improvements

1. **Continuous Collision Detection**: Implement continuous collision detection to handle fast-moving objects.
2. **Collision Resolution**: Add built-in collision resolution to automatically resolve collisions.
3. **Collision Shapes**: Support for different collision shapes (circles, polygons, etc.).
4. **Collision Filtering**: More advanced collision filtering based on entity properties.
5. **Collision Callbacks**: Allow entities to register collision callbacks directly. 