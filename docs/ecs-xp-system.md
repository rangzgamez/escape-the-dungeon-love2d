# ECS XP System

## Overview

The Entity Component System (ECS) XP System manages the creation, behavior, and collection of experience points (XP) in the game. XP pellets are dropped by enemies when they are defeated and can be collected by the player to gain experience and level up.

## Components

### XP Component

The `xp` component defines the XP properties of an entity:

```lua
entity:addComponent("xp", {
    value = 1,              -- XP value when collected
    collectible = false,    -- Whether the pellet can be collected
    collectionDelay = 0.5,  -- Delay before pellet becomes collectible
    lifetime = 15.0,        -- How long the pellet exists before disappearing
    magnetizable = false    -- Whether the pellet can be attracted to the player
})
```

### Transform Component

The `transform` component defines the position and dimensions of an entity:

```lua
entity:addComponent("transform", {
    x = 100,               -- X position
    y = 200,               -- Y position
    width = 20,            -- Visual width
    height = 20,           -- Visual height
    rotation = 0,          -- Rotation in radians
    scaleX = 1,            -- X scale
    scaleY = 1             -- Y scale
})
```

### Physics Component

The `physics` component defines the movement properties of an entity:

```lua
entity:addComponent("physics", {
    velocityX = 0,         -- X velocity
    velocityY = 0,         -- Y velocity
    gravity = false,       -- Whether gravity affects this entity
    gravityScale = 0,      -- Gravity multiplier
    onGround = false,      -- Whether the entity is on the ground
    friction = 0.1,        -- Ground friction
    airResistance = 0.01,  -- Air resistance
    dampening = 0.98       -- Velocity dampening
})
```

### Renderer Component

The `renderer` component defines how the entity is drawn:

```lua
entity:addComponent("renderer", {
    type = "custom",       -- Renderer type (custom for XP pellets)
    layer = 20,            -- Render layer (higher numbers render on top)
    color = {0.2, 0.8, 1}, -- Color
    drawFunction = function(entity)
        -- Custom drawing function
        xpSystem:drawXpPellet(entity)
    end
})
```

## XP System

The `XpSystem` is responsible for managing XP pellets, including their creation, behavior, and collection.

### Creating XP Pellets

XP pellets are created when enemies are defeated:

```lua
function XpSystem:onEnemyKill(entityManager, enemy, comboCount)
    -- Determine XP amount based on enemy type and combo
    local enemyType = enemy:getComponent("type")
    local baseXp = 5
    
    -- Bonus XP for combo
    local comboBonus = math.floor(comboCount / 2)
    local totalXp = baseXp + comboBonus
    
    -- Distribute XP across multiple pellets
    local pelletCount = math.min(totalXp, 5) -- Max 5 pellets
    local xpPerPellet = math.ceil(totalXp / pelletCount)
    
    -- Get enemy position
    local enemyTransform = enemy:getComponent("transform")
    local enemyCenterX = enemyTransform.x + enemyTransform.width / 2
    local enemyCenterY = enemyTransform.y + enemyTransform.height / 2
    
    -- Create pellets around the enemy
    local pellets = {}
    
    for i = 1, pelletCount do
        local pellet = entityManager:getPooledEntity("xpPellet")
        
        -- Add components
        pellet:addComponent("transform", {
            x = enemyCenterX + love.math.random(-10, 10),
            y = enemyCenterY + love.math.random(-10, 10),
            width = 20,
            height = 20
        })
        
        pellet:addComponent("physics", {
            velocityX = math.cos(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            velocityY = math.sin(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            gravity = false,
            dampening = 0.95
        })
        
        pellet:addComponent("xp", {
            value = xpPerPellet,
            collectible = false,
            collectionDelay = 0.5,
            lifetime = 15.0,
            magnetizable = false
        })
        
        -- Add to pellets list
        table.insert(pellets, pellet)
    end
    
    return pellets
end
```

### Updating XP Pellets

XP pellets are updated each frame to handle their behavior:

```lua
function XpSystem:updateXpEntity(entity, dt, player)
    local transform = entity:getComponent("transform")
    local xp = entity:getComponent("xp")
    local physics = entity:getComponent("physics")
    
    -- Update collection delay
    if not xp.collectible then
        xp.collectionDelay = xp.collectionDelay - dt
        if xp.collectionDelay <= 0 then
            xp.collectible = true
            xp.magnetizable = true
            
            -- Stop all movement when becoming collectible
            if physics then
                physics.velocityX = 0
                physics.velocityY = 0
            end
        end
    end
    
    -- Update lifetime
    xp.lifetime = xp.lifetime - dt
    if xp.lifetime <= 0 then
        entity.active = false
        return
    end
    
    -- Apply magnetic attraction if player exists
    if player and xp.collectible and xp.magnetizable then
        self:applyMagneticAttraction(entity, player, dt)
    end
end
```

### Magnetic Attraction

XP pellets can be attracted to the player when they are within a certain radius:

```lua
function XpSystem:applyMagneticAttraction(entity, player, dt)
    local transform = entity:getComponent("transform")
    local playerTransform = player:getComponent("transform")
    
    -- Calculate distance to player
    local dx = playerTransform.x - transform.x
    local dy = playerTransform.y - transform.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Collection radius
    local magnetRadius = self.baseCollectionRadius + self.collectionRadiusBonus
    
    -- Check if player has magnetic upgrade
    local magnetActive = player:hasComponent("upgrades") and 
                         player:getComponent("upgrades").magneticAttraction
    
    -- Apply magnetic force if within radius
    if distance < magnetRadius then
        -- Normalize direction
        local nx = dx / distance
        local ny = dy / distance
        
        -- Calculate attraction strength (stronger when closer)
        local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength
        
        -- Move entity toward player
        transform.x = transform.x + nx * strength * dt
        transform.y = transform.y + ny * strength * dt
        
        -- Update bounds if entity has them
        if entity.bounds then
            local collider = entity:getComponent("collider")
            if collider then
                entity.bounds.x = transform.x + collider.offsetX
                entity.bounds.y = transform.y + collider.offsetY
            end
        end
    end
end
```

### Drawing XP Pellets

XP pellets have a custom drawing function:

```lua
function XpSystem:drawXpPellet(entity)
    local transform = entity:getComponent("transform")
    local xp = entity:getComponent("xp")
    
    -- Set color based on collectible state
    love.graphics.setColor(0.2, 0.8, 1, xp.collectible and 0.9 or 0.6)
    
    -- Draw pellet shape
    love.graphics.circle("fill", transform.width/2, transform.height/2, transform.width/2 * 0.8)
    
    -- Draw a small triangle on top
    love.graphics.setColor(0.9, 0.9, 1, xp.collectible and 0.9 or 0.6)
    love.graphics.line(
        transform.width/4, transform.height/4,
        transform.width/2, 0,
        3 * transform.width/4, transform.height/4
    )
    
    -- Add a small "XP" text in the center for clarity
    love.graphics.setColor(1, .5, .5, xp.collectible and 0.9 or 0.6)
    local font = love.graphics.getFont()
    local text = "XP"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, transform.width/2 - textWidth/2, transform.height/2 - textHeight/2, 0, 0.7, 0.7)
    
    -- Draw debug info if needed
    if entity:hasComponent("debug") and entity:getComponent("debug").enabled then
        -- Draw position info
        local posText = string.format("Pos: %.0f, %.0f", transform.x, transform.y)
        local posWidth = font:getWidth(posText)
        
        -- Draw background for position text
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 
            transform.width/2 - posWidth/2 - 4, 
            transform.height + 10,
            posWidth + 8,
            20)
            
        -- Draw position text
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow for position
        love.graphics.print(
            posText, 
            transform.width/2 - posWidth/2, 
            transform.height + 12,
            0,
            1.0, 1.0
        )
    end
end
```

## Collecting XP Pellets

XP pellets are collected when they collide with the player:

```lua
function Bridge.handleCollision(entityA, entityB, collisionData)
    -- Get entity types
    local typeA = entityA:getComponent("type").name
    local typeB = entityB:getComponent("type").name
    
    -- Handle XP pellet collection
    if (typeA == "xpPellet" and typeB == "player") or
       (typeA == "player" and typeB == "xpPellet") then
        local pellet = typeA == "xpPellet" and entityA or entityB
        local player = typeA == "player" and entityA or entityB
        
        local xp = pellet:getComponent("xp")
        
        if xp.collectible then
            -- Collect the XP
            Events.fire("xpCollected", {
                value = xp.value,
                player = player
            })
            
            -- Deactivate the pellet
            pellet:deactivate()
            
            -- Return to pool
            world:returnToPool(pellet)
        end
    end
end
```

## Integration with Legacy System

The ECS XP system is integrated with the legacy XP system through the `Bridge` module:

```lua
-- Create XP pellets using the ECS system
function Bridge.createXpPellets(world, x, y, count, value)
    local xpSystem = world.systemManager:getSystem("XpSystem")
    local pellets = {}
    
    for i = 1, count do
        local pellet = world:getPooledEntity("xpPellet")
        
        -- Add components
        pellet:addComponent("transform", {
            x = x + love.math.random(-10, 10),
            y = y + love.math.random(-10, 10),
            width = 20,
            height = 20
        })
        
        pellet:addComponent("physics", {
            velocityX = math.cos(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            velocityY = math.sin(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            gravity = false,
            dampening = 0.95
        })
        
        pellet:addComponent("collider", {
            offsetX = 0,
            offsetY = 0,
            width = 20,
            height = 20,
            layer = "collectible",
            collidesWithLayers = {"player"}
        })
        
        pellet:addComponent("renderer", {
            type = "custom",
            layer = 20,
            color = {0.2, 0.8, 1},
            drawFunction = function(entity)
                xpSystem:drawXpPellet(entity)
            end
        })
        
        pellet:addComponent("xp", {
            value = value or 1,
            collectible = false,
            collectionDelay = 0.5,
            lifetime = 15.0,
            magnetizable = false
        })
        
        pellet:addComponent("type", {
            name = "xpPellet"
        })
        
        -- Add debug component
        pellet:addComponent("debug", {
            enabled = true
        })
        
        table.insert(pellets, pellet)
    end
    
    return pellets
end
```

## Object Pooling

The XP system uses object pooling to reduce garbage collection and improve performance:

```lua
-- Get a pooled entity
local pellet = world:getPooledEntity("xpPellet")

-- Return an entity to its pool
world:returnToPool(pellet)
```

## Debug Visualization

XP pellets include debug visualization to help with development and troubleshooting:

```lua
-- Draw debug info if needed
if entity:hasComponent("debug") and entity:getComponent("debug").enabled then
    -- Draw position info
    local posText = string.format("Pos: %.0f, %.0f", transform.x, transform.y)
    local posWidth = font:getWidth(posText)
    
    -- Draw background for position text
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 
        transform.width/2 - posWidth/2 - 4, 
        transform.height + 10,
        posWidth + 8,
        20)
        
    -- Draw position text
    love.graphics.setColor(1, 1, 0, 1)  -- Yellow for position
    love.graphics.print(
        posText, 
        transform.width/2 - posWidth/2, 
        transform.height + 12,
        0,
        1.0, 1.0
    )
}
```

## Usage

### Creating XP Pellets

```lua
-- Create XP pellets when an enemy is killed
Events.on("enemyKill", function(data)
    -- Get the XP system
    local xpSystem = ecsWorld.systemManager:getSystem("XpSystem")
    if xpSystem then
        -- Create XP pellets using the ECS system
        xpSystem:onEnemyKill(ecsWorld.entityManager, data.enemy, data.comboCount)
    end
end)
```

### Handling XP Collection

```lua
-- Set up collision event handlers
Events.on("collision:player:xpPellet", function(data)
    Bridge.handleCollision(data.entityA, data.entityB, data.collisionData)
end)

-- Listen for XP collected events
Events.on("xpCollected", function(data)
    -- Update player XP
    local player = data.player
    local value = data.value
    
    -- Add XP to player
    player:addXp(value)
    
    -- Check for level up
    if player:checkLevelUp() then
        -- Show level up menu
        levelUpMenu:show()
    end
end)
```

### Testing XP Pellets

```lua
-- Spawn test XP pellets
function spawnTestXpPellets()
    local pelletCount = 10
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    
    -- Create pellets using the ECS system
    local pellets = Bridge.createXpPellets(ecsWorld, centerX, centerY, pelletCount, 1)
    
    -- Enable debug mode for all pellets
    for _, pellet in ipairs(pellets) do
        pellet:getComponent("debug").enabled = true
    end
    
    print("Spawned " .. pelletCount .. " test XP pellets")
end
```

## Performance Considerations

- Object pooling is used to reduce garbage collection and improve performance.
- XP pellets are deactivated and returned to the pool when collected or when their lifetime expires.
- The magnetic attraction calculation only applies to pellets within a certain radius of the player.

## Future Improvements

1. **Visual Effects**: Add particle effects when XP pellets are collected.
2. **Sound Effects**: Add sound effects when XP pellets are collected.
3. **XP Types**: Support for different types of XP pellets with different values and behaviors.
4. **Attraction Upgrades**: More advanced magnetic attraction upgrades for the player.
5. **XP Multipliers**: Support for XP multipliers based on player upgrades or game state. 