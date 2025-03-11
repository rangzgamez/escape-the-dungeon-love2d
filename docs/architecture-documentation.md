# Vertical Jumper - Technical Architecture

## Core Architecture

The game is built with several key architectural patterns:

### Finite State Machine (FSM)
The player is controlled through a state machine that manages different behaviors:

```
StateMachine
├── IdleState       # When on ground
├── FallingState    # When airborne
├── DashingState    # During dash attacks
└── DraggingState   # While aiming jumps
```

- Each state inherits from `BaseState`
- States handle their own update, draw, and input logic
- Transitions between states are triggered by game events

### Event System
A publish/subscribe event system allows loose coupling between components:

```lua
-- Publishing an event
Events.fire("playerLanded", { x = player.x, y = player.y })

-- Subscribing to an event
Events.on("playerLanded", function(data)
    particleManager:createDustEffect(data.x, data.y)
end)
```

Key events include:
- `playerLanded`, `playerDashStarted`, `playerDragStart`
- `enemyKill`, `enemyCollision`
- `playerHit`, `playerStateChanged`

### Manager Classes
The game uses manager classes to handle specialized systems:

- **EnemyManager**: Spawns and updates enemies
- **ParticleManager**: Creates and manages visual effects
- **CollisionManager**: Handles physics interactions
- **TimeManager**: Controls time scale effects
- **World**: Generates the level procedurally

## Key Components

### Player System
`player.lua` controls the main character with:
- Physics properties (position, velocity, gravity)
- Dash mechanics (direction, power, duration)
- Health and damage handling
- Combo tracking and visual effects

### Camera System
`camera.lua` implements:
- Smooth follow mechanics
- Screen shake effects
- Vertical tracking for level progression

### Collision System
The collision system uses axis-aligned bounding box (AABB) detection:
```lua
function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
```

Special cases:
- One-way platforms (collide only from above)
- Enemy-player interactions based on player state

### Enemy AI
Enemies like the Bat implement:
- Detection radius for player awareness
- State-based behavior (patrol, chase, stunned)
- Physics-based movement and animation

### Particle Systems
Visual effects created with Love2D's particle system:
```lua
local dust = love.graphics.newParticleSystem(self.dustCanvas, 50)
dust:setParticleLifetime(0.2, 0.8)
dust:setEmissionRate(200)
dust:setSizeVariation(1)
-- Additional properties...
```

## Data Flow and Processing

### Main Game Loop
1. **Input Processing**: Handle keyboard, mouse, and touch
2. **Update Cycle**: Update all game entities with time delta
3. **Collision Detection**: Check and resolve collisions
4. **Rendering**: Draw game elements in appropriate order

### Player State Flow
```
[Idle] ⟷ [Dragging] → [Dashing] → [Falling] → [Idle]
```

### Combo System Flow
1. Enemy defeated → Increment combo counter
2. Combo ≥ 5 → Display affirmation text
3. Landing on ground → Reset combo
4. Taking damage → Reset combo

## Performance Considerations

### Optimization Techniques
- Object pooling for particle effects
- Cleanup of off-screen entities
- Delta time scaling for consistent performance
- Capping delta time to prevent tunneling

### Memory Management
- Platforms and enemies below the screen are removed
- Particle systems have limited lifetimes
- Resources are reused where possible

## Extension Points

The architecture supports easy extension through:
- New player states by adding to the state machine
- New enemy types by implementing the same interface
- New particle effects through ParticleManager
- New event types through the event system