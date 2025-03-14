# Spatial Partitioning System

## Overview

The Spatial Partitioning system is an optimization technique implemented in our Entity Component System (ECS) architecture to efficiently handle spatial queries. It divides the game world into a grid of cells and tracks which entities are in each cell, allowing for much faster spatial queries than brute force approaches.

## Key Features

1. **Grid-based Spatial Partitioning**: Divides the world into a grid of cells for efficient entity lookup.
2. **Automatic Entity Tracking**: Automatically tracks entities with position components.
3. **Efficient Spatial Queries**: Provides optimized methods for querying entities in a radius or rectangle.
4. **Collision Pair Generation**: Efficiently generates potential collision pairs for physics systems.
5. **Debug Visualization**: Includes debug drawing functionality to visualize the spatial grid.

## Implementation Details

The spatial partitioning system consists of the following components:

### SpatialPartition Module

The core module that implements the grid-based spatial partitioning system. It provides methods for:

- Creating a spatial grid with customizable cell size and world bounds
- Converting between world and cell coordinates
- Inserting, removing, and updating entities in the grid
- Querying entities in a specific cell, radius, or rectangle
- Generating potential collision pairs
- Debug drawing the grid

### ECS Integration

The spatial partitioning system is integrated into the ECS architecture through:

- World creation with spatial configuration
- Automatic entity tracking based on position components
- Event listeners for component changes
- Spatial query methods exposed through the world interface

## Performance Benefits

The spatial partitioning system provides significant performance improvements for spatial queries:

- **Radius Queries**: Instead of checking distance against all entities (O(n)), only entities in relevant cells are checked (O(k) where k is the number of entities in nearby cells).
- **Rectangle Queries**: Similar optimization for rectangle-based queries.
- **Collision Detection**: Reduces potential collision pairs by only considering entities in the same cell.

In our testing, spatial queries using the grid-based approach were typically 5-20x faster than brute force approaches, with the performance gap increasing as the number of entities grows.

## Usage Examples

### Creating a World with Spatial Partitioning

```lua
local world = ECS.createWorld({
    cellSize = 100, -- 100 pixel cells
    worldBounds = {
        minX = -1000,
        minY = -1000,
        maxX = 1000,
        maxY = 1000
    }
})
```

### Querying Entities in a Radius

```lua
local nearbyEntities = world:getEntitiesInRadius(x, y, radius)
```

### Querying Entities in a Rectangle

```lua
local entitiesInRect = world:getEntitiesInRect(x, y, width, height)
```

### Getting Potential Collision Pairs

```lua
local collisionPairs = world:getPotentialCollisionPairs()
```

### Updating Entity Position

```lua
-- After manually changing an entity's position
entity:getComponent("position").x = newX
entity:getComponent("position").y = newY
world:updateEntityPosition(entity)
```

### Debug Drawing

```lua
function love.draw()
    -- Draw the spatial grid for debugging
    world:debugDrawSpatialGrid()
end
```

## Best Practices

1. **Choose Appropriate Cell Size**: The cell size should be based on the typical query radius and entity density. Too small cells increase memory usage, while too large cells reduce efficiency.

2. **Update Entity Positions**: When manually changing an entity's position, make sure to update it in the spatial grid using `world:updateEntityPosition(entity)`.

3. **Use for Spatial Queries**: Always use the spatial partitioning system for spatial queries instead of brute force approaches.

4. **Consider Entity Size**: For entities with significant size, consider placing them in multiple cells or using a larger query radius.

5. **Optimize World Bounds**: Set the world bounds to match your game world to avoid wasting memory on unused cells.

## Future Improvements

1. **Quadtree/Octree**: Implement more advanced spatial partitioning structures for varying entity densities.

2. **Dynamic Cell Sizing**: Adapt cell size based on entity density in different regions.

3. **Spatial Hashing**: Implement spatial hashing for infinite or very large worlds.

4. **Broad/Narrow Phase**: Implement a two-phase collision detection system using the spatial grid for broad phase.

5. **Parallel Processing**: Optimize for multi-threaded processing of spatial queries.

## Example

See `examples/spatial_partitioning_example.lua` for a complete example of using the spatial partitioning system. 