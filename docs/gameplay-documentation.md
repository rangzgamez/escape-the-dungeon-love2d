# Vertical Jumper - Gameplay Documentation

## Core Gameplay

### Objective
The player's goal is to climb as high as possible by jumping between platforms while avoiding falling off the bottom of the screen and defeating or evading enemies.

### Controls
- **Mobile (Touch)**:
  - Tap and drag on the screen to aim jumps
  - Pull back farther for stronger jumps
  - Release to launch in the opposite direction of the drag
  
- **Desktop (Mouse & Keyboard)**:
  - Click and drag with mouse to aim jumps
  - Left/Right arrow keys or A/D for horizontal movement
  - Space/Up/W for keyboard-based jumps

### Player Mechanics

#### Movement System
- **Drag-to-Launch**: The primary movement mechanic
  - Drag distance determines dash power (up to a maximum)
  - Trajectory preview shows predicted path
  - A minimum drag distance is required to trigger a dash

#### Jump Types
1. **Standard Dash**: Pull back and release to dash in any direction
2. **Mid-air Jump**: One additional jump available while airborne
3. **Springboard Boost**: Higher jump when landing on red springboards

#### Combo System
- Defeating multiple enemies in succession builds a combo
- Reaching a 5x combo activates special text effects
- Combos reset when landing on platforms or taking damage
- Higher combos award more points

### Environment

#### Platform Generation
- Platforms are procedurally generated as the player moves upward
- A mix of regular platforms and springboards appear
- Old platforms are removed when they fall below the screen

#### Camera System
- Camera follows the player with smooth movement
- Tracks the highest point reached
- Includes screen shake effects for impacts and actions

### Enemy System

#### Enemy Types
- **Bats**: Flying enemies that patrol and chase the player when nearby
  - Patrol randomly when player is out of detection range
  - Chase player when within detection radius
  - Can be defeated with a dash attack

#### Enemy States
- **Idle**: Default patrolling behavior
- **Chase**: Actively pursuing the player
- **Stunned**: Temporarily incapacitated after being hit

### Visual Effects

#### Particle Systems
- **Dust**: Created when landing on platforms
- **Dash Trail**: Visual streak effect behind dashing player
- **Impact**: Explosion effect when defeating enemies
- **Double Jump**: Special effect for mid-air jumps
- **Refresh**: Effect shown when dash ability is refreshed

#### Time Effects
- Game can slow down or pause during aiming (configurable)
- Brief freeze frames when defeating enemies

### Game Progression

#### Difficulty Scaling
- Game speed gradually increases based on height climbed
- Enemy spawn rate increases with height

#### Scoring System
- Score increases based on height climbed
- Bonus points awarded for combos
- High scores are displayed on game over

#### Health System
- Player has 3 health points
- Briefly invulnerable after taking damage
- Game over occurs when health reaches zero or player falls off screen

### Settings
- Toggle slow-motion during aiming
- Toggle pause during aiming
- Press 'S' to access settings menu in-game