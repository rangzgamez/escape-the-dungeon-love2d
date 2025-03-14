-- examples/ecs_entity_example.lua
-- Example demonstrating the use of ECSEntity

local ECS = require("lib/ecs/ecs")
local Bridge = require("lib/ecs/bridge")
local ECSEntity = require("entities/ecsEntity")
local Events = require("lib/events")

-- Create a simple game entity that extends ECSEntity
local SimpleEntity = {}
SimpleEntity.__index = SimpleEntity
setmetatable(SimpleEntity, {__index = ECSEntity})

function SimpleEntity:new(x, y, width, height, color)
    -- Call the parent constructor
    local self = ECSEntity:new(x, y, width, height, {
        type = "simple",
        collisionLayer = "default",
        collidesWithLayers = {"default"}
    })
    
    -- Set the metatable to SimpleEntity
    setmetatable(self, SimpleEntity)
    
    -- Add custom properties
    self.color = color or {1, 0, 0, 1}  -- Default to red
    self.speed = 100
    
    -- Add custom components to the ECS entity if available
    if self.ecsEntity then
        -- Add a custom renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "rectangle",
            layer = 10,
            width = width,
            height = height,
            color = self.color,
            mode = "fill"
        })
    end
    
    return self
end

-- Override the draw method
function SimpleEntity:draw()
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw collision box in debug mode
    if self.debug then
        love.graphics.setColor(1, 0, 0, 0.5)
        local bounds = self:getBounds()
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

-- Custom update method
function SimpleEntity:update(dt)
    -- Call parent update to sync with ECS
    ECSEntity.update(self, dt)
    
    -- Add custom behavior
    -- For example, move in a circle
    local time = love.timer.getTime()
    self:setVelocity(
        math.cos(time) * self.speed,
        math.sin(time) * self.speed
    )
end

-- Example usage
local function runExample()
    -- Create an ECS world
    local world = Bridge.createWorld()
    
    -- Set the ECS world for ECSEntity
    ECSEntity.setECSWorld(world)
    
    -- Create some entities
    local entities = {}
    for i = 1, 10 do
        local x = love.math.random(50, 750)
        local y = love.math.random(50, 550)
        local width = love.math.random(20, 50)
        local height = love.math.random(20, 50)
        local color = {
            love.math.random(),
            love.math.random(),
            love.math.random(),
            1
        }
        
        local entity = SimpleEntity:new(x, y, width, height, color)
        entity.speed = love.math.random(50, 150)
        entity.debug = true  -- Show collision bounds
        
        table.insert(entities, entity)
    end
    
    -- Set up collision event handler
    Events.on("collision:simple:simple", function(data)
        print("Collision between entities!")
        
        -- Change colors on collision
        local entityA = data.entityA
        local entityB = data.entityB
        
        -- Swap colors
        local tempColor = entityA.color
        entityA.color = entityB.color
        entityB.color = tempColor
        
        -- Update renderer components
        if entityA.ecsEntity and entityA.ecsEntity:hasComponent("renderer") then
            entityA.ecsEntity:getComponent("renderer").color = entityA.color
        end
        
        if entityB.ecsEntity and entityB.ecsEntity:hasComponent("renderer") then
            entityB.ecsEntity:getComponent("renderer").color = entityB.color
        end
    end)
    
    -- Main loop
    local function update(dt)
        -- Update the ECS world
        world:update(dt)
        
        -- Update entities
        for _, entity in ipairs(entities) do
            entity:update(dt)
        end
    end
    
    local function draw()
        -- Draw entities
        for _, entity in ipairs(entities) do
            entity:draw()
        end
        
        -- Draw debug info
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("ECSEntity Example", 10, 10)
        love.graphics.print("Entities: " .. #entities, 10, 30)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 50)
    end
    
    return {
        update = update,
        draw = draw,
        world = world,
        entities = entities
    }
end

return {
    runExample = runExample
} 