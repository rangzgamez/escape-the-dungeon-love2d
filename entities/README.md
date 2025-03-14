# Entity System

This directory contains entity classes used in the game.

## Entity Types

- `BaseEntity`: The original entity implementation (deprecated)
- `ECSEntity`: The new ECS-based entity implementation

## Transitioning from BaseEntity to ECSEntity

The game is in the process of transitioning from the original `BaseEntity` class to the new `ECSEntity` class, which integrates directly with the Entity Component System (ECS) architecture.

### Benefits of ECSEntity

- Direct integration with the ECS system
- Better performance through spatial partitioning
- More flexible component-based design
- Improved collision detection
- Better memory management through entity pooling

### How to Migrate

To migrate an entity from BaseEntity to ECSEntity:

1. Change the require statement:
   ```lua
   -- Old
   local BaseEntity = require("entities/baseEntity")
   
   -- New
   local ECSEntity = require("entities/ecsEntity")
   ```

2. Update entity creation:
   ```lua
   -- Old
   local entity = BaseEntity:new(x, y, width, height, options)
   
   -- New
   local entity = ECSEntity:new(x, y, width, height, options)
   ```

3. Make sure the ECS world is set before creating entities:
   ```lua
   -- In your initialization code (e.g., main.lua)
   local ecsWorld = initializeECS()
   ECSEntity.setECSWorld(ecsWorld)
   ```

4. If your entity has custom components or behavior, you may need to add those components to the ECS entity:
   ```lua
   -- In your entity's initialization
   if self.ecsEntity then
       self.ecsEntity:addComponent("customComponent", {
           -- component properties
       })
   end
   ```

### Compatibility

The `ECSEntity` class maintains the same API as `BaseEntity` for backward compatibility, so most entity code should continue to work without changes. However, some advanced features may require updates to take full advantage of the ECS architecture.

## Future Plans

Eventually, all entities will be migrated to use the ECS system directly, and the `BaseEntity` class will be removed. This transition will be done gradually to ensure stability and maintain compatibility with existing code. 