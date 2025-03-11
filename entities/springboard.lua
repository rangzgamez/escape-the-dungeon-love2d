-- springboard.lua - Springboard class for Love2D Platformer

local Springboard = {}
Springboard.__index = Springboard

function Springboard:new(x, y, width, height)
    local self = setmetatable({}, Springboard)
    
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.boingEffect = nil
    
    return self
end

function Springboard:update(dt)
    if self.boingEffect and self.boingEffect > 0 then
        self.boingEffect = self.boingEffect - dt
        if self.boingEffect < 0 then
            self.boingEffect = nil
        end
    end
end

function Springboard:activate()
    self.boingEffect = 0.5  -- Time the effect will last
end

function Springboard:draw()
    if self.boingEffect then
        -- Activation animation - bright red
        love.graphics.setColor(1, 0, 0)
    else
        -- Normal color - red
        love.graphics.setColor(0.8, 0, 0)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return Springboard
