local PowerUp = require("entities/powerUp")
local Events = require("lib/events")

local PowerUpManager = {}
PowerUpManager.__index = PowerUpManager

function PowerUpManager:new()
    local self = setmetatable({}, PowerUpManager)
    
    -- Collection of active power-ups
    self.powerUps = {}
    
    -- Spawn settings
    self.spawnChance = 0.15  -- 15% chance per platform
    self.platformSpawnChance = 0.05 -- 5% chance to add a power-up when generating a platform
    self.randomSpawnTimer = 0
    self.randomSpawnInterval = 5 -- Try to spawn a random power-up every 5 seconds
    
    -- Power-up type weights (higher = more common)
    self.typeWeights = {
        HEALTH = 10,       -- More common when health is low
        DOUBLE_JUMP = 5,   -- Moderately common
        DASH_POWER = 3,    -- Less common
        MAGNET = 2,        -- Rare
        SHIELD = 2         -- Rare
    }
    
    -- Register event handlers
    Events.on("playerHealthChanged", function(data)
        -- Adjust health power-up chance based on player health
        if data.health <= 1 then
            self.typeWeights.HEALTH = 25 -- Much more common when critical
        elseif data.health <= 2 then
            self.typeWeights.HEALTH = 15 -- More common when low
        else
            self.typeWeights.HEALTH = 5  -- Less common when healthy
        end
    end)
    
    return self
end

-- Update all power-ups
function PowerUpManager:update(dt, player, camera)
    -- Update existing power-ups
    for i = #self.powerUps, 1, -1 do
        local powerUp = self.powerUps[i]
        powerUp:update(dt)
        
        -- Remove inactive power-ups
        if not powerUp.active then
            table.remove(self.powerUps, i)
        end
    end
    
    -- Update random spawn timer
    self.randomSpawnTimer = self.randomSpawnTimer - dt
    if self.randomSpawnTimer <= 0 then
        self.randomSpawnTimer = self.randomSpawnInterval
        
        -- Try to spawn a random power-up
        self:tryRandomSpawn(camera)
    end
    
    -- Add magnet effect if player has the magnet power-up
    if player.magnetActive then
        self:updateMagnetEffect(dt, player)
    end
end

-- Draw all power-ups
function PowerUpManager:draw()
    for _, powerUp in ipairs(self.powerUps) do
        powerUp:draw()
    end
end

-- Spawn a power-up at the specified position
function PowerUpManager:spawnPowerUp(x, y, specificType)
    -- Create a new power-up (with specified type or random)
    local powerUp = PowerUp:new(x, y, specificType or self:getRandomPowerUpType())
    table.insert(self.powerUps, powerUp)
    
    -- Fire event for power-up spawned
    Events.fire("powerUpSpawned", {
        x = x,
        y = y,
        type = powerUp.type
    })
    
    return powerUp
end

-- Try to spawn a power-up on a platform
function PowerUpManager:tryPlatformSpawn(platform)
    -- Only spawn if random chance is met
    if love.math.random() > self.platformSpawnChance then
        return nil
    end
    
    -- Calculate position (centered on platform)
    local x = platform.x + platform.width/2 - 15
    local y = platform.y - 40
    
    return self:spawnPowerUp(x, y)
end

-- Try to spawn a random power-up somewhere in the visible area
function PowerUpManager:tryRandomSpawn(camera)
    -- 30% chance to actually spawn
    if love.math.random() > 0.3 then
        return nil
    end
    
    -- Get a random position in the visible area
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = love.math.random(50, screenWidth - 50)
    local y = camera.y + love.math.random(50, screenHeight - 100)
    
    return self:spawnPowerUp(x, y)
end

-- Get a random power-up type based on weights
function PowerUpManager:getRandomPowerUpType()
    -- Calculate total weight
    local totalWeight = 0
    for _, weight in pairs(self.typeWeights) do
        totalWeight = totalWeight + weight
    end
    
    -- Pick a random value based on weights
    local randomValue = love.math.random() * totalWeight
    local cumulativeWeight = 0
    
    -- Find which type was selected
    for type, weight in pairs(self.typeWeights) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue <= cumulativeWeight then
            return type
        end
    end
    
    -- Fallback to HEALTH if something went wrong
    return "HEALTH"
end

-- Handle collisions between player and power-ups
function PowerUpManager:handleCollisions(player)
    for i = #self.powerUps, 1, -1 do
        local powerUp = self.powerUps[i]
        
        -- Skip inactive power-ups
        if not powerUp.active then
            table.remove(self.powerUps, i)
        else
            -- Check for collision with player
            local powerUpBounds = powerUp:getBounds()
            local playerBounds = player:getBounds()
            
            if self:checkCollision(powerUpBounds, playerBounds) then
                -- Apply power-up effect to player
                local message = powerUp:apply(player)
                
                -- Remove power-up
                table.remove(self.powerUps, i)
                
                -- Return collected message
                return message
            end
        end
    end
    
    return nil
end

-- Clean up power-ups that are off-screen
function PowerUpManager:cleanupPowerUps(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.powerUps, 1, -1 do
        if self.powerUps[i].y > removalThreshold then
            table.remove(self.powerUps, i)
        end
    end
end

-- Update magnet effect to attract power-ups to the player
function PowerUpManager:updateMagnetEffect(dt, player)
    local magnetRadius = 150
    local magnetStrength = 200
    
    -- Calculate center of player
    local playerCenterX = player.x + player.width/2
    local playerCenterY = player.y + player.height/2
    
    for _, powerUp in ipairs(self.powerUps) do
        -- Calculate power-up center
        local powerUpCenterX = powerUp.x + powerUp.width/2
        local powerUpCenterY = powerUp.y + powerUp.height/2
        
        -- Calculate distance to player
        local dx = playerCenterX - powerUpCenterX
        local dy = playerCenterY - powerUpCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        
        -- If within magnet radius, move toward player
        if distance < magnetRadius then
            -- Normalize direction vector
            local nx = dx / distance
            local ny = dy / distance
            
            -- Calculate pull strength (stronger when closer)
            local pullFactor = 1 - (distance / magnetRadius)
            local pullStrength = magnetStrength * pullFactor * dt
            
            -- Move power-up toward player
            powerUp.x = powerUp.x + nx * pullStrength
            powerUp.y = powerUp.y + ny * pullStrength
        end
    end
end

-- Simple collision detection
function PowerUpManager:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

return PowerUpManager