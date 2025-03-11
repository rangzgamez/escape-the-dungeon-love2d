# Vertical Jumper - Project Structure

## Overview
Vertical Jumper is a mobile-friendly 2D platformer built with Love2D where the player navigates upward through platforms, avoiding enemies and collecting power-ups. The game features a unique drag-to-launch mechanic, combo system, and dynamic camera movement.

## Directory Structure
```
vertical-jumper/
├── main.lua                 # Entry point for Love2D
├── conf.lua                 # Game configuration (to be created)
├── assets/                  # Game assets (to be created)
│   ├── images/              # Sprites and images
│   ├── sounds/              # Sound effects and music
│   └── fonts/               # Custom fonts
├── lib/                     # Core system components
│   ├── events.lua           # Event system
│   └── timeManager.lua      # Time control for effects
├── states/                  # Player state machine components
│   ├── baseState.lua        # Base state class
│   ├── stateMachine.lua     # State machine implementation
│   ├── idleState.lua        # On-ground state
│   ├── fallingState.lua     # Airborne state
│   ├── dashingState.lua     # Dash attack state
│   └── draggingState.lua    # Aiming state
├── entities/                # Game objects
│   ├── player.lua           # Player implementation
│   ├── platform.lua         # Standard platforms
│   ├── springboard.lua      # Jump-boosting platforms
│   └── bat.lua              # Enemy implementation
├── managers/                # Game systems
│   ├── camera.lua           # Camera and screen shake
│   ├── collisionManager.lua # Collision detection
│   ├── enemyManager.lua     # Enemy spawning and control
│   ├── particleManager.lua  # Visual effects system
│   └── world.lua            # Level generation
└── docs/                    # Documentation (separate folder)
    ├── gameplay.md          # Gameplay systems documentation
    ├── architecture.md      # Code architecture documentation
    └── extending.md         # Guide for adding features
```

## Reorganization Needed
Your current code is well-structured but could benefit from folder organization as shown above. Moving files into appropriate directories will help maintain the codebase as it grows.

## Building and Running
1. Install Love2D from [love2d.org](https://love2d.org)
2. Organize files according to the directory structure
3. Run the game with: `love path/to/vertical-jumper`