-- entities/movingPlatform.lua
local Platform = require("entities/platform")

local MovingPlatform = setmetatable({}, {__index = Platform})
MovingPlatform.__index = MovingPlatform

function MovingPlatform:new(x, y, width, height, speed, distance)
    local self = Platform.new(self, x, y, width, height)
    self.type = "movingPlatform"
    
    self.startX = x
    self.speed = speed or 50
    self.distance = distance or 100
    self.direction = 1
    
    return self
end

function MovingPlatform:update(dt)
    -- Moving platforms don't use default physics
    -- so we don't call BaseEntity.update
    
    -- Move platform back and forth
    self.x = self.x + self.speed * self.direction * dt
    
    -- Change direction when reaching limits
    if self.x > self.startX + self.distance then
        self.x = self.startX + self.distance
        self.direction = -1
    elseif self.x < self.startX then
        self.x = self.startX
        self.direction = 1
    end
end

function MovingPlatform:draw()
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return MovingPlatform