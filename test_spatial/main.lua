-- test_spatial.lua
-- Simple script to test the spatial partitioning example

-- Load the example
require("examples/spatial_partitioning_example")

-- This is a minimal Love2D game that just runs the example
function love.load()
    print("Test script loaded")
end

function love.update(dt)
    -- Nothing to update
end

function love.draw()
    love.graphics.print("Spatial partitioning example ran successfully. Check console output.", 50, 50)
end 