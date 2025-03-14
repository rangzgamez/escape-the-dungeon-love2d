-- world.lua - World generation for Love2D Vertical Jumper

local World = {}
World.__index = World

local CollisionManager = require("managers/collisionManager")
local PowerUpManager = require("managers/powerUpManager")
local EntityFactoryECS = require("entities/entityFactoryECS")

function World:new()
    local self = setmetatable({}, World)
    
    -- World generation parameters
    self.highestPlatformY = love.graphics.getHeight() - 50  -- Start near bottom of screen
    self.minHorizontalGap = 20
    self.maxHorizontalGap = love.graphics.getWidth() * 0.4 -- Scale to screen width
    self.minVerticalGap = 80   -- Minimum vertical distance between platforms
    self.maxVerticalGap = 150  -- Maximum vertical distance between platforms
    self.minPlatformWidth = 60
    self.maxPlatformWidth = love.graphics.getWidth() * 0.5 -- Scale to screen width
    self.platformHeight = 20
    self.screenWidth = love.graphics.getWidth()
    self.springboardChance = 0.3 -- 30% chance of a springboard on a platform
    self.generationDistance = 1000 -- Generate platforms this far ahead of camera
    self.powerUpManager = PowerUpManager:new()
    
    -- Create entity factory if ECS world is available
    if _G.ecsWorld then
        self.entityFactory = EntityFactoryECS.new(_G.ecsWorld)
    end
    
    return self
end

function World:generateInitialPlatforms(platforms, springboards)
    -- Add the starting platform (wider for easier start)
    local startX = love.graphics.getWidth() / 2 - love.graphics.getWidth() * 0.25
    local startY = love.graphics.getHeight() - 50
    
    local platform
    if self.entityFactory then
        platform = self.entityFactory:createPlatform(startX, startY, love.graphics.getWidth() * 0.5, self.platformHeight)
    else
        -- Fallback to old system if ECS is not available
        local Platform = require("entities/platform")
        platform = Platform:new(startX, startY, love.graphics.getWidth() * 0.5, self.platformHeight)
    end
    
    table.insert(platforms, platform)
    self.highestPlatformY = startY
    
    -- Generate initial set of platforms going upward
    for i = 1, 15 do
        self:generateNextPlatform(platforms, springboards)
    end
end

function World:generateNextPlatform(platforms, springboards)
    -- Generate random vertical gap
    local verticalGap = love.math.random(self.minVerticalGap, self.maxVerticalGap)
    local platformY = self.highestPlatformY - verticalGap
    
    -- Generate random platform width
    local platformWidth = love.math.random(self.minPlatformWidth, self.maxPlatformWidth)
    
    -- Generate random X position within screen bounds
    local platformX = love.math.random(0, self.screenWidth - platformWidth)
    
    -- Create new platform
    local platform
    local springboard = nil
    
    if self.entityFactory then
        -- Use ECS entities
        platform = self.entityFactory:createPlatform(platformX, platformY, platformWidth, self.platformHeight)
        
        -- Randomly add a springboard to the platform
        if love.math.random() < self.springboardChance then
            local springX = platformX + platformWidth/2 - 25  -- Center on platform
            springboard = self.entityFactory:createSpringboard(springX, platformY - 20, 50, 20)
        end
    else
        -- Fallback to old system
        local Platform = require("entities/platform")
        local Springboard = require("entities/springboard")
        
        platform = Platform:new(platformX, platformY, platformWidth, self.platformHeight)
        
        -- Randomly add a springboard to the platform
        if love.math.random() < self.springboardChance then
            local springX = platformX + platformWidth/2 - 25  -- Center on platform
            springboard = Springboard:new(springX, platformY - 20, 50, 20)
        end
    end
    
    table.insert(platforms, platform)
    self.highestPlatformY = platformY
    
    if springboard then
        table.insert(springboards, springboard)
    end
    
    self.powerUpManager:tryPlatformSpawn(platform)
    
    return platform, springboard
end

function World:updatePlatforms(camera, platforms, springboards)
    local newPlatforms = {}
    local newSpringboards = {}
    
    -- Generate new platforms if needed
    while self.highestPlatformY > camera.y - self.generationDistance do
        local platform, springboard = self:generateNextPlatform(platforms, springboards)
        
        if platform then
            table.insert(newPlatforms, platform)
            -- Add new platform to collision system
            CollisionManager.addEntity(platform)
        end
        
        if springboard then
            table.insert(newSpringboards, springboard)
            -- Add new springboard to collision system
            CollisionManager.addEntity(springboard)
        end
    end
    
    return newPlatforms, newSpringboards
end

function World:cleanupPlatforms(camera, platforms, springboards, removeCallback)
    -- Remove platforms and springboards that are too far below the camera
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    -- Remove old platforms
    for i = #platforms, 1, -1 do
        if platforms[i].y > removalThreshold then
            if removeCallback then
                removeCallback(platforms[i])
            end
            
            -- Deactivate ECS entity if it exists
            if platforms[i].ecsEntity then
                platforms[i]:destroy()
            end
            
            table.remove(platforms, i)
        end
    end
    
    -- Remove old springboards
    for i = #springboards, 1, -1 do
        if springboards[i].y > removalThreshold then
            if removeCallback then
                removeCallback(springboards[i])
            end
            
            -- Deactivate ECS entity if it exists
            if springboards[i].ecsEntity then
                springboards[i]:destroy()
            end
            
            table.remove(springboards, i)
        end
    end
end

-- Update the world
function World:update(dt)
    -- Update power-up manager
    if self.powerUpManager then
        self.powerUpManager:update(dt)
    end
    
    -- If using ECS, update any world-specific ECS systems
    if self.entityFactory and self.entityFactory.ecsWorld then
        -- Any world-specific ECS updates can go here
    end
end

return World