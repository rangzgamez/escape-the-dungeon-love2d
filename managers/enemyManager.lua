-- enemyManager.lua - Manages enemies for Love2D Vertical Jumper
local Events = require("lib/events")
local Bat = require("entities/bat")
local Slime = require("entities/slime")

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager:new()
    local self = setmetatable({}, EnemyManager)
    
    self.enemies = {}
    self.bats = {}
    self.slimes = {}

    -- Enemy generation parameters
    self.minEnemyY = 0
    self.lastEnemyY = love.graphics.getHeight()
    self.enemySpawnInterval = 200 -- Vertical distance between enemy spawns
    self.batChance = 0.8 -- 80% chance to spawn a bat
    self.screenWidth = love.graphics.getWidth()
    self.generationDistance = 1000 -- Generate enemies this far ahead of camera

    return self
end

function EnemyManager:generateInitialEnemies()
    -- Start with a few enemies
    for i = 1, 5 do
        self:generateEnemy()
    end
end

function EnemyManager:generateEnemy()
    -- Generate enemy at a position above the last one
    local enemyY = self.lastEnemyY - self.enemySpawnInterval + love.math.random(-50, 50)
    local enemyX = love.math.random(50, self.screenWidth - 50)
    
    -- Create a bat
    if love.math.random() < self.batChance then
        local bat = Bat:new(enemyX, enemyY)
        table.insert(self.bats, bat)
        table.insert(self.enemies, bat)
    end

    if love.math.random() < 0.3 then  -- 30% chance for slime
        local slime = Slime:new(enemyX, enemyY)
        table.insert(self.slimes, slime)
        table.insert(self.enemies, slime)
    end
    
    -- Update the highest enemy position
    self.lastEnemyY = enemyY
    self.minEnemyY = math.min(self.minEnemyY, enemyY)
end

function EnemyManager:update(dt, player, camera)
    -- Generate new enemies if needed
    while self.minEnemyY > camera.y - self.generationDistance do
        self:generateEnemy()
    end
    
    -- Update all enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, player)
    end
    
    -- Cleanup enemies that are too far below the camera
    self:cleanupEnemies(camera)
end

function EnemyManager:cleanupEnemies(camera)
    local removalThreshold = camera.y + love.graphics.getHeight() * 1.5
    
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        if enemy.y > removalThreshold then
            -- Find and remove from specific enemy type table
            if enemy.radius then -- It's a bat
                for j = #self.bats, 1, -1 do
                    if self.bats[j] == enemy then
                        table.remove(self.bats, j)
                        break
                    end
                end
            end
            
            -- Remove from main enemies table
            table.remove(self.enemies, i)
        end
    end
end

function EnemyManager:handleCollisions(player, particleManager)
    local enemyHit = false
    
    for _, enemy in ipairs(self.enemies) do
        if self:checkCollision(player, enemy) then
            -- Fire an event for the collision instead of calling a method
            local eventData = {
                enemy = enemy,
                playerState = player.stateMachine:getCurrentStateName(),
                comboCount = player.comboCount,
                result = { enemyHit = false, playerHit = false }
            }
            
            -- Fire the event and let listeners handle it
            Events.fire("enemyCollision", eventData)
            
            -- Check the result from the event handlers
            if eventData.result.enemyHit then
                enemyHit = true
            end
        end
    end
    
    return enemyHit
end

function EnemyManager:checkCollision(a, b)
    local aBounds = a.getBounds and a:getBounds() or a
    local bBounds = b.getBounds and b:getBounds() or b
    
    return aBounds.x < bBounds.x + bBounds.width and
           aBounds.x + aBounds.width > bBounds.x and
           aBounds.y < bBounds.y + bBounds.height and
           aBounds.y + aBounds.height > bBounds.y
end

function EnemyManager:draw()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
    
    -- Debug: Draw detection radius for bats
    if false then -- Set to true to enable debug visualization
        love.graphics.setColor(1, 0, 0, 0.2)
        for _, bat in ipairs(self.bats) do
            love.graphics.circle("line", bat.x + bat.radius, bat.y + bat.radius, bat.detectionRadius)
        end
    end
end

return EnemyManager