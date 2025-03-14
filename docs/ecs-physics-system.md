# ECS Physics System

## Overview

The Entity Component System (ECS) Physics System is responsible for handling movement, gravity, and other physical behaviors of entities in the game. It provides a lightweight physics simulation that is efficient and suitable for 2D platformer games.

## Components

### Physics Component

The `physics` component defines the physical properties and behavior of an entity:

```lua
entity:addComponent("physics", {
    velocityX = 0,         -- X velocity
    velocityY = 0,         -- Y velocity
    gravity = true,        -- Whether gravity affects this entity
    gravityScale = 1,      -- Gravity multiplier (1.0 = normal gravity)
    onGround = false,      -- Whether the entity is on the ground
    friction = 0.1,        -- Ground friction coefficient
    airResistance = 0.01,  -- Air resistance coefficient
    dampening = 0.98,      -- Velocity dampening factor
    disabled = false       -- Whether physics is disabled for this entity
})
```

### Transform Component

The `transform` component defines the position and dimensions of an entity:

```lua
entity:addComponent("transform", {
    x = 100,               -- X position
    y = 200,               -- Y position
    width = 32,            -- Width
    height = 32,           -- Height
    rotation = 0,          -- Rotation in radians
    scaleX = 1,            -- X scale
    scaleY = 1             -- Y scale
})
```

## Physics System

The `PhysicsSystem` is responsible for updating the physical state of entities based on their physics components.

### Global Physics Settings

The system defines global physics settings that apply to all entities:

```lua
-- Global physics settings
self.gravity = 400           -- Gravity acceleration (pixels/second²)
self.terminalVelocity = 1000 -- Maximum falling speed
self.dampening = 0.98        -- Default velocity dampening
```

### Physics Update

The system updates each entity's physical state in the following steps:

1. Apply gravity if enabled
2. Apply friction if on ground
3. Apply air resistance if not on ground
4. Apply velocity dampening
5. Update position based on velocity
6. Update collider position if the entity has one

```lua
function PhysicsSystem:updateEntity(entity, dt)
    local transform = entity:getComponent("transform")
    local physics = entity:getComponent("physics")
    
    -- Skip if physics is disabled
    if physics.disabled then
        return
    end
    
    -- Apply gravity if enabled
    if physics.gravity then
        physics.velocityY = physics.velocityY + (physics.gravityScale or 1) * self.gravity * dt
        
        -- Limit to terminal velocity
        if physics.velocityY > self.terminalVelocity then
            physics.velocityY = self.terminalVelocity
        end
    end
    
    -- Apply friction if on ground
    if physics.onGround and physics.friction then
        physics.velocityX = physics.velocityX * (1 - physics.friction * dt)
        
        -- Stop completely if very slow (avoid floating point creep)
        if math.abs(physics.velocityX) < 0.1 then
            physics.velocityX = 0
        end
    end
    
    -- Apply air resistance
    if physics.airResistance and not physics.onGround then
        physics.velocityX = physics.velocityX * (1 - physics.airResistance * dt)
        physics.velocityY = physics.velocityY * (1 - physics.airResistance * dt)
    end
    
    -- Apply dampening
    if physics.dampening then
        physics.velocityX = physics.velocityX * (physics.dampening or self.dampening)
        physics.velocityY = physics.velocityY * (physics.dampening or self.dampening)
    end
    
    -- Apply velocity to position
    transform.x = transform.x + physics.velocityX * dt
    transform.y = transform.y + physics.velocityY * dt
    
    -- Update collider position if entity has one
    if entity:hasComponent("collider") then
        local collider = entity:getComponent("collider")
        
        -- Update bounds if entity has them
        if entity.bounds then
            entity.bounds.x = transform.x + collider.offsetX
            entity.bounds.y = transform.y + collider.offsetY
        end
    end
    
    -- Reset onGround flag (will be set by collision system if needed)
    physics.onGround = false
end
```

## Integration with Collision System

The physics system works closely with the collision system to handle collisions and ground detection:

1. The physics system updates entity positions based on their velocities
2. The collision system detects collisions between entities
3. The collision system sets the `onGround` flag for entities that are on the ground
4. The physics system applies friction to entities that are on the ground

## Integration with Legacy System

The ECS physics system is integrated with the legacy physics system through the `Bridge` module:

```lua
-- Convert a BaseEntity to an ECS entity
function Bridge.convertBaseEntityToECS(baseEntity, world)
    -- ...
    
    -- Add physics component
    entity:addComponent("physics", {
        velocityX = baseEntity.velocity.x,
        velocityY = baseEntity.velocity.y,
        gravity = baseEntity.gravity ~= nil,
        gravityScale = baseEntity.gravity / 400, -- Normalize to the system's gravity
        onGround = baseEntity.onGround,
        friction = 0.1,
        airResistance = 0.01,
        dampening = 0.98
    })
    
    -- ...
}

-- Update a BaseEntity from an ECS entity
function Bridge.updateBaseFromEntity(baseEntity, entity)
    -- ...
    
    -- Update velocity
    local physics = entity:getComponent("physics")
    baseEntity.velocity.x = physics.velocityX
    baseEntity.velocity.y = physics.velocityY
    baseEntity.onGround = physics.onGround
    
    -- ...
}
```

## Usage

### Creating an Entity with Physics

```lua
-- Create an entity with physics
local entity = world:createEntity()

-- Add transform component
entity:addComponent("transform", {
    x = 100,
    y = 200,
    width = 32,
    height = 32
})

-- Add physics component
entity:addComponent("physics", {
    velocityX = 0,
    velocityY = 0,
    gravity = true,
    gravityScale = 1,
    onGround = false,
    friction = 0.1,
    airResistance = 0.01,
    dampening = 0.98
})
```

### Applying Forces

```lua
-- Apply a force to an entity
function applyForce(entity, forceX, forceY)
    local physics = entity:getComponent("physics")
    
    physics.velocityX = physics.velocityX + forceX
    physics.velocityY = physics.velocityY + forceY
end

-- Apply a jump force
function jump(entity, jumpForce)
    local physics = entity:getComponent("physics")
    
    if physics.onGround then
        physics.velocityY = -jumpForce
        physics.onGround = false
    end
}
```

### Disabling Physics

```lua
-- Disable physics for an entity
function disablePhysics(entity)
    local physics = entity:getComponent("physics")
    physics.disabled = true
}

-- Enable physics for an entity
function enablePhysics(entity)
    local physics = entity:getComponent("physics")
    physics.disabled = false
}
```

## Performance Considerations

- The physics system is designed to be lightweight and efficient, suitable for 2D platformer games.
- Gravity and friction calculations are simple and fast, avoiding complex physics simulations.
- The system uses a simple dampening approach to simulate air resistance and friction.
- Entities with disabled physics are skipped entirely, reducing computational load.

## Future Improvements

1. **Continuous Collision Detection**: Implement continuous collision detection to handle fast-moving objects.
2. **Verlet Integration**: Use Verlet integration for more stable physics simulation.
3. **Constraints**: Add support for constraints like springs, joints, and ropes.
4. **Sleeping Entities**: Implement a sleeping system to avoid updating entities that are at rest.
5. **Impulse Resolution**: Improve collision response with impulse-based resolution.
6. **Rotational Physics**: Add support for rotational physics with angular velocity and torque. 