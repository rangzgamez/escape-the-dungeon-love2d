-- xpManager.lua - Manages XP pellets and player progression
local Events = require("lib/events")
local XpPellet = require("entities/xpPellet")
local CollisionManager = require("managers/collisionManager")

local XpManager = {}
XpManager.__index = XpManager

function XpManager:new()
    local self = setmetatable({}, XpManager)
    
    -- XP pellets collection
    self.pellets = {}
    
    -- Collection radius properties
    self.baseCollectionRadius = 100 -- Base collection radius
    self.collectionRadiusBonus = 0 -- Bonus from upgrades
    self.attractionStrength = 300  -- How fast pellets are pulled to player
    
    return self
end


function XpManager:onEnemyKill(data)
    -- Create XP drops when enemies are killed
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
        
    -- Create pellets around the enemy
    for i = 1, pelletCount do
        -- Create pellets at the enemy's center with a small random offset
        local offsetX = love.math.random(-10, 10)
        local offsetY = love.math.random(-10, 10)
        
        -- Calculate pellet position (centered on enemy with offset)
        -- No need to subtract half the pellet width/height as the pellet's visual center
        -- will be at its position + half its width/height
        local pelletX = enemyCenterX + offsetX
        local pelletY = enemyCenterY + offsetY
        
        local pellet = XpPellet:new(
            pelletX,
            pelletY,
            xpPerPellet
        )
        
        -- Enable debug mode to see collision bounds
        pellet.debug = true
        
        -- Give each pellet a unique explosion direction
        local angle = love.math.random() * math.pi * 2 -- Random angle in radians
        local speed = love.math.random(100, 200)       -- Random speed
        
        -- Set velocity based on angle and speed
        pellet.velocity.x = math.cos(angle) * speed
        pellet.velocity.y = math.sin(angle) * speed
        
        
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
    
    -- Apply magnetic attraction to pellets
    if player then
        self:applyMagneticAttraction(dt, player)
    end
    
    -- Clean up pellets that are too far below the camera
    self:cleanupPellets(camera)
end

-- Apply magnetic attraction to pellets (separated from collection logic)
function XpManager:applyMagneticAttraction(dt, player)
    local playerCenterX = player.x + player.width / 2
    local playerCenterY = player.y + player.height / 2
    
    -- Get effective collection radius
    local radius = self.baseCollectionRadius + self.collectionRadiusBonus
    
    -- Check if player has pellet magnet upgrade active
    local magnetActive = player.magnetActive or false
    local magnetRadius = magnetActive and radius * 2 or radius
    
    for _, pellet in ipairs(self.pellets) do
        -- Only apply magnetic attraction to collectible pellets
        if pellet.collectible and pellet.magnetizable then
            local pelletCenterX = pellet.x + pellet.width / 2
            local pelletCenterY = pellet.y + pellet.height / 2
            
            -- Calculate distance to player
            local dx = playerCenterX - pelletCenterX
            local dy = playerCenterY - pelletCenterY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Pellet attraction logic - always pull them closer
            if distance < magnetRadius then
                -- Normalize direction
                local nx = dx / distance
                local ny = dy / distance
                
                -- Calculate attraction strength (stronger when closer)
                local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength * 1.5
                
                -- Move pellet toward player
                pellet.x = pellet.x + nx * strength * dt
                pellet.y = pellet.y + ny * strength * dt
            end
        end
    end
end

function XpManager:cleanupPellets(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.pellets, 1, -1 do
        local pellet = self.pellets[i]
        if pellet.y > removalThreshold then
            -- Call the removal callback so CollisionManager can remove it
            CollisionManager.removeEntity(pellet)
            table.remove(self.pellets, i)
        end
    end
end

-- Spawn a specific amount of XP at a location (for testing or special events)
function XpManager:spawnXp(x, y, amount)
    local pellet = XpPellet:new(x, y, amount)
    
    -- Enable debug mode to see collision bounds
    pellet.debug = true
    
    table.insert(self.pellets, pellet)
    return pellet
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
    
    -- Enable debug mode to see collision bounds
    pellet.debug = true
    
    table.insert(self.pellets, pellet)
    return pellet
end

return XpManager