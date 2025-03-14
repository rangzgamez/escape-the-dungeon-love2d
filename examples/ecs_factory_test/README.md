# ECS Factory Test

This example demonstrates the usage of the new ECS-compatible entity factory in the game.

## What This Example Shows

- How to use the `EntityFactoryECS` to create both traditional and ECS-based entities
- How to toggle between traditional and ECS entities at runtime
- How to create entities individually or in batches
- How the ECS world interacts with ECS entities

## How to Run

From the root directory of the project:

```
cd examples/ecs_factory_test
love .
```

Or from the examples directory:

```
cd ecs_factory_test
love .
```

## Controls

- **Space**: Spawn a new XP pellet at a random position
- **T**: Toggle between traditional and ECS entities
- **Escape**: Quit the example

## Implementation Details

This example demonstrates how the new `EntityFactoryECS` can be used to create both traditional and ECS-based entities. The factory provides a unified interface for creating entities, making it easier to transition from the old system to the new ECS architecture.

Key features of the `EntityFactoryECS`:

1. Support for both traditional and ECS-based entities
2. Ability to create entities individually or in batches
3. Automatic handling of entity parameters
4. Integration with the ECS world

## Next Steps

After testing the factory, the next step would be to integrate it into the main game, gradually transitioning from traditional entities to ECS-based entities. This can be done by:

1. Replacing the current entity factory with `EntityFactoryECS`
2. Updating the level loader to use the new factory
3. Gradually enabling ECS entities for different entity types
4. Eventually removing support for traditional entities once all entity types have been migrated 