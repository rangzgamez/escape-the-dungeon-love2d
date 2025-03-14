local BaseEntity = require("entities/baseEntity")

local KillFloor = setmetatable({}, {__index = BaseEntity})
KillFloor.__index = KillFloor

function KillFloor:new(width)
    -- Create a wide floor that spans the entire game width
    local self = BaseEntity.new(self, 0, 0, width, 100, {
        type = "killFloor",
        collisionLayer = "killFloor",
        collidesWithLayers = {"enemy", "collectible", "platform", "powerup"},
        solid = false -- Non-solid entity
    })
    
    self.debug = false -- Set to true to visualize the kill floor
    
    setmetatable(self, KillFloor)
    return self
end

function KillFloor:update(dt)
    -- This entity doesn't need standard physics updates
    -- But we can still use the parent's update method if needed
    BaseEntity.update(self, dt)
end

function KillFloor:draw()
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function KillFloor:onCollision(other, collisionData)
    -- When anything collides with the kill floor, deactivate it
    if other.type ~= 'player' then
        other.destroy()
        print('we did it')
    end
    return true
end

return KillFloor