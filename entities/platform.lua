-- entities/platform.lua
local BaseEntity = require("entities/baseEntity")

local Platform = setmetatable({}, {__index = BaseEntity})
Platform.__index = Platform

function Platform:new(x, y, width, height)
    local self = BaseEntity.new(self, x, y, width, height, {
        type = "platform",
        collisionLayer = "platform",
        collidesWithLayers = {"player"},  -- Platforms collide with player
        solid = true,
        gravity = 0  -- Platforms don't fall
    })
    
    return self
end

function Platform:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Platform