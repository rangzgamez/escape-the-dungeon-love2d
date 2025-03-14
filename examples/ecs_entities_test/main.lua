-- examples/ecs_entities_test/main.lua
-- Test script for ECS entities

local ECS = require("lib/ecs/ecs")
local EntityFactoryECS = require("entities/entityFactoryECS")
local Events = require("lib/events")
local Camera = {}
local PowerUpManager = require("managers/powerUpManager")
local ECSEntity = require("entities/ecsEntity")

-- Simple camera implementation for the test
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    
    self.x = 0
    self.y = 0
    self.target = nil
    self.smoothness = 0.1
    
    return self
end

function Camera:setTarget(target)
    self.target = target
end

function Camera:update(dt)
    if self.target then
        local targetX = self.target.x + self.target.width / 2 - love.graphics.getWidth() / 2
        local targetY = self.target.y + self.target.height / 2 - love.graphics.getHeight() / 2
        
        self.x = self.x + (targetX - self.x) * self.smoothness
        self.y = self.y + (targetY - self.y) * self.smoothness
    end
end

function Camera:apply()
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end

function Camera:reset()
    love.graphics.pop()
end

-- Game state
local world
local entityFactory
local camera
local powerUpManager
local entities = {}
local testEntities = {}

-- Initialize the game
function love.load()
    -- Create ECS world
    world = ECS.createWorld()
    
    -- Set the ECS world for ECSEntity
    ECSEntity.setECSWorld(world)
    
    -- Register ECS systems
    world.systemManager:addSystem(require("lib/ecs/systems/physicsSystem").create())
    world.systemManager:addSystem(require("lib/ecs/systems/collisionSystem").create())
    world.systemManager:addSystem(require("lib/ecs/systems/renderSystem").create())
    world.systemManager:addSystem(require("lib/ecs/systems/xpSystem").create())
    
    -- Create entity factory
    entityFactory = EntityFactoryECS.new(world)
    
    -- Create camera
    camera = Camera:new()
    
    -- Create power-up manager
    powerUpManager = PowerUpManager:new()
    powerUpManager:setECSWorld(world)
    
    -- Create test entities
    createTestEntities()
    
    -- Set up event listeners
    setupEventListeners()
    
    -- Print instructions
    print("ECS Entities Test")
    print("Controls:")
    print("  R - Reset test")
end

-- Create test entities
function createTestEntities()
    -- Clear existing test entities
    testEntities = {}
    
    -- Create platforms
    local platform1 = entityFactory:createPlatform(300, 500, 200, 20)
    table.insert(testEntities, platform1)
    
    local platform2 = entityFactory:createPlatform(600, 400, 200, 20)
    table.insert(testEntities, platform2)
    
    local movingPlatform = entityFactory:createMovingPlatform(100, 350, 150, 20, 300, 450, 50)
    table.insert(testEntities, movingPlatform)
    
    local springboard = entityFactory:createSpringboard(400, 550, 50, 10)
    table.insert(testEntities, springboard)
    
    -- Create bats
    local bat1 = entityFactory:createBat(500, 200)
    table.insert(testEntities, bat1)
    
    local bat2 = entityFactory:createBat(300, 150)
    table.insert(testEntities, bat2)
    
    -- Create power-ups
    local powerUp1 = entityFactory:createPowerUp(200, 200, "HEALTH")
    table.insert(testEntities, powerUp1)
    
    local powerUp2 = entityFactory:createPowerUp(600, 200, "DOUBLE_JUMP")
    table.insert(testEntities, powerUp2)
    
    local powerUp3 = entityFactory:createPowerUp(400, 150, "SHIELD")
    table.insert(testEntities, powerUp3)
    
    -- Create XP pellets
    for i = 1, 5 do
        local x = love.math.random(100, 700)
        local y = love.math.random(50, 250)
        local value = love.math.random(1, 5)
        local pellet = entityFactory:createXpPellet(x, y, value)
        table.insert(testEntities, pellet)
        print("XP Pellet at position (" .. x .. ", " .. y .. ") with value " .. value)
    end
    
    -- Add all entities to the main entities table
    for _, entity in ipairs(testEntities) do
        table.insert(entities, entity)
    end
end

-- Set up event listeners
function setupEventListeners()
    Events.on("powerupCollected", function(data)
        print("Power-up collected: " .. data.type .. " - " .. data.message)
    end)
    
    Events.on("xpCollected", function(data)
        print("XP collected: " .. data.value)
    end)
    
    Events.on("enemyHit", function(data)
        print("Enemy hit: " .. data.enemy.type)
    end)
    
    Events.on("playerHit", function(data)
        print("Player hit by: " .. data.source.type .. " - Damage: " .. data.damage)
    end)
end

-- Update the game
function love.update(dt)
    -- Update ECS world
    world:update(dt)
    
    -- Update entities
    for _, entity in ipairs(entities) do
        if entity.update then
            entity:update(dt)
        end
    end
    
    -- Update power-up manager
    powerUpManager:update(dt, nil, camera)
    
    -- Update camera
    camera:update(dt)
    
    -- Clean up inactive entities
    for i = #entities, 1, -1 do
        if not entities[i].active then
            table.remove(entities, i)
        end
    end
end

-- Key press handler
function love.keypressed(key)
    if key == "r" then
        -- Reset test
        createTestEntities()
    end
end

-- Draw the game
function love.draw()
    -- Apply camera transformation
    camera:apply()
    
    -- Draw entities
    for _, entity in ipairs(entities) do
        if entity.draw then
            entity:draw()
        end
    end
    
    -- Draw power-ups
    powerUpManager:draw()
    
    -- Reset camera transformation
    camera:reset()
    
    -- Draw UI
    drawUI()
end

-- Draw UI
function drawUI()
    -- Draw stats
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ECS Entities Test", 10, 10)
    love.graphics.print("Entities: " .. #entities, 10, 30)
    
    -- Draw controls reminder
    love.graphics.print("R - Reset Test", 10, love.graphics.getHeight() - 30)
end 