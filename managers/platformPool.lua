-- managers/platformPool.lua
-- Object pool for platforms and springboards

local ObjectPool = require("lib/objectPool")
local Platform = require("entities/platform")
local Springboard = require("entities/springboard")
local CollisionManager = require("managers/collisionManager")

local PlatformPool = {}
PlatformPool.__index = PlatformPool

--[[
    Create a new platform pool
    
    @return A new PlatformPool instance
]]
function PlatformPool:new()
    local pool = {
        -- Create pools for platforms and springboards
        platformPool = ObjectPool:new(Platform, 50),
        springboardPool = ObjectPool:new(Springboard, 20),
        
        -- Track active objects
        activePlatforms = {},
        activeSpringboards = {},
        
        -- Platform generation parameters
        highestPlatformY = 0,
        minHorizontalGap = 20,
        maxHorizontalGap = 0, -- Will be initialized based on screen width
        minVerticalGap = 80,
        maxVerticalGap = 150,
        minPlatformWidth = 60,
        maxPlatformWidth = 0, -- Will be initialized based on screen width
        platformHeight = 20,
        springboardChance = 0.3,
        
        -- Debug mode
        debugMode = false
    }
    
    setmetatable(pool, PlatformPool)
    
    -- Initialize based on screen size
    pool:updateScreenSize(love.graphics.getWidth(), love.graphics.getHeight())
    
    return pool
end

--[[
    Update parameters based on screen size
    
    @param width - Screen width
    @param height - Screen height
]]
function PlatformPool:updateScreenSize(width, height)
    self.screenWidth = width
    self.maxHorizontalGap = width * 0.4
    self.maxPlatformWidth = width * 0.5
end

--[[
    Initialize the platforms with a starting set
    
    @param startY - Starting Y position (default: screen height - 50)
]]
function PlatformPool:initialize(startY)
    -- Clear any existing platforms
    self:clearAll()
    
    -- Set starting position
    startY = startY or (love.graphics.getHeight() - 50)
    self.highestPlatformY = startY
    
    -- Create a wider starting platform
    local startWidth = self.screenWidth * 0.5
    local startX = self.screenWidth / 2 - startWidth / 2
    self:createPlatform(startX, startY, startWidth, self.platformHeight)
    
    -- Generate initial platforms
    for i = 1, 15 do
        self:generateNextPlatform()
    end
    
    return self
end

--[[
    Create a platform from the pool
    
    @param x - X position
    @param y - Y position
    @param width - Platform width
    @param height - Platform height
    @return The created platform
]]
function PlatformPool:createPlatform(x, y, width, height)
    -- Get platform from pool
    local platform = self.platformPool:get(x, y, width, height)
    
    -- Register with collision system if needed
    if not CollisionManager.isRegistered(platform) then
        CollisionManager.addEntity(platform)
    end
    
    -- Add to active platforms
    table.insert(self.activePlatforms, platform)
    
    return platform
end

--[[
    Create a springboard from the pool
    
    @param x - X position
    @param y - Y position
    @param width - Springboard width
    @param height - Springboard height
    @return The created springboard
]]
function PlatformPool:createSpringboard(x, y, width, height)
    -- Get springboard from pool
    local springboard = self.springboardPool:get(x, y, width, height)
    
    -- Register with collision system if needed
    if not CollisionManager.isRegistered(springboard) then
        CollisionManager.addEntity(springboard)
    end
    
    -- Add to active springboards
    table.insert(self.activeSpringboards, springboard)
    
    return springboard
end

--[[
    Generate a new platform with possible springboard
    
    @return The new platform and springboard (if created)
]]
function PlatformPool:generateNextPlatform()
    -- Generate random vertical gap
    local verticalGap = love.math.random(self.minVerticalGap, self.maxVerticalGap)
    local platformY = self.highestPlatformY - verticalGap
    
    -- Generate random platform width
    local platformWidth = love.math.random(self.minPlatformWidth, self.maxPlatformWidth)
    
    -- Generate random X position within screen bounds
    local platformX = love.math.random(0, self.screenWidth - platformWidth)
    
    -- Create platform
    local platform = self:createPlatform(platformX, platformY, platformWidth, self.platformHeight)
    
    -- Update highest platform position
    self.highestPlatformY = platformY
    
    -- Possibly add a springboard
    local springboard = nil
    if love.math.random() < self.springboardChance then
        local springX = platformX + platformWidth/2 - 25  -- Center on platform
        springboard = self:createSpringboard(springX, platformY - 20, 50, 20)
    end
    
    -- Debug message
    if self.debugMode then
        print(string.format("Generated platform at %.1f, %.1f (width: %.1f, height: %.1f)",
            platformX, platformY, platformWidth, self.platformHeight))
        
        if springboard then
            print(string.format("Added springboard at %.1f, %.1f",
                springboard.x, springboard.y))
        end
    end
    
    return platform, springboard
end

--[[
    Update platforms based on camera position
    
    @param camera - Camera object
    @param generationDistance - How far ahead to generate platforms
    @return Arrays of newly created platforms and springboards
]]
function PlatformPool:update(dt, camera, generationDistance)
    local newPlatforms = {}
    local newSpringboards = {}
    
    -- Default generation distance
    generationDistance = generationDistance or 1000
    
    -- Generate new platforms if needed
    while camera and (self.highestPlatformY > camera.y - generationDistance) do
        local platform, springboard = self:generateNextPlatform()
        
        if platform then
            table.insert(newPlatforms, platform)
        end
        
        if springboard then
            table.insert(newSpringboards, springboard)
        end
    end
    
    -- Cleanup platforms that are too far below
    if camera then
        self:cleanupPlatforms(camera)
    end
    
    -- Update all platforms
    for _, platform in ipairs(self.activePlatforms) do
        if platform.update then
            platform:update(dt)
        end
    end
    
    -- Update all springboards
    for _, springboard in ipairs(self.activeSpringboards) do
        if springboard.update then
            springboard:update(dt)
        end
    end
    
    return newPlatforms, newSpringboards
end

--[[
    Clean up platforms that are far below the screen
    
    @param camera - Camera object
]]
function PlatformPool:cleanupPlatforms(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    -- Clean up platforms
    for i = #self.activePlatforms, 1, -1 do
        local platform = self.activePlatforms[i]
        
        if platform.y > removalThreshold then
            -- Debug message
            if self.debugMode then
                print(string.format("Cleaning up platform at %.1f, %.1f (below threshold %.1f)",
                    platform.x, platform.y, removalThreshold))
            end
            
            -- Remove from active list
            table.remove(self.activePlatforms, i)
            
            -- Remove from collision system
            CollisionManager.removeEntity(platform)
            
            -- Return to pool
            self.platformPool:release(platform)
        end
    end
    
    -- Clean up springboards
    for i = #self.activeSpringboards, 1, -1 do
        local springboard = self.activeSpringboards[i]
        
        if springboard.y > removalThreshold then
            -- Debug message
            if self.debugMode then
                print(string.format("Cleaning up springboard at %.1f, %.1f (below threshold %.1f)",
                    springboard.x, springboard.y, removalThreshold))
            end
            
            -- Remove from active list
            table.remove(self.activeSpringboards, i)
            
            -- Remove from collision system
            CollisionManager.removeEntity(springboard)
            
            -- Return to pool
            self.springboardPool:release(springboard)
        end
    end
end

--[[
    Draw all active platforms and springboards
]]
function PlatformPool:draw()
    -- Draw platforms
    for _, platform in ipairs(self.activePlatforms) do
        platform:draw()
    end
    
    -- Draw springboards
    for _, springboard in ipairs(self.activeSpringboards) do
        springboard:draw()
    end
end

--[[
    Clear all active platforms and springboards
]]
function PlatformPool:clearAll()
    -- Release all platforms
    for i = #self.activePlatforms, 1, -1 do
        local platform = self.activePlatforms[i]
        CollisionManager.removeEntity(platform)
        self.platformPool:release(platform)
    end
    self.activePlatforms = {}
    
    -- Release all springboards
    for i = #self.activeSpringboards, 1, -1 do
        local springboard = self.activeSpringboards[i]
        CollisionManager.removeEntity(springboard)
        self.springboardPool:release(springboard)
    end
    self.activeSpringboards = {}
end

--[[
    Enable/disable debug mode
    
    @param enabled - Whether debug mode should be enabled
]]
function PlatformPool:setDebugMode(enabled)
    self.debugMode = enabled
    self.platformPool:setDebugMode(enabled)
    self.springboardPool:setDebugMode(enabled)
end

--[[
    Get stats about the platform pools
    
    @return Table with stats
]]
function PlatformPool:getStats()
    return {
        activePlatforms = #self.activePlatforms,
        activeSpringboards = #self.activeSpringboards,
        platformPool = {
            active = self.platformPool:getActiveCount(),
            available = self.platformPool:getAvailableCount(),
            total = self.platformPool:getTotalSize()
        },
        springboardPool = {
            active = self.springboardPool:getActiveCount(),
            available = self.springboardPool:getAvailableCount(),
            total = self.springboardPool:getTotalSize()
        }
    }
end

--[[
    Get all active platforms
    
    @return Array of active platforms
]]
function PlatformPool:getPlatforms()
    return self.activePlatforms
end

--[[
    Get all active springboards
    
    @return Array of active springboards
]]
function PlatformPool:getSpringboards()
    return self.activeSpringboards
end

return PlatformPool