-- entities/movingPlatformECS.lua
local PlatformECS = require("entities/platformECS")

local MovingPlatformECS = setmetatable({}, {__index = PlatformECS})
MovingPlatformECS.__index = MovingPlatformECS

function MovingPlatformECS:new(x, y, width, height, speed, distance)
    local self = PlatformECS.new(self, x, y, width, height)
    self.type = "movingPlatform"
    
    self.startX = x
    self.speed = speed or 50
    self.distance = distance or 100
    self.direction = 1
    
    -- Add moving platform specific components to ECS entity if available
    if self.ecsEntity then
        -- Update type component
        if self.ecsEntity:hasComponent("type") then
            self.ecsEntity:getComponent("type").name = "movingPlatform"
        end
        
        -- Add moving platform component
        self.ecsEntity:addComponent("movingPlatform", {
            startX = self.startX,
            speed = self.speed,
            distance = self.distance,
            direction = self.direction
        })
        
        -- Update renderer component color
        if self.ecsEntity:hasComponent("renderer") then
            self.ecsEntity:getComponent("renderer").color = {0.3, 0.5, 0.7, 1}
        end
    end
    
    return self
end

function MovingPlatformECS:update(dt)
    -- Moving platforms don't use default physics
    -- so we don't call PlatformECS.update
    
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
    
    -- Update ECS entity position if available
    if self.ecsEntity then
        self:setPosition(self.x, self.y)
        
        -- Update moving platform component
        if self.ecsEntity:hasComponent("movingPlatform") then
            local mp = self.ecsEntity:getComponent("movingPlatform")
            mp.direction = self.direction
        end
    end
end

function MovingPlatformECS:draw()
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

-- Destroy the moving platform
function MovingPlatformECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to moving platforms
    self.active = false
end

return MovingPlatformECS 