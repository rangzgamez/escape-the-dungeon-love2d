-- entities/platformECS.lua
local ECSEntity = require("entities/ecsEntity")

local PlatformECS = setmetatable({}, {__index = ECSEntity})
PlatformECS.__index = PlatformECS

function PlatformECS:new(x, y, width, height)
    local self = ECSEntity.new(self, x, y, width, height, {
        type = "platform",
        collisionLayer = "platform",
        collidesWithLayers = {"player"},  -- Platforms collide with player
        solid = true
    })
    
    -- Add platform-specific components to ECS entity if available
    if self.ecsEntity then
        -- Add renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "rectangle",
            layer = 5,
            width = width,
            height = height,
            color = {0.5, 0.5, 0.5, 1},
            mode = "fill"
        })
    end
    
    return self
end

function PlatformECS:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

-- Destroy the platform
function PlatformECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to platforms
    self.active = false
end

return PlatformECS 