-- managers/xpPelletPool.lua
-- Object pool for XP pellets

local ObjectPool = require("lib/objectPool")
local XpPellet = require("entities/xpPellet")
local CollisionManager = require("managers/collisionManager")
local Events = require("lib/events")

local XpPelletPool = {}
XpPelletPool.__index = XpPelletPool

--[[
    Create a new XP pellet pool
    
    @return A new XpPelletPool instance
]]
function XpPelletPool:new()
    local pool = {
        -- Initialize with 50 pellets to start - will grow as needed
        pool = ObjectPool:new(XpPellet, 50),
        
        -- Display debug info (visualize bounds, etc.)
        debugMode = false,
        
        -- Base collection settings
        baseCollectionRadius = 100,
        collectionRadiusBonus = 0,
        attractionStrength = 300
    }
    
    setmetatable(pool, XpPelletPool)
    
    -- Set up event handlers for enemy defeats
    Events.on("enemyKill", function(data) 
        pool:onEnemyKill(data)
    end)
    
    -- Listen for collection radius changes from player upgrades
    Events.on("playerCollectionRadiusChanged", function(data)
        pool.collectionRadiusBonus = data.bonus or 0
    end)
    
    return pool
end

--[[
    Handle enemy kill events to spawn XP pellets
    
    @param data - Event data including enemy and combo information
    @return Array of created XP pellets
]]
function XpPelletPool:onEnemyKill(data)
    local enemy = data.enemy
    local comboCount = data.comboCount or 0
    
    -- Determine XP amount based on enemy type and combo
    local baseXp = 5
    
    -- Bonus XP for combo
    local comboBonus = math.floor(comboCount / 2)
    local totalXp = baseXp + comboBonus
    
    -- Distribute XP across multiple pellets
    local pelletCount = math.min(totalXp, 5) -- Max 5 pellets
    local xpPerPellet = math.ceil(totalXp / pelletCount)
    
    -- Calculate enemy center position
    local enemyCenterX = enemy.x + (enemy.width or 0) / 2
    local enemyCenterY = enemy.y + (enemy.height or 0) / 2
    
    -- Created pellets
    local pellets = {}
    
    -- Create pellets around the enemy
    for i = 1, pelletCount do
        -- Create pellets at the enemy's center with a small random offset
        local offsetX = love.math.random(-10, 10)
        local offsetY = love.math.random(-10, 10)
        
        -- Calculate pellet position
        local pelletX = enemyCenterX + offsetX
        local pelletY = enemyCenterY + offsetY
        
        -- Get pellet from pool and initialize it
        local pellet = self.pool:get(pelletX, pelletY, xpPerPellet)
        
        -- Enable debug mode if set
        pellet.debug = self.debugMode
        
        -- Add to created pellets array
        table.insert(pellets, pellet)
    end
    
    return pellets
end

--[[
    Spawn a specific amount of XP at a location
    
    @param x - X position
    @param y - Y position
    @param amount - XP value (default: 1)
    @return The created XP pellet
]]
function XpPelletPool:spawnXp(x, y, amount)
    -- Get a pellet from the pool
    local pellet = self.pool:get(x, y, amount or 1)
    
    -- Enable debug mode if set
    pellet.debug = self.debugMode
    
    return pellet
end

--[[
    Apply magnetic attraction to pellets near the player
    
    @param dt - Delta time
    @param player - Player entity
]]
function XpPelletPool:applyMagneticAttraction(dt, player)
    if not player then return end
    
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    
    -- Get effective collection radius
    local radius = self.baseCollectionRadius + self.collectionRadiusBonus
    
    -- Check if player has pellet magnet upgrade active
    local magnetActive = player.magnetActive or false
    local magnetRadius = magnetActive and radius * 2 or radius
    
    -- Apply to all active pellets
    for pellet in self.pool:each() do
        -- Only apply magnetic attraction to collectible pellets
        if pellet.collectible and pellet.magnetizable then
            local pelletCenterX = pellet.x + pellet.width / 2
            local pelletCenterY = pellet.y + pellet.height / 2
            
            -- Calculate distance to player
            local dx = playerCenterX - pelletCenterX
            local dy = playerCenterY - pelletCenterY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Pellet attraction logic - always pull them closer if attracted
            if pellet.attracted or distance < magnetRadius then
                pellet.attracted = true
                -- Normalize direction
                local nx = dx / distance
                local ny = dy / distance
                
                -- Calculate attraction strength (stronger when closer)
                local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength
                
                -- Move pellet toward player
                pellet.x = pellet.x + nx * strength * dt
                pellet.y = pellet.y + ny * strength * dt
            end
        end
    end
end

--[[
    Update all active XP pellets
    
    @param dt - Delta time
    @param player - Player entity for magnetic attraction
    @param camera - Camera object for cleanup
]]
function XpPelletPool:update(dt, player, camera)
    -- Update all pellets in the pool
    self.pool:update(dt)
    
    -- Apply magnetic attraction to pellets
    if player then
        self:applyMagneticAttraction(dt, player)
    end
    
    -- Clean up pellets that are off-screen
    if camera then
        self:cleanupPellets(camera)
    end
end

--[[
    Clean up pellets that are far below the screen
    
    @param camera - Camera object
]]
function XpPelletPool:cleanupPellets(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for pellet in self.pool:each() do
        if pellet.y > removalThreshold then
            -- Release the pellet back to the pool
            CollisionManager.removeEntity(pellet)
            self.pool:release(pellet)
        end
    end
end

--[[
    Draw all active XP pellets
]]
function XpPelletPool:draw()
    self.pool:draw()
end

--[[
    Enable/disable debug mode for all pellets
    
    @param enabled - Whether debug mode should be enabled
]]
function XpPelletPool:setDebugMode(enabled)
    self.debugMode = enabled
    self.pool:setDebugMode(enabled)
    
    -- Update existing pellets
    for pellet in self.pool:each() do
        pellet.debug = enabled
    end
end

--[[
    Set collection radius bonus from player upgrades
    
    @param bonus - Amount to add to base collection radius
]]
function XpPelletPool:setCollectionRadiusBonus(bonus)
    self.collectionRadiusBonus = bonus
end

--[[
    Get stats about the pellet pool
    
    @return Table with stats
]]
function XpPelletPool:getStats()
    return {
        active = self.pool:getActiveCount(),
        available = self.pool:getAvailableCount(),
        total = self.pool:getTotalSize()
    }
end

--[[
    Spawn test XP pellets around the player (for debugging)
    
    @param player - Player entity
    @param count - Number of pellets to spawn (default: 5)
]]
function XpPelletPool:spawnTestPellets(player, count)
    count = count or 5
    
    for i = 1, count do
        local offsetX = love.math.random(-100, 100)
        local offsetY = love.math.random(-100, 100)
        
        local pellet = self:spawnXp(
            player.x + player.width/2 + offsetX,
            player.y + player.height/2 + offsetY,
            love.math.random(1, 3)
        )
        
        -- Make them immediately collectible
        pellet.collectible = true
        pellet.magnetizable = true
        
        -- Print debug info
        print(string.format("Created test XP pellet at: %.1f, %.1f", pellet.x, pellet.y))
    end
end

return XpPelletPool