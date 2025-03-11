-- platform.lua - Platform class for Love2D Platformer

local Platform = {}
Platform.__index = Platform

function Platform:new(x, y, width, height)
    local self = setmetatable({}, Platform)
    
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    
    return self
end

function Platform:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Platform
