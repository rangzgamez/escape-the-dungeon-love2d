# ECS Entities Test

This example demonstrates the usage of the new ECS-based entity implementations in the game.

## What This Example Shows

- How to initialize the ECS world
- How to create and use ECS-based entities:
  - XP Pellets
  - Platforms (static)
  - Moving Platforms
  - Springboards
  - Slime enemies
- How entities interact with the ECS world
- Basic rendering and updating of ECS entities

## How to Run

From the root directory of the project:

```
cd examples/ecs_entities_test
love .
```

Or from the examples directory:

```
cd ecs_entities_test
love .
```

## Controls

- **Space**: Spawn a new XP pellet at a random position
- **Escape**: Quit the example

## Implementation Details

This example demonstrates how the new ECS-based entities work compared to the traditional entity system. The key differences are:

1. Entities are now based on the `ECSEntity` class instead of `BaseEntity`
2. Entities register components with the ECS world
3. Systems in the ECS world process these components
4. Collision detection is handled by the ECS collision system

This approach provides better performance, more flexibility, and cleaner separation of concerns compared to the previous implementation.

## Next Steps

After testing these implementations, the next step would be to fully integrate them into the main game, replacing the old entity implementations. This includes:

1. Updating the entity factory to create ECS entities
2. Modifying the level loader to work with ECS entities
3. Ensuring all game systems properly interact with the ECS world
4. Removing deprecated entity implementations once the transition is complete 