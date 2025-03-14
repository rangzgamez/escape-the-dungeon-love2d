-- examples/player_ecs_test/main.lua
-- Test script for PlayerECS implementation

-- Add the parent directory to the package path so we can require modules from the main project
package.path = package.path .. ";../../?.lua"

local love = require("love")
local ECS = require("lib/ecs/ecs")
local Bridge = require("lib/ecs/bridge")
local ECSEntity = require("entities/ecsEntity")
local PlayerECS = require("entities/playerECS")
local PlatformECS = require("entities/platformECS")
local MovingPlatformECS = require("entities/movingPlatformECS")
local SpringboardECS = require("entities/springboardECS")
local SlimeECS = require("entities/slimeECS")
local XpPelletECS = require("entities/xpPelletECS")
local Events = require("lib/events")
local Camera = require("lib/camera")
local EntityFactoryECS = require("entities/entityFactoryECS")

-- Global variables
local player
local camera
local ecsWorld
local factory
local platforms = {}
local enemies = {}
local xpPellets = {}

-- Debug settings
local debug = {
    collisionDebug = true,
    showFPS = true
}

function love.load()
    -- Initialize the ECS world
    ecsWorld = Bridge.createWorld()
    
    -- Set the ECS world for ECSEntity
    ECSEntity.setECSWorld(ecsWorld)
    
    -- Create the entity factory
    factory = EntityFactoryECS.new(ecsWorld)
    
    -- Create the player
    player = PlayerECS.new(100, 100)
    
    -- Create the camera
    camera = Camera.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    camera:setFollowStyle("PLATFORMER")
    camera:follow(player)
    
    -- Create some platforms
    platforms[1] = factory:createPlatform(400, 300, 800, 20)
    platforms[2] = factory:createPlatform(200, 200, 200, 20)
    platforms[3] = factory:createPlatform(600, 200, 200, 20)
    platforms[4] = factory:createPlatform(400, 100, 100, 20)
    
    -- Create some enemies
    enemies[1] = factory:createEnemy(300, 250, "basic")
    enemies[2] = factory:createEnemy(500, 250, "basic")
    
    -- Create some XP pellets
    for i = 1, 5 do
        local x = math.random(100, 700)
        local y = math.random(50, 250)
        local value = math.random(1, 5)
        local pellet = factory:createXpPellet(x, y, value)
        table.insert(xpPellets, pellet)
        print("XP Pellet at position (" .. x .. ", " .. y .. ") with value " .. value)
    end
    
    -- Enable collision debug drawing
    if debug.collisionDebug then
        Bridge.toggleCollisionDebug(ecsWorld)
    end
    
    -- Set up event handlers
    Events.on("xpCollected", function(data)
        print("XP collected: " .. data.value)
        if player and player.addExperience then
            player:addExperience(data.value)
        end
    end)
end

function love.update(dt)
    -- Update the ECS world
    ecsWorld:update(dt)
    
    -- Update the camera
    camera:update(dt)
end

function love.draw()
    camera:attach()
    
    -- Draw the ECS world
    ecsWorld:draw()
    
    camera:detach()
    
    -- Draw UI
    if debug.showFPS then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Pass key press to player
    if player and player.keypressed then
        player:keypressed(key)
    end
end

function love.keyreleased(key)
    -- Pass key release to player
    if player and player.keyreleased then
        player:keyreleased(key)
    end
end 