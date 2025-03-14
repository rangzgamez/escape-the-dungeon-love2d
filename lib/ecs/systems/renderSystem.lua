-- lib/ecs/systems/renderSystem.lua
-- Render System for drawing entities

local System = require("lib/ecs/system")

local RenderSystem = setmetatable({}, {__index = System})
RenderSystem.__index = RenderSystem

function RenderSystem.create()
    local self = setmetatable(System.create("RenderSystem"), RenderSystem)
    
    -- Set required components
    self:requires("transform", "renderer")
    
    -- Set priority (run after all other systems)
    self:setPriority(100)
    
    -- Render layers (lower numbers draw first)
    self.layers = {
        background = 0,
        platforms = 10,
        items = 20,
        enemies = 30,
        player = 40,
        effects = 50,
        ui = 100
    }
    
    return self
end

-- Draw all entities
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

-- Draw a single entity
function RenderSystem:drawEntity(entity)
    local transform = entity:getComponent("transform")
    local renderer = entity:getComponent("renderer")
    
    -- Skip if missing required components
    if not transform or not renderer then
        return
    end
    
    -- Ensure transform has valid position values
    if not transform.x or not transform.y then
        if transform.position then
            transform.x = transform.position.x
            transform.y = transform.position.y
        else
            transform.x = 0
            transform.y = 0
        end
    end
    
    -- Save current transformation state
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(transform.x, transform.y)
    love.graphics.rotate(transform.rotation or 0)
    love.graphics.scale(transform.scaleX or 1, transform.scaleY or 1)
    
    -- Set color
    if renderer.color then
        love.graphics.setColor(unpack(renderer.color))
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    
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
    
    -- Restore transformation state
    love.graphics.pop()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return RenderSystem 