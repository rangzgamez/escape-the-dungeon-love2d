# XP System Design Document

## Overview

The XP (Experience Points) system in Escape the Dungeon provides players with a progression mechanic that rewards them for defeating enemies and exploring the game world. XP is collected through XP pellets that drop from defeated enemies, and accumulating enough XP allows the player to level up and potentially unlock new abilities.

## Core Components

### 1. XP Pellets

XP pellets are collectible items that appear when enemies are defeated. They are the primary source of experience points in the game.

#### Visual Design
- **Shape**: Diamond-shaped gems with a distinctive blue color
- **Effects**:
  - Outer glow that pulses to attract player attention
  - "XP" text displayed in the center for clarity
  - White border that becomes more visible when collectible
  - Position information displayed in debug mode

#### Behavior
- **Movement**:
  - Initial explosion from enemy with random velocity
  - Stop moving completely once they become collectible
  - Magnetic attraction toward the player when in range
- **States**:
  - **Non-collectible**: Initial state after spawning, pellets move with physics
  - **Collectible**: After a short delay (0.5s), pellets stop and can be collected
  - **Magnetizable**: When collectible, pellets can be pulled toward the player
- **Lifetime**: Pellets remain active for 15 seconds before disappearing

### 2. XP Manager

The XP Manager coordinates the creation, movement, and collection of XP pellets throughout the game.

#### Responsibilities
- Spawning XP pellets when enemies are killed
- Tracking all active XP pellets
- Applying magnetic attraction to pellets when the player is nearby
- Cleaning up inactive or out-of-bounds pellets

#### Key Methods
- `onEnemyKill(data)`: Creates XP pellets at the enemy's position when killed
- `spawnXp(x, y, amount)`: Manually spawns XP at a specific location
- `applyMagneticAttraction(dt, player)`: Pulls collectible pellets toward the player
- `cleanupPellets(camera, removeCallback)`: Removes pellets that are too far below the camera

### 3. Player XP Collection

The player collects XP by coming into contact with collectible XP pellets.

#### Collection Mechanics
- Pellets must be in "collectible" state to be collected
- Collection occurs through collision detection between player and pellet
- Collection radius can be modified through upgrades
- Magnetic attraction pulls pellets toward the player when in range

#### XP Processing
- When collected, the pellet's XP value is added to the player's experience
- Visual feedback is provided through XP popup text
- When enough XP is accumulated, the player levels up

## Technical Implementation

### Collision System
- XP pellets are registered with the collision manager through the BaseEntity constructor
- Pellets only collide with the player (collisionLayer = "collectible")
- Collision bounds are visualized in debug mode with white outlines

### Visual Effects
- Pellets use a combination of shapes and colors to create a distinctive appearance
- Debug visualization shows both the visual representation and collision bounds
- Position information is displayed in debug mode for troubleshooting

### Camera Integration
- XP pellets are created in world coordinates
- The camera transformation in `love.draw()` ensures pellets appear at the correct position on screen
- Pellets that go off-screen are automatically cleaned up

## Recent Enhancements

### 1. Improved Visual Feedback
- Enhanced outer glow with increased size and vibrancy
- Added "XP" text in the center for immediate recognition
- Implemented pulsing effect to draw player attention
- Added position information in debug mode

### 2. Refined Movement Mechanics
- Pellets now stop completely when becoming collectible
- Implemented a more direct magnetic attraction system
- Fixed issues with pellet positioning relative to enemies
- Ensured proper cleanup of off-screen pellets

### 3. Debug Features
- Added visual indicators for collision bounds
- Implemented position display for troubleshooting
- Created test function to spawn pellets around the player
- Enhanced console logging for development

## Future Considerations

### Potential Enhancements
- Different XP pellet types with varying values and visual styles
- Special effects for larger XP values
- XP multipliers based on player performance
- Temporary XP bonuses as power-ups

### Balance Considerations
- XP values should be balanced against level requirements
- Collection radius should be balanced for gameplay challenge
- Pellet lifetime should be adjusted based on level design

## Usage Examples

### Spawning XP Pellets
```lua
-- When an enemy is killed
Events.on("enemyKill", function(data)
    local xpPellets = xpManager:onEnemyKill(data)
end)

-- Manual spawning for testing
function spawnTestXpPellets()
    local pellet = xpManager:spawnXp(x, y, amount)
    pellet.collectible = true
    pellet.magnetizable = true
end
```

### Collecting XP
```lua
-- In XpPellet:onCollision
function XpPellet:onCollision(other, collisionData)
    if other.type == "player" and self.collectible then
        self.active = false
        return true
    end
end

-- In Player class
function Player:addExperience(amount)
    self.experience = self.experience + amount
    if self.experience >= self.xpToNextLevel then
        self:levelUp()
    end
end
```

## Conclusion

The XP system provides a core progression mechanic that rewards players for successful gameplay. The recent enhancements have improved the visual clarity, movement mechanics, and overall player experience when collecting XP pellets. The system is designed to be extensible for future features and balanced for engaging gameplay. 