# Vertical Jumper

A fast-paced, vertical platformer built with LÖVE (Love2D) featuring fluid movement mechanics, procedural level generation, and engaging enemy encounters.

![Game Screenshot Placeholder]

## Game Features

- **Unique Drag-to-Launch Mechanic**: Pull back and release to dash in any direction
- **Procedurally Generated Levels**: Endless vertical climbing with randomized platforms
- **Combo System**: Chain enemy defeats for higher scores and special effects
- **Mobile-Friendly Design**: Works great on both touchscreens and desktop
- **Fluid Movement**: State-based player controls with polished animations
- **Visual Effects**: Particle systems for jumps, dashes, and impacts
- **Enemy AI**: Responsive enemies that react to player presence
- **Time Effects**: Slow-motion and screen freeze for dramatic moments

## Getting Started

### Prerequisites

- [LÖVE](https://love2d.org/) 11.3 or newer

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/vertical-jumper.git
   ```

2. Run the game:
   ```
   love vertical-jumper
   ```

### Controls

#### Touch/Mouse Controls:
- **Tap and drag**: Aim your jump
- **Release**: Launch in the opposite direction
- **Settings button**: Access game options

#### Keyboard Controls:
- **A/D or Left/Right arrows**: Move horizontally
- **W, Up arrow, or Space**: Jump
- **R**: Restart after game over
- **S**: Toggle settings menu
- **Escape**: Quit game

## Code Architecture

The game uses several architectural patterns:

- **Finite State Machine**: Controls player states (idle, falling, dashing, dragging)
- **Event System**: Handles communication between game components
- **Manager Classes**: Organize game systems (particles, enemies, collisions)

See the [architecture documentation](docs/architecture.md) for more details.

## Project Structure

```
vertical-jumper/
├── main.lua                 # Entry point
├── assets/                  # Game resources
├── lib/                     # Core systems
├── states/                  # Player state machine
├── entities/                # Game objects
├── managers/                # Game systems
└── docs/                    # Documentation
```

See the [project structure document](docs/project-structure.md) for more details.

## Extension Guide

Want to add new features? Check out the [extension guide](docs/extending.md) for tutorials on:

- Adding new enemy types
- Creating power-ups
- Implementing new platform types
- Adding visual polish
- Implementing progression systems
- Adding sound and music
- Creating save systems

## Acknowledgments

- Developed with [LÖVE](https://love2d.org/)
- Inspired by mobile platformers like Doodle Jump and Sonic Jump

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Your Name - your.email@example.com

Project Link: https://github.com/yourusername/vertical-jumper