-- powerUpECS.lua - Power-up entity for Love2D Vertical Jumper (ECS version)
local ECSEntity = require("entities/ecsEntity")
local Events = require("lib/events")

local PowerUpECS = setmetatable({}, {__index = ECSEntity})
PowerUpECS.__index = PowerUpECS

-- Power-up types and their effects
local POWERUP_TYPES = {
    HEALTH = {
        color = {1, 0.2, 0.2, 1},  -- Red
        effect = function(player) 
            if player.ecsEntity and player.ecsEntity:hasComponent("player") then
                local playerComp = player.ecsEntity:getComponent("player")
                playerComp.health = math.min(playerComp.health + 1, playerComp.maxHealth)
            else
                player.health = math.min(player.health + 1, 3)
            end
            return "Health +1"
        end
    },
    DOUBLE_JUMP = {
        color = {0.2, 1, 0.2, 1},  -- Green
        effect = function(player)
            if player.ecsEntity and player.ecsEntity:hasComponent("movement") then
                local movement = player.ecsEntity:getComponent("movement")
                movement.maxMidairJumps = movement.maxMidairJumps + 1
                movement.midairJumps = movement.maxMidairJumps
            else
                player.maxMidairJumps = player.maxMidairJumps + 1
                player.midairJumps = player.maxMidairJumps
            end
            return "Double Jump +1"
        end
    },
    DASH_POWER = {
        color = {0.2, 0.2, 1, 1},  -- Blue
        effect = function(player)
            if player.ecsEntity and player.ecsEntity:hasComponent("movement") then
                local movement = player.ecsEntity:getComponent("movement")
                movement.dashSpeed = movement.dashSpeed * 1.2
            else
                player.dashSpeed = player.dashSpeed * 1.2
            end
            return "Dash Power Up!"
        end
    },
    MAGNET = {
        color = {1, 1, 0.2, 1},  -- Yellow
        effect = function(player)
            if player.ecsEntity and player.ecsEntity:hasComponent("player") then
                local playerComp = player.ecsEntity:getComponent("player")
                playerComp.magnetActive = true
                playerComp.magnetTimer = 10.0  -- 10 seconds duration
            else
                player.magnetActive = true
                player.magnetTimer = 10.0  -- 10 seconds duration
            end
            return "Coin Magnet Active!"
        end
    },
    SHIELD = {
        color = {0.2, 0.8, 1, 1},  -- Cyan
        effect = function(player)
            if player.ecsEntity and player.ecsEntity:hasComponent("player") then
                local playerComp = player.ecsEntity:getComponent("player")
                playerComp.shieldActive = true
                playerComp.shieldHealth = 1  -- Absorbs one hit
            else
                player.shieldActive = true
                player.shieldHealth = 1  -- Absorbs one hit
            end
            return "Shield Active!"
        end
    }
}

function PowerUpECS:new(x, y, type)
    -- Create with ECSEntity first
    local self = ECSEntity.new(x, y, 30, 30, {
        type = "powerup",
        collisionLayer = "collectible",
        collidesWithLayers = {"player"},
        isSolid = false
    })
    
    -- Now set metatable to PowerUpECS
    setmetatable(self, PowerUpECS)
    
    -- Set power-up type
    self.powerupType = type or self:randomType()
    self.typeData = POWERUP_TYPES[self.powerupType]
    
    -- Animation properties
    self.animTimer = 0
    self.bobHeight = 10
    self.bobSpeed = 3
    self.rotation = 0
    self.rotationSpeed = 1
    self.scale = 1
    self.pulseDirection = 1
    
    -- Add power-up-specific components to ECS entity if available
    if self.ecsEntity then
        -- Add renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "custom",
            layer = 5,
            drawFunction = function(entity)
                -- This will be handled by the draw method
            end
        })
        
        -- Add powerup component
        self.ecsEntity:addComponent("powerup", {
            powerupType = self.powerupType,
            animTimer = self.animTimer,
            bobHeight = self.bobHeight,
            bobSpeed = self.bobSpeed,
            rotation = self.rotation,
            rotationSpeed = self.rotationSpeed,
            scale = self.scale,
            pulseDirection = self.pulseDirection,
            color = self.typeData.color
        })
        
        -- Add physics component with no gravity
        self.ecsEntity:addComponent("physics", {
            velocity = {x = 0, y = 0},
            acceleration = {x = 0, y = 0},
            gravity = 0,
            friction = 0,
            mass = 1,
            affectedByGravity = false
        })
    end
    
    return self
end

function PowerUpECS:randomType()
    local types = {}
    for type, _ in pairs(POWERUP_TYPES) do
        table.insert(types, type)
    end
    return types[love.math.random(1, #types)]
end

function PowerUpECS:update(dt)
    -- If we have an ECS entity, sync with it
    if self.ecsEntity and self.ecsEntity:hasComponent("powerup") then
        local powerup = self.ecsEntity:getComponent("powerup")
        
        -- Update animation properties
        powerup.animTimer = powerup.animTimer + dt
        powerup.rotation = powerup.rotation + powerup.rotationSpeed * dt
        
        -- Pulse scaling effect
        powerup.scale = powerup.scale + 0.2 * powerup.pulseDirection * dt
        if powerup.scale > 1.2 then
            powerup.scale = 1.2
            powerup.pulseDirection = -1
        elseif powerup.scale < 0.8 then
            powerup.scale = 0.8
            powerup.pulseDirection = 1
        end
        
        -- Sync our local properties
        self.animTimer = powerup.animTimer
        self.rotation = powerup.rotation
        self.scale = powerup.scale
        self.pulseDirection = powerup.pulseDirection
    else
        -- Legacy update
        self.animTimer = self.animTimer + dt
        self.rotation = self.rotation + self.rotationSpeed * dt
        
        -- Pulse scaling effect
        self.scale = self.scale + 0.2 * self.pulseDirection * dt
        if self.scale > 1.2 then
            self.scale = 1.2
            self.pulseDirection = -1
        elseif self.scale < 0.8 then
            self.scale = 0.8
            self.pulseDirection = 1
        end
    end
end

function PowerUpECS:draw()
    -- Calculate bobbing position
    local yOffset = math.sin(self.animTimer * self.bobSpeed) * self.bobHeight
    
    -- Save current transformation
    love.graphics.push()
    
    -- Apply transformations
    love.graphics.translate(self.x + self.width/2, self.y + self.height/2 + yOffset)
    love.graphics.rotate(self.rotation)
    love.graphics.scale(self.scale, self.scale)
    
    -- Draw power-up
    love.graphics.setColor(self.typeData.color)
    love.graphics.circle("fill", 0, 0, self.width/2)
    
    -- Draw glow effect
    love.graphics.setColor(self.typeData.color[1], self.typeData.color[2], self.typeData.color[3], 0.5)
    love.graphics.circle("line", 0, 0, self.width/2 + 5)
    
    -- Draw inner symbol (depends on power-up type)
    love.graphics.setColor(1, 1, 1)
    if self.powerupType == "HEALTH" then
        -- Health cross
        love.graphics.rectangle("fill", -2, -10, 4, 20)
        love.graphics.rectangle("fill", -10, -2, 20, 4)
    elseif self.powerupType == "DOUBLE_JUMP" then
        -- Up arrows
        love.graphics.polygon("fill", 0, -8, -6, 0, 6, 0)
        love.graphics.polygon("fill", 0, -3, -6, 5, 6, 5)
    elseif self.powerupType == "DASH_POWER" then
        -- Lightning bolt
        love.graphics.polygon("fill", -2, -10, 5, -5, 0, 0, 7, 10, -5, 2, 0, -5)
    elseif self.powerupType == "MAGNET" then
        -- Magnet shape
        love.graphics.rectangle("fill", -7, -7, 14, 4)
        love.graphics.rectangle("fill", -7, -7, 4, 14)
        love.graphics.rectangle("fill", 3, -7, 4, 14)
    elseif self.powerupType == "SHIELD" then
        -- Shield symbol
        love.graphics.polygon("fill", 0, -10, 8, -5, 8, 5, 0, 10, -8, 5, -8, -5)
        love.graphics.setColor(self.typeData.color)
        love.graphics.polygon("fill", 0, -6, 5, -3, 5, 3, 0, 6, -5, 3, -5, -3)
    end
    
    -- Restore transformation
    love.graphics.pop()
end

function PowerUpECS:onCollision(other, collisionData)
    -- Call parent onCollision method
    ECSEntity.onCollision(self, other, collisionData)
    
    -- Handle collision with player
    if other.type == "player" then
        self:apply(other)
    end
end

function PowerUpECS:apply(player)
    if not self.active then return nil end
    
    -- Apply effect based on type
    local message = self.typeData.effect(player)
    
    -- Fire event
    Events.fire("powerupCollected", {
        type = self.powerupType,
        player = player,
        x = self.x,
        y = self.y,
        message = message
    })
    
    -- Deactivate power-up
    self.active = false
    
    -- Deactivate ECS entity if available
    if self.ecsEntity then
        self.ecsEntity:deactivate()
    end
    
    return message
end

return PowerUpECS 