-- xpManager.lua - Manages XP pellets and player progression
local Events = require("lib/events")
local Bridge = require("lib/ecs/bridge")
local EntityFactoryECS = require("entities/entityFactoryECS")

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
    
    -- ECS world reference (will be set later)
    self.ecsWorld = nil
    
    -- Create entity factory if ECS world is available
    if _G.ecsWorld then
        self.entityFactory = EntityFactoryECS.new(_G.ecsWorld)
    end
    
    return self
end

-- Set the ECS world reference
function XpManager:setECSWorld(world)
    self.ecsWorld = world
    self.entityFactory = EntityFactoryECS.new(world)
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
    local enemyX, enemyY
    
    -- Check if the enemy is an ECS entity
    if enemy.ecsEntity then
        -- Get position from transform component
        local transform = enemy.ecsEntity:getComponent("transform")
        if transform and transform.position then
            enemyX = transform.position.x + transform.size.width / 2
            enemyY = transform.position.y + transform.size.height / 2
        else
            -- Fallback to entity properties
            enemyX = enemy.x + enemy.width / 2
            enemyY = enemy.y + enemy.height / 2
        end
    else
        -- Legacy entity
        enemyX = enemy.x + enemy.width / 2
        enemyY = enemy.y + enemy.height / 2
    end
    
    -- Create pellets
    local createdPellets = {}
    
    -- Make sure we have an entity factory
    if not self.entityFactory then
        if self.ecsWorld or _G.ecsWorld then
            local world = self.ecsWorld or _G.ecsWorld
            self.entityFactory = EntityFactoryECS.new(world)
        else
            print("Warning: No ECS world available for XP pellet creation")
            return {}
        end
    end
    
    for i = 1, pelletCount do
        -- Create pellets at the enemy's center with a small random offset
        local offsetX = love.math.random(-10, 10)
        local offsetY = love.math.random(-10, 10)
        
        -- Calculate pellet position
        local pelletX = enemyX + offsetX
        local pelletY = enemyY + offsetY
        
        -- Create pellet using the factory
        local pellet = self.entityFactory:createXpPellet(pelletX, pelletY, xpPerPellet)
        table.insert(self.pellets, pellet)
        table.insert(createdPellets, pellet)
        
        print("Created XP pellet at:", pelletX, pelletY, "with value:", xpPerPellet)
    end
    
    return createdPellets
end

function XpManager:update(dt, player, camera)
    -- Update all XP pellets
    for i = #self.pellets, 1, -1 do
        local pellet = self.pellets[i]
        
        -- Skip if pellet is not active
        if not pellet.active then
            table.remove(self.pellets, i)
            goto continue
        end
        
        -- Update the pellet
        if pellet.update then
            pellet:update(dt)
        end
        
        -- Apply magnetic attraction to player if pellet is collectible
        if player and pellet.magnetizable then
            local isECSPellet = pellet.ecsEntity ~= nil
            local isECSPlayer = player.ecsEntity ~= nil
            
            -- Get player position
            local playerX, playerY
            
            if isECSPlayer then
                local transform = player.ecsEntity:getComponent("transform")
                if transform and transform.position then
                    playerX = transform.position.x + transform.size.width / 2
                    playerY = transform.position.y + transform.size.height / 2
                else
                    playerX = player.x + player.width / 2
                    playerY = player.y + player.height / 2
                end
            else
                playerX = player.x + player.width / 2
                playerY = player.y + player.height / 2
            end
            
            -- Get pellet position
            local pelletX, pelletY
            
            if isECSPellet then
                pelletX = pellet.x + pellet.width / 2
                pelletY = pellet.y + pellet.height / 2
            else
                pelletX = pellet.x + pellet.width / 2
                pelletY = pellet.y + pellet.height / 2
            end
            
            -- Calculate distance to player
            local dx = playerX - pelletX
            local dy = playerY - pelletY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Get effective collection radius
            local radius = self.baseCollectionRadius + self.collectionRadiusBonus
            
            -- Check if player has pellet magnet upgrade active
            local magnetActive = player.hasMagnetUpgrade and player:hasMagnetUpgrade()
            local magnetRadius = magnetActive and radius * 2 or radius
            
            -- Apply attraction if within radius
            if distance < magnetRadius then
                -- If pellet has its own magnetic attraction method, use it
                if pellet.applyMagneticForce then
                    pellet:applyMagneticForce(playerX, playerY, self.attractionStrength)
                else
                    -- Calculate attraction strength (stronger when closer)
                    local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength
                    
                    -- Normalize direction
                    local nx = dx / distance
                    local ny = dy / distance
                    
                    -- Apply force to velocity
                    if isECSPellet then
                        local physics = pellet.ecsEntity:getComponent("physics")
                        if physics and physics.velocity then
                            physics.velocity.x = physics.velocity.x + nx * strength * dt
                            physics.velocity.y = physics.velocity.y + ny * strength * dt
                        end
                    else
                        -- Legacy pellet
                        pellet.velocity.x = pellet.velocity.x + nx * strength * dt
                        pellet.velocity.y = pellet.velocity.y + ny * strength * dt
                    end
                end
            end
        end
        
        ::continue::
    end
    
    -- Clean up pellets that are too far below the camera
    if camera then
        self:cleanupPellets(camera, function(pellet)
            -- Remove from collision manager if needed
            if CollisionManager then
                CollisionManager.removeEntity(pellet)
            end
            
            -- If using ECS, deactivate ECS entity
            if self.ecsWorld and self.entityMap[pellet] then
                local ecsEntity = self.entityMap[pellet]
                ecsEntity:deactivate()
                self.ecsWorld:returnToPool(ecsEntity)
                self.entityMap[pellet] = nil
            end
        end)
    end
    
    -- If using ECS, update the ECS world
    if self.ecsWorld then
        self.ecsWorld:update(dt)
    end
end

-- Apply magnetic attraction to pellets (separated from collection logic)
function XpManager:applyMagneticAttraction(dt, player)
    -- If using ECS, let the ECS system handle it
    if self.ecsWorld then
        return
    end
    
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
                local strength = magnetActive and self.attractionStrength * 1.5 or self.attractionStrength
                
                -- Move pellet toward player
                pellet.x = pellet.x + nx * strength * dt
                pellet.y = pellet.y + ny * strength * dt
            end
        end
    end
end

function XpManager:cleanupPellets(camera, removeCallback)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.pellets, 1, -1 do
        local pellet = self.pellets[i]
        if pellet.y > removalThreshold then
            -- Call the removal callback so CollisionManager can remove it
            if removeCallback then 
                removeCallback(pellet)
            end
            table.remove(self.pellets, i)
        end
    end
end

-- Spawn an XP pellet at the specified position
function XpManager:spawnXp(x, y, value)
    if not self.entityFactory then
        if self.ecsWorld or _G.ecsWorld then
            local world = self.ecsWorld or _G.ecsWorld
            self.entityFactory = EntityFactoryECS.new(world)
        else
            print("Warning: No ECS world available for XP pellet creation")
            return nil
        end
    end
    
    local pellet = self.entityFactory:createXpPellet(x, y, value)
    table.insert(self.pellets, pellet)
    return pellet
end

function XpManager:draw()
    -- If using ECS, let the ECS system handle it
    if self.ecsWorld then
        self.ecsWorld:draw()
    else
        -- Draw all pellets using legacy system
        for _, pellet in ipairs(self.pellets) do
            pellet:draw()
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Set collection radius modifier (for upgrades)
function XpManager:setCollectionRadiusBonus(bonus)
    self.collectionRadiusBonus = bonus
    
    -- Update ECS system if available
    if self.ecsWorld then
        local xpSystem = self.ecsWorld.systemManager:getSystem("XpSystem")
        if xpSystem then
            xpSystem:setCollectionRadiusBonus(bonus)
        end
    end
end

return XpManager