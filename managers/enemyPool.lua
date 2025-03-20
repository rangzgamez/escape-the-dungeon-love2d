-- managers/enemyPool.lua
-- Object pool for enemies

local ObjectPool = require("lib/objectPool")
local Bat = require("entities/bat")
local Slime = require("entities/slime")
local CollisionManager = require("managers/collisionManager")

local EnemyPool = {}
EnemyPool.__index = EnemyPool

--[[
    Create a new enemy pool
    
    @return A new EnemyPool instance
]]
function EnemyPool:new()
    local pool = {
        -- Create separate pools for each enemy type
        batPool = ObjectPool:new(Bat, 20),
        slimePool = ObjectPool:new(Slime, 10),
        
        -- Enemy spawn settings
        minEnemyY = 0,
        lastEnemyY = 0,
        enemySpawnInterval = 200,
        batChance = 0.7,
        slimeChance = 0.4,
        
        -- Tracking
        activeEnemies = {},
        screenWidth = love.graphics.getWidth(),
        generationDistance = 1000,
        
        -- Display debug info
        debugMode = false
    }
    
    setmetatable(pool, EnemyPool)
    
    return pool
end

--[[
    Initialize enemy spawning with initial enemies
    
    @param startY - Starting Y position for enemies
    @param platforms - Array of platforms (for slimes)
]]
function EnemyPool:initialize(startY, platforms)
    self.lastEnemyY = startY or love.graphics.getHeight()
    self.platforms = platforms
    
    -- Generate a few initial enemies
    for i = 1, 5 do
        self:generateEnemy()
    end
end

--[[
    Generate a new enemy
    
    @return The created enemy
]]
function EnemyPool:generateEnemy()
    -- Generate enemy position
    local enemyY = self.lastEnemyY - self.enemySpawnInterval + love.math.random(-50, 50)
    local enemyX = love.math.random(50, self.screenWidth - 50)
    
    -- Create an enemy based on random chance
    local enemy = nil
    
    if love.math.random() < self.batChance then
        -- Create a bat
        enemy = self.batPool:get(enemyX, enemyY)
        
        -- Debug message
        if self.debugMode then
            print(string.format("Created bat at %.1f, %.1f", enemyX, enemyY))
        end
        
    elseif self.platforms and #self.platforms > 0 and love.math.random() < self.slimeChance then
        -- Find a suitable platform for the slime
        local platformIndex = self:findPlatformNearY(enemyY)
        
        if platformIndex then
            local platform = self.platforms[platformIndex]
            
            -- Place slime on the platform
            local slimeX = platform.x + love.math.random(10, platform.width - 40) -- Keep away from edges
            
            -- Get a slime from the pool
            enemy = self.slimePool:get(slimeX, 0, platform)
            
            -- Debug message
            if self.debugMode then
                print(string.format("Created slime at %.1f on platform at %.1f", slimeX, platform.y))
            end
        end
    end
    
    -- Add successful enemy to active list
    if enemy then
        table.insert(self.activeEnemies, enemy)
        
        -- Register with collision system
        if not CollisionManager.isRegistered(enemy) then
            CollisionManager.addEntity(enemy)
        end
    end
    
    -- Update positions
    self.lastEnemyY = enemyY
    self.minEnemyY = math.min(self.minEnemyY, enemyY)
    
    return enemy
end

--[[
    Find a platform close to a specific Y coordinate
    
    @param targetY - Target Y position
    @return Index of suitable platform or nil
]]
function EnemyPool:findPlatformNearY(targetY)
    if not self.platforms or #self.platforms == 0 then
        return nil
    end
    
    -- Look for platforms within a certain range of the target Y
    local yRange = 100 -- How far to search
    local candidates = {}
    
    for i, platform in ipairs(self.platforms) do
        if math.abs(platform.y - targetY) < yRange and platform.width >= 60 then
            -- Only use platforms wide enough for slimes
            table.insert(candidates, i)
        end
    end
    
    if #candidates > 0 then
        -- Return a random platform from suitable candidates
        return candidates[love.math.random(1, #candidates)]
    end
    
    -- If no platforms in range, find the closest one
    local closestDist = math.huge
    local closestIndex = nil
    
    for i, platform in ipairs(self.platforms) do
        if platform.width >= 60 then
            local dist = math.abs(platform.y - targetY)
            if dist < closestDist then
                closestDist = dist
                closestIndex = i
            end
        end
    end
    
    return closestIndex
end

--[[
    Update all active enemies
    
    @param dt - Delta time
    @param player - Player entity for enemy targeting
    @param camera - Camera object for generation and cleanup
    @return Newly created enemy (if any)
]]
function EnemyPool:update(dt, player, camera)
    local newEnemy = nil
    
    -- Generate new enemies if needed
    while camera and self.minEnemyY > camera.y - self.generationDistance do
        newEnemy = self:generateEnemy()
    end
    
    -- Update active enemies in reverse order to handle removals
    for i = #self.activeEnemies, 1, -1 do
        local enemy = self.activeEnemies[i]
        
        -- Skip if enemy is no longer active
        if not enemy.active then
            -- Remove from active list
            table.remove(self.activeEnemies, i)
            
            -- Remove from collision system
            CollisionManager.removeEntity(enemy)
            
            -- Return to appropriate pool
            if enemy.type == "bat" then
                self.batPool:release(enemy)
            elseif enemy.type == "slime" then
                self.slimePool:release(enemy)
            end
        else
            -- Update enemy
            enemy:update(dt, player)
        end
    end
    
    -- Clean up off-screen enemies
    if camera then
        self:cleanupEnemies(camera)
    end
    
    return newEnemy
end

--[[
    Clean up enemies that are far below the screen
    
    @param camera - Camera object
]]
function EnemyPool:cleanupEnemies(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.activeEnemies, 1, -1 do
        local enemy = self.activeEnemies[i]
        
        if enemy.y > removalThreshold then
            -- Debug message
            if self.debugMode then
                print(string.format("Cleaning up %s at %.1f, %.1f (below threshold %.1f)",
                    enemy.type, enemy.x, enemy.y, removalThreshold))
            end
            
            -- Remove from active list
            table.remove(self.activeEnemies, i)
            
            -- Remove from collision system
            CollisionManager.removeEntity(enemy)
            
            -- Return to appropriate pool
            if enemy.type == "bat" then
                self.batPool:release(enemy)
            elseif enemy.type == "slime" then
                self.slimePool:release(enemy)
            end
        end
    end
end

--[[
    Draw all active enemies
]]
function EnemyPool:draw()
    for _, enemy in ipairs(self.activeEnemies) do
        enemy:draw()
    end
    
    -- Draw debug visualization if enabled
    if self.debugMode then
        -- Draw detection radius for enemies
        love.graphics.setColor(1, 0, 0, 0.2)
        
        for _, enemy in ipairs(self.activeEnemies) do
            if enemy.detectionRadius then
                love.graphics.circle(
                    "line",
                    enemy.x + (enemy.width or enemy.radius or 0) / 2,
                    enemy.y + (enemy.height or enemy.radius or 0) / 2,
                    enemy.detectionRadius
                )
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
end

--[[
    Enable/disable debug mode
    
    @param enabled - Whether debug mode should be enabled
]]
function EnemyPool:setDebugMode(enabled)
    self.debugMode = enabled
    self.batPool:setDebugMode(enabled)
    self.slimePool:setDebugMode(enabled)
end

--[[
    Update platform references (for slime enemies)
    
    @param platforms - Array of platforms
]]
function EnemyPool:updatePlatforms(platforms)
    self.platforms = platforms
end

--[[
    Get stats about the enemy pools
    
    @return Table with stats
]]
function EnemyPool:getStats()
    return {
        active = #self.activeEnemies,
        batPool = {
            active = self.batPool:getActiveCount(),
            available = self.batPool:getAvailableCount(),
            total = self.batPool:getTotalSize()
        },
        slimePool = {
            active = self.slimePool:getActiveCount(),
            available = self.slimePool:getAvailableCount(),
            total = self.slimePool:getTotalSize()
        }
    }
end

return EnemyPool