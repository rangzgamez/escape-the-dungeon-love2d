-- run_ecs_entity_example.lua
-- Script to run the ECSEntity example

local ECSEntityExample = require("examples/ecs_entity_example")

-- Example instance
local example

function love.load()
    -- Initialize the example
    example = ECSEntityExample.runExample()
end

function love.update(dt)
    -- Update the example
    example.update(dt)
end

function love.draw()
    -- Draw the example
    example.draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end 