local Events = require("lib/events")

local PowerUp = {}
PowerUp.__index = PowerUp

-- Power-up types and their effects
local POWERUP_TYPES = {
    HEALTH = {
        color = {1, 0.2, 0.2},  -- Red
        effect = function(player) 
            player.health = math.min(player.health + 1, 3)
            return "Health +1"
        end
    },
    DOUBLE_JUMP = {
        color = {0.2, 1, 0.2},  -- Green
        effect = function(player)
            player.maxMidairJumps = player.maxMidairJumps + 1
            player.midairJumps = player.maxMidairJumps
            return "Double Jump +1"
        end
    },
    DASH_POWER = {
        color = {0.2, 0.2, 1},  -- Blue
        effect = function(player)
            player.dashSpeed = player.dashSpeed * 1.2
            return "Dash Power Up!"
        end
    },
    MAGNET = {
        color = {1, 1, 0.2},  -- Yellow
        effect = function(player)
            player.magnetActive = true
            player.magnetTimer = 10.0  -- 10 seconds duration
            return "Coin Magnet Active!"
        end
    },
    SHIELD = {
        color = {0.2, 0.8, 1},  -- Cyan
        effect = function(player)
            player.shieldActive = true
            player.shieldHealth = 1  -- Absorbs one hit
            return "Shield Active!"
        end
    }
}

function PowerUp:new(x, y, type)
    local self = setmetatable({}, PowerUp)
    
    self.x = x
    self.y = y
    self.width = 30
    self.height = 30
    self.type = type or self:randomType()
    self.typeData = POWERUP_TYPES[self.type]
    
    -- Animation properties
    self.animTimer = 0
    self.bobHeight = 10
    self.bobSpeed = 3
    self.rotation = 0
    self.rotationSpeed = 1
    self.scale = 1
    self.pulseDirection = 1
    self.active = true
    
    return self
end

function PowerUp:randomType()
    local types = {}
    for type, _ in pairs(POWERUP_TYPES) do
        table.insert(types, type)
    end
    return types[love.math.random(1, #types)]
end

function PowerUp:update(dt)
    -- Update animation
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

function PowerUp:draw()
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
    if self.type == "HEALTH" then
        -- Health cross
        love.graphics.rectangle("fill", -2, -10, 4, 20)
        love.graphics.rectangle("fill", -10, -2, 20, 4)
    elseif self.type == "DOUBLE_JUMP" then
        -- Up arrows
        love.graphics.polygon("fill", 0, -8, -6, 0, 6, 0)
        love.graphics.polygon("fill", 0, -3, -6, 5, 6, 5)
    elseif self.type == "DASH_POWER" then
        -- Lightning bolt
        love.graphics.polygon("fill", -2, -10, 5, -5, 0, 0, 7, 10, -5, 2, 0, -5)
    elseif self.type == "MAGNET" then
        -- Magnet shape
        love.graphics.rectangle("fill", -7, -7, 14, 4)
        love.graphics.rectangle("fill", -7, -7, 4, 14)
        love.graphics.rectangle("fill", 3, -7, 4, 14)
    elseif self.type == "SHIELD" then
        -- Shield symbol
        love.graphics.polygon("fill", 0, -10, 8, -5, 8, 5, 0, 10, -8, 5, -8, -5)
        love.graphics.setColor(self.typeData.color)
        love.graphics.polygon("fill", 0, -6, 5, -3, 5, 3, 0, 6, -5, 3, -5, -3)
    end
    
    -- Restore transformation
    love.graphics.pop()
end

function PowerUp:apply(player)
    if not self.active then return nil end
    
    -- Apply effect based on type
    local message = self.typeData.effect(player)
    
    -- Fire event
    Events.fire("powerupCollected", {
        type = self.type,
        player = player,
        x = self.x,
        y = self.y,
        message = message
    })
    
    -- Deactivate power-up
    self.active = false
    
    return message
end

function PowerUp:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return PowerUp