# PlayerECS Test Example

This example demonstrates the PlayerECS implementation using the Entity Component System (ECS) architecture.

## What This Example Shows

- How the PlayerECS class integrates with the ECS framework
- How player movement, jumping, and dashing work in the ECS system
- How the player interacts with other ECS entities (platforms, enemies, collectibles)
- How the state machine manages player states
- How events are fired and handled for player actions

## How to Run

From the `examples/player_ecs_test` directory, run:

```
love .
```

## Controls

- **Arrow Keys/WASD**: Move the player
- **Space**: Jump (can perform midair jumps)
- **Shift**: Dash in the direction you're moving
- **Escape**: Quit the game

## Implementation Details

The PlayerECS implementation uses the following components:

- **Transform**: Handles position and size
- **Collider**: Manages collision detection
- **Physics**: Controls velocity, gravity, and movement
- **Player**: Stores player-specific data like health, experience, and level
- **Movement**: Handles player movement mechanics
- **StateMachine**: Manages player states (idle, running, jumping, etc.)

## Recent Fixes

We made several improvements to the ECS implementation:

1. **Component Structure**: Updated component structures to use nested tables for related properties (e.g., `position.x` instead of separate `x` and `y` properties)
2. **Inheritance**: Fixed inheritance between ECSEntity and derived classes like PlayerECS and XpPelletECS
3. **Collision System**: Improved collision detection and response
4. **Physics System**: Enhanced physics calculations and movement
5. **Camera**: Added better camera following with different styles (LOCKON, PLATFORMER, TOPDOWN)
6. **Entity Factory**: Created a factory for easily generating different entity types
7. **Input Handling**: Added keyboard input handling for player controls

## Next Steps

To integrate the PlayerECS into your main game:

1. Ensure your ECS world is properly initialized
2. Create a player entity using the PlayerECS class
3. Set up collision handling between the player and other entities
4. Connect player events to your game's UI and logic
5. Implement any additional player mechanics specific to your game

## Troubleshooting

If you encounter issues:

- Check that the ECS world is properly initialized and set for ECSEntity
- Ensure all required components are added to entities
- Verify that collision layers are properly set up
- Make sure event handlers are connected correctly 