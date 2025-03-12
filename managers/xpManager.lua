-- xpManager.lua - Manages XP pellets and player progression
local Events = require("lib/events")
local XpPellet = require("entities/xpPellet")

local XpManager = {}
XpManager.__index = XpManager

function XpManager:new()
    local self = setmetatable({}, XpManager)
    
    -- XP pellets collection
    self.pellets = {}
    
    -- Collection radius properties
    self.baseCollectionRadius = 50 -- Base collection radius
    self.collectionRadiusBonus = 0 -- Bonus from upgrades
    self.attractionStrength = 200  -- How fast pellets are pulled to player
    
    return self
end

function XpManager:onEnemyKill(data)
    -- Create XP drops when enemies are killed
    local enemy = data.enemy
    local comboCount = data.comboCount or 0
    
    -- Determine XP amount based on enemy type and combo
    local baseXp = 1
    if enemy.radius then -- It's a bat
        baseXp = 2
    else -- It's a slime or other enemy
        baseXp = 3
    end
    
    -- Bonus XP for combo
    local comboBonus = math.floor(comboCount / 2)
    local totalXp = baseXp + comboBonus
    
    -- Distribute XP across multiple pellets
    local pelletCount = math.min(totalXp, 5) -- Max 5 pellets
    local xpPerPellet = math.ceil(totalXp / pelletCount)
    
    -- Create pellets around the enemy
    for i = 1, pelletCount do
        local offsetX = love.math.random(-20, 20)
        local offsetY = love.math.random(-20, 20)
        
        local pellet = XpPellet:new(
            enemy.x + enemy.width/2 - 5 + offsetX, 
            enemy.y + enemy.height/2 - 5 + offsetY,
            xpPerPellet
        )
        
        table.insert(self.pellets, pellet)
    end
end

function XpManager:update(dt, player, camera)
    -- Update all pellets
    for i = #self.pellets, 1, -1 do
        local pellet = self.pellets[i]
        pellet:update(dt)
        
        -- Remove inactive pellets
        if not pellet.active then
            table.remove(self.pellets, i)
        end
    end
    
    -- Clean up pellets that are too far below the camera
    if camera then
        self:cleanupPellets(camera)
    end
end

function XpManager:updatePelletCollection(dt, player)
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    local totalXp = 0
    
    -- Get effective collection radius
    local radius = self.baseCollectionRadius + self.collectionRadiusBonus
    
    -- Check if player has pellet magnet upgrade active
    local magnetActive = player.magnetActive or false
    local magnetRadius = magnetActive and radius * 2 or radius
    for i = #self.pellets, 1, -1 do
        local pellet = self.pellets[i]
        -- Make pellets collectible immediately for now (for testing)
        pellet.collectible = true
        local pelletCenterX = pellet.x + pellet.width / 2
        local pelletCenterY = pellet.y + pellet.height / 2
        
        -- Calculate distance to player
        local dx = playerCenterX - pelletCenterX
        local dy = playerCenterY - pelletCenterY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Debug print for a few frames
        if i == 1 and love.timer.getTime() % 1 < 0.1 then
            print("Distance to pellet: " .. distance .. ", Collection radius: " .. radius)
            print("Player pos: " .. playerCenterX .. ", " .. playerCenterY)
            print("Pellet pos: " .. pelletCenterX .. ", " .. pelletCenterY)
        end
        
        -- Pellet attraction logic - always pull them closer
        if distance < magnetRadius then
            -- Normalize direction
            local nx = dx / distance
            local ny = dy / distance
            
            -- Calculate attraction strength (stronger when closer)
            local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength
            
            -- Move pellet toward player
            pellet.x = pellet.x + nx * strength * dt
            pellet.y = pellet.y + ny * strength * dt
        end
        
        -- Simplified collection - if close enough, collect it
        if distance < radius * 0.75 then
            local xpValue = pellet:collect()
            totalXp = totalXp + xpValue
            table.remove(self.pellets, i)
        end
    end
    
    -- Return total XP collected this frame
    return totalXp
end

function XpManager:cleanupPellets(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.pellets, 1, -1 do
        if self.pellets[i].y > removalThreshold then
            table.remove(self.pellets, i)
        end
    end
end

function XpManager:draw()
    -- Draw all pellets
    for _, pellet in ipairs(self.pellets) do
        pellet:draw()
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Set collection radius modifier (for upgrades)
function XpManager:setCollectionRadiusBonus(bonus)
    self.collectionRadiusBonus = bonus
end

-- Spawn a specific amount of XP at a location (for testing or special events)
function XpManager:spawnXp(x, y, amount)
    local pellet = XpPellet:new(x, y, amount)
    table.insert(self.pellets, pellet)
    return pellet
end

return XpManager