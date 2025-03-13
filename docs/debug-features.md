# Debug Features Documentation

## Overview

Escape the Dungeon includes a comprehensive set of debug features to assist with development, testing, and troubleshooting. These features are accessible when the game is run with the `--debug` flag and provide valuable insights into the game's internal workings.

## Enabling Debug Mode

Debug mode can be enabled by:

1. Running the game with the `--debug` flag:
   ```
   love . --debug
   ```

2. Setting the `debugMode` variable to `true` in `main.lua`

## Available Debug Features

### 1. Collision Visualization

Visualize collision boundaries for all entities in the game.

#### Usage
- Press `F3` to toggle collision bounds visibility
- Click the "Show collision bounds" checkbox in the settings menu

#### Implementation Details
- Collision bounds are drawn as white outlines for XP pellets
- Different entity types use different colors:
  - Player: Green
  - Enemies: Red
  - Platforms: Gray
  - XP Pellets: White
  - Other entities: Blue
- Opacity is set to allow seeing the game through the bounds

### 2. Particle Effect Controls

Toggle particle effects to reduce visual clutter and improve performance.

#### Usage
- Press `F2` to toggle particle effects
- Click the "Disable particle effects" checkbox in the settings menu

#### Implementation Details
- When disabled, no particle systems are updated or drawn
- Affects all particle systems including:
  - Dash effects
  - Jump effects
  - Impact effects
  - XP pellet sparkles

### 3. XP Pellet Testing

Spawn test XP pellets around the player to test collection mechanics.

#### Usage
- Press `X` to spawn test XP pellets

#### Implementation Details
- Spawns 5 pellets with random positions around the player
- Pellets are immediately collectible and magnetizable
- Debug mode is enabled on the pellets to show collision bounds
- Console output confirms creation with position information

### 4. Position Information

Display position information for game entities to assist with positioning and layout.

#### Implementation Details
- XP pellets display their exact X and Y coordinates
- Position is shown in yellow text below the entity label
- Updates in real-time as entities move

### 5. Console Logging

Extensive console logging provides insights into game events and entity states.

#### Implementation Details
- Player state changes are logged with previous and new states
- XP pellet creation is logged with position and velocity information
- Enemy spawning and destruction is logged
- Collision events are logged when relevant

### 6. Game State Controls

Control the game state for testing different scenarios.

#### Usage
- Press `P` to toggle pause
- Press `R` to restart the game
- Press `S` to toggle the settings menu

### 7. Visual Debug Indicators

On-screen indicators show the current state of debug features.

#### Implementation Details
- "PARTICLES OFF (F2)" indicator when particles are disabled
- "COLLISION BOUNDS ON (F3)" indicator when collision bounds are visible
- Settings menu shows checkboxes for all active debug features

## Adding New Debug Features

When adding new debug features, follow these guidelines:

1. **Conditional Execution**: Wrap debug code in conditions checking the `debugMode` variable
   ```lua
   if debugMode then
       -- Debug code here
   end
   ```

2. **Performance Considerations**: Ensure debug features don't significantly impact performance
   ```lua
   -- Only print occasionally to avoid spam
   if love.timer.getTime() % 2 < 0.1 then
       print("Debug info")
   end
   ```

3. **Visual Clarity**: Use distinct colors and shapes for different types of debug visualization
   ```lua
   love.graphics.setColor(1, 0, 0, 0.5) -- Red with 50% opacity
   ```

4. **User Controls**: Provide keyboard shortcuts for toggling features
   ```lua
   if key == "f4" and debugMode then
       newDebugFeature = not newDebugFeature
   end
   ```

5. **Documentation**: Update this document when adding new debug features

## Troubleshooting Common Issues

### Entity Positioning
- Use the position display to verify entity coordinates
- Check both visual bounds (red) and collision bounds (white) for discrepancies
- Verify camera transformation is correctly applied

### Collision Detection
- Enable collision bounds visualization
- Check that entities are registered with the collision manager
- Verify collision layers are correctly set

### Performance Issues
- Disable particle effects to see if they're causing slowdowns
- Check console for excessive logging
- Monitor entity count and cleanup

## Conclusion

The debug features in Escape the Dungeon provide powerful tools for development and troubleshooting. By leveraging these features, developers can more easily identify and fix issues, test new functionality, and ensure the game runs smoothly. 