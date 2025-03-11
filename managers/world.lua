-- world.lua - World generation for Love2D Vertical Jumper

local World = {}
World.__index = World

local Platform = require("entities/platform")
local Springboard = require("entities/springboard")
local PowerUpManager = require("managers/powerUpManager")
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
    return self
end

function World:generateInitialPlatforms(platforms, springboards)
    -- Add the starting platform (wider for easier start)
    local startX = love.graphics.getWidth() / 2 - love.graphics.getWidth() * 0.25
    local startY = love.graphics.getHeight() - 50
    table.insert(platforms, Platform:new(startX, startY, love.graphics.getWidth() * 0.5, self.platformHeight))
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
    local platform = Platform:new(platformX, platformY, platformWidth, self.platformHeight)
    table.insert(platforms, platform)
    self.highestPlatformY = platformY
    self.powerUpManager:tryPlatformSpawn(platform)

    -- Randomly add a springboard to the platform
    if love.math.random() < self.springboardChance then
        local springX = platformX + platformWidth/2 - 25  -- Center on platform
        table.insert(springboards, Springboard:new(springX, platformY - 20, 50, 20))
    end
end

function World:updatePlatforms(camera, platforms, springboards)
    -- Generate new platforms if needed
    while self.highestPlatformY > camera.y - self.generationDistance do
        self:generateNextPlatform(platforms, springboards)
    end
end

function World:cleanupPlatforms(camera, platforms, springboards)
    -- Remove platforms and springboards that are too far below the camera
    local removalThreshold = camera.y + love.graphics.getHeight()
    
    -- Remove old platforms
    for i = #platforms, 1, -1 do
        if platforms[i].y > removalThreshold then
            table.remove(platforms, i)
        end
    end
    
    -- Remove old springboards
    for i = #springboards, 1, -1 do
        if springboards[i].y > removalThreshold then
            table.remove(springboards, i)
        end
    end
end

return World