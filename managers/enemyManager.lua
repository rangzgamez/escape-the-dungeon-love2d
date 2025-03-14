-- enemyManager.lua - Manages enemies for Love2D Vertical Jumper
local Events = require("lib/events")
local EntityFactoryECS = require("entities/entityFactoryECS")

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager:new()
    local self = setmetatable({}, EnemyManager)
    
    self.enemies = {} -- Single array for all enemy types
    
    -- Enemy generation parameters
    self.minEnemyY = 0
    self.lastEnemyY = love.graphics.getHeight()
    self.enemySpawnInterval = 200
    self.batChance = 0.7
    self.slimeChance = 0.4 -- 40% chance to spawn a slime
    self.screenWidth = love.graphics.getWidth()
    self.generationDistance = 1000
    -- Store platforms reference (will be set in update)
    self.platforms = nil
    
    -- Create entity factory if ECS world is available
    if _G.ecsWorld then
        self.entityFactory = EntityFactoryECS.new(_G.ecsWorld)
    end

    return self
end

function EnemyManager:generateInitialEnemies(platforms)
    -- Store platforms reference
    self.platforms = platforms
    
    -- Start with a few enemies
    for i = 1, 5 do
        self:generateEnemy()
    end
end

function EnemyManager:generateEnemy()
    -- Generate enemy position
    local enemyY = self.lastEnemyY - self.enemySpawnInterval + love.math.random(-50, 50)
    local enemyX = love.math.random(50, self.screenWidth - 50)
    
    -- Create an enemy based on random chance
    local enemy = nil
    
    if self.entityFactory then
        -- Use ECS entities
        if love.math.random() < self.batChance then
            enemy = self.entityFactory:createBat(enemyX, enemyY)
        elseif self.platforms and #self.platforms > 0 and love.math.random() < self.slimeChance then
            -- Find a suitable platform for the slime
            local platformIndex = self:findPlatformNearY(enemyY)
            
            if platformIndex then
                local platform = self.platforms[platformIndex]
                
                -- Place slime on the platform
                local slimeX = platform.x + love.math.random(10, platform.width - 40) -- Keep away from edges
                local slimeY = platform.y - 20 -- Height of slime
                
                -- Create slime using ECS
                enemy = self.entityFactory:createEnemy(slimeX, slimeY, "basic")
            end
        end
    else
        -- Fallback to old system
        local Bat = require("entities/bat")
        local Slime = require("entities/slime")
        
        if love.math.random() < self.batChance then
            enemy = Bat:new(enemyX, enemyY)
        elseif self.platforms and #self.platforms > 0 and love.math.random() < self.slimeChance then
            -- Find a suitable platform for the slime
            local platformIndex = self:findPlatformNearY(enemyY)
            
            if platformIndex then
                local platform = self.platforms[platformIndex]
                
                -- Place slime on the platform
                local slimeX = platform.x + love.math.random(10, platform.width - 40) -- Keep away from edges
                local slimeY = platform.y - 20 -- Height of slime
                
                enemy = Slime:new(slimeX, slimeY, platform)
            end
        end
    end
    
    -- Only insert if we created an enemy
    if enemy then
        table.insert(self.enemies, enemy)
    end
    
    -- Update positions
    self.lastEnemyY = enemyY
    self.minEnemyY = math.min(self.minEnemyY, enemyY)
    return enemy
end

-- Find a platform close to a specific Y coordinate
function EnemyManager:findPlatformNearY(targetY)
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

function EnemyManager:update(dt, player, camera)
    -- We rely on platforms being set during initialization
    -- This is a safety check
    if not self.platforms or #self.platforms == 0 then
        -- Try to get platforms reference from main
        if _G.platforms then
            self.platforms = _G.platforms
        end
    end
    local enemy = nil;
    
    -- Generate new enemies if camera is provided
    if camera then
        -- Generate new enemies if needed
        while self.minEnemyY > camera.y - self.generationDistance do
            enemy = self:generateEnemy()
        end
    end
    
    -- Update all enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, player)
    end
    
    return enemy
end

function EnemyManager:cleanupEnemies(camera, removeCallback)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        if enemy.y > removalThreshold then
            -- Call the removal callback if provided
            if removeCallback then
                removeCallback(enemy)
            end
            
            -- Deactivate ECS entity if it exists
            if enemy.ecsEntity then
                enemy:destroy()
            end
            
            -- Remove from the main enemies table
            table.remove(self.enemies, i)
        end
    end
end

-- function EnemyManager:handleCollisions(player, particleManager)
--     local enemyHit = false
    
--     for _, enemy in ipairs(self.enemies) do
--         if enemy.state == 'stunned' then
--             goto continue
--         end
--         if self:checkCollision(player, enemy)then
--             -- Fire an event for the collision instead of calling a method
--             local eventData = {
--                 enemy = enemy,
--                 comboCount = player.comboCount,
--             }
            
--             -- Fire the event and let listeners handle it
--             Events.fire("enemyCollision", eventData)
            
--         end
--         ::continue::
--     end
    
--     return enemyHit
-- end

-- function EnemyManager:checkCollision(a, b)
--     local aBounds = a.getBounds and a:getBounds() or a
--     local bBounds = b.getBounds and b:getBounds() or b
    
--     return aBounds.x < bBounds.x + bBounds.width and
--            aBounds.x + aBounds.width > bBounds.x and
--            aBounds.y < bBounds.y + bBounds.height and
--            aBounds.y + aBounds.height > bBounds.y
-- end

function EnemyManager:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    -- Debug: Draw detection radius for enemies
    if false then -- Set to true to enable debug visualization
        love.graphics.setColor(1, 0, 0, 0.2)
        for _, enemy in ipairs(self.enemies) do
            if enemy.detectionRadius then
                love.graphics.circle("line", enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.detectionRadius)
            end
        end
    end
end

-- Reset the enemy manager
function EnemyManager:reset()
    -- Clear all enemies
    self.enemies = {}
    
    -- Reset enemy generation parameters
    self.minEnemyY = 0
    self.lastEnemyY = love.graphics.getHeight()
    
    print("Enemy manager reset")
end

return EnemyManager