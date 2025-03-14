# ECS Render System

## Overview

The Entity Component System (ECS) Render System is responsible for drawing entities on the screen. It provides a flexible and efficient way to render different types of entities with various visual representations, including rectangles, circles, sprites, text, and custom drawing functions.

## Components

### Transform Component

The `transform` component defines the position, dimensions, and transformation properties of an entity:

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

### Renderer Component

The `renderer` component defines how an entity is drawn:

```lua
-- Rectangle renderer
entity:addComponent("renderer", {
    type = "rectangle",    -- Renderer type
    layer = 10,            -- Render layer (lower numbers draw first)
    width = 32,            -- Width
    height = 32,           -- Height
    color = {1, 0, 0, 1},  -- Color (RGBA)
    mode = "fill"          -- Fill mode ("fill" or "line")
})

-- Circle renderer
entity:addComponent("renderer", {
    type = "circle",       -- Renderer type
    layer = 10,            -- Render layer
    radius = 16,           -- Radius
    color = {0, 1, 0, 1},  -- Color
    mode = "fill"          -- Fill mode
})

-- Sprite renderer
entity:addComponent("renderer", {
    type = "sprite",       -- Renderer type
    layer = 10,            -- Render layer
    image = spriteImage,   -- Love2D Image object
    width = 32,            -- Width
    height = 32,           -- Height
    color = {1, 1, 1, 1}   -- Color tint
})

-- Text renderer
entity:addComponent("renderer", {
    type = "text",         -- Renderer type
    layer = 10,            -- Render layer
    text = "Hello, World!",-- Text to display
    color = {1, 1, 1, 1},  -- Color
    scale = 1              -- Text scale
})

-- Custom renderer
entity:addComponent("renderer", {
    type = "custom",       -- Renderer type
    layer = 10,            -- Render layer
    color = {1, 1, 1, 1},  -- Color
    drawFunction = function(entity)
        -- Custom drawing code
        local transform = entity:getComponent("transform")
        love.graphics.rectangle("fill", 0, 0, transform.width, transform.height)
    end
})
```

## Render System

The `RenderSystem` is responsible for drawing entities on the screen. It sorts entities by layer and applies transformations before drawing them.

### Render Layers

The system defines default render layers to control the drawing order:

```lua
self.layers = {
    background = 0,
    platforms = 10,
    items = 20,
    enemies = 30,
    player = 40,
    effects = 50,
    ui = 100
}
```

Entities with lower layer numbers are drawn first, and entities with higher layer numbers are drawn on top.

### Drawing Entities

The system draws entities in the following steps:

1. Get all entities with transform and renderer components
2. Sort entities by layer
3. Draw each active entity

```lua
function RenderSystem:draw(entityManager)
    -- Get all entities with transform and renderer components
    local entities = entityManager:getEntitiesWith("transform", "renderer")
    
    -- Sort entities by layer
    table.sort(entities, function(a, b)
        local layerA = a:getComponent("renderer").layer or 0
        local layerB = b:getComponent("renderer").layer or 0
        return layerA < layerB
    end)
    
    -- Draw each entity
    for _, entity in ipairs(entities) do
        if entity.active then
            self:drawEntity(entity)
        end
    end
end
```

### Transformations

The system applies transformations to each entity before drawing it:

```lua
-- Apply transformations
love.graphics.push()
love.graphics.translate(transform.x, transform.y)
love.graphics.rotate(transform.rotation or 0)
love.graphics.scale(transform.scaleX or 1, transform.scaleY or 1)
```

This allows entities to be positioned, rotated, and scaled independently.

### Renderer Types

The system supports several renderer types:

- **Rectangle**: Draws a rectangle with the specified width, height, color, and fill mode.
- **Circle**: Draws a circle with the specified radius, color, and fill mode.
- **Polygon**: Draws a polygon with the specified vertices, color, and fill mode.
- **Sprite**: Draws an image with the specified width, height, and color tint.
- **Text**: Draws text with the specified color and scale.
- **Custom**: Calls a custom drawing function to draw the entity.

```lua
-- Draw based on renderer type
if renderer.type == "rectangle" then
    love.graphics.rectangle(
        renderer.mode or "fill",
        0, 0,
        renderer.width, renderer.height
    )
elseif renderer.type == "circle" then
    love.graphics.circle(
        renderer.mode or "fill",
        renderer.radius, renderer.radius,
        renderer.radius
    )
elseif renderer.type == "polygon" then
    love.graphics.polygon(
        renderer.mode or "fill",
        unpack(renderer.vertices)
    )
elseif renderer.type == "sprite" and renderer.image then
    love.graphics.draw(
        renderer.image,
        0, 0,
        0,
        renderer.width / renderer.image:getWidth(),
        renderer.height / renderer.image:getHeight()
    )
elseif renderer.type == "text" and renderer.text then
    love.graphics.print(
        renderer.text,
        0, 0,
        0,
        renderer.scale or 1,
        renderer.scale or 1
    )
elseif renderer.type == "custom" and renderer.drawFunction then
    -- Call custom draw function
    renderer.drawFunction(entity)
end
```

## Integration with Legacy System

The ECS render system is integrated with the legacy rendering system through the `Bridge` module:

```lua
-- Convert a BaseEntity to an ECS entity
function Bridge.convertBaseEntityToECS(baseEntity, world)
    -- ...
    
    -- Add renderer component
    if baseEntity.type == "xpPellet" then
        entity:addComponent("renderer", {
            type = "custom",
            layer = 20,
            color = baseEntity.color,
            drawFunction = function(entity)
                world.systemManager:getSystem("XpSystem"):drawXpPellet(entity)
            end
        })
    else
        entity:addComponent("renderer", {
            type = "rectangle",
            layer = 10,
            width = baseEntity.width,
            height = baseEntity.height,
            color = {1, 1, 1, 1},
            mode = "fill"
        })
    end
    
    -- ...
}
```

## Usage

### Creating an Entity with a Renderer

```lua
-- Create an entity with a renderer
local entity = world:createEntity()

-- Add transform component
entity:addComponent("transform", {
    x = 100,
    y = 200,
    width = 32,
    height = 32
})

-- Add renderer component
entity:addComponent("renderer", {
    type = "rectangle",
    layer = 10,
    width = 32,
    height = 32,
    color = {1, 0, 0, 1},
    mode = "fill"
})
```

### Creating a Custom Renderer

```lua
-- Create an entity with a custom renderer
local entity = world:createEntity()

-- Add transform component
entity:addComponent("transform", {
    x = 100,
    y = 200,
    width = 32,
    height = 32
})

-- Add custom renderer component
entity:addComponent("renderer", {
    type = "custom",
    layer = 10,
    color = {1, 1, 1, 1},
    drawFunction = function(entity)
        local transform = entity:getComponent("transform")
        
        -- Draw a custom shape
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, transform.width, transform.height/2)
        
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", 0, transform.height/2, transform.width, transform.height/2)
    end
})
```

### Drawing the World

```lua
-- Draw all entities in the world
function love.draw()
    -- Apply camera transformation
    love.graphics.push()
    love.graphics.translate(0, -camera.y + love.graphics.getHeight() / 2)
    
    -- Draw the world
    ecsWorld:draw()
    
    -- Restore transformation
    love.graphics.pop()
    
    -- Draw UI elements (not affected by camera)
    drawUI()
end
```

## Performance Considerations

- Entities are sorted by layer each frame, which can be expensive with a large number of entities.
- Custom drawing functions should be optimized to avoid unnecessary calculations.
- The system uses Love2D's transformation stack, which can be slower than manually calculating transformations.
- Consider using sprite batches for rendering large numbers of similar entities.

## Future Improvements

1. **Sprite Animation**: Add support for sprite animations with frame-based or time-based animations.
2. **Particle Systems**: Integrate with Love2D's particle system for efficient particle effects.
3. **Render Targets**: Support for rendering to off-screen canvases for post-processing effects.
4. **Culling**: Implement frustum culling to avoid drawing entities that are off-screen.
5. **Batching**: Implement batching for similar entities to reduce draw calls.
6. **Shaders**: Support for custom shaders to create advanced visual effects. 