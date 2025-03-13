-- entities/springboard.lua
local BaseEntity = require("entities/baseEntity")
local Events = require("lib/events")

local Springboard = setmetatable({}, {__index = BaseEntity})
Springboard.__index = Springboard

function Springboard:new(x, y, width, height)
    -- Create with BaseEntity first
    local self = BaseEntity:new(x, y, width, height, {
        type = "springboard",
        collisionLayer = "springboard",
        collidesWithLayers = {"player"},
    })
    
    -- Now set metatable to Springboard
    setmetatable(self, Springboard)
    
    -- Springboard-specific properties
    self.boingEffect = nil  -- Timer for activation effect
    self.boostStrength = 1000  -- How strong the boost is
    
    return self
end

function Springboard:update(dt)
    -- Update activation effect timer
    if self.boingEffect and self.boingEffect > 0 then
        self.boingEffect = self.boingEffect - dt
        if self.boingEffect < 0 then
            self.boingEffect = nil
        end
    end
end

function Springboard:draw()
    -- Draw based on activation state
    if self.boingEffect then
        -- Activation animation - bright red
        love.graphics.setColor(1, 0, 0)
    else
        -- Normal color - red
        love.graphics.setColor(0.8, 0, 0)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

function Springboard:activate()
    self.boingEffect = 0.5  -- Time the effect will last
end
-- In Springboard:onCollision
function Springboard:onCollision(other, collisionData)
    -- Only boost player when coming from above
    if other.type == "player" and other.velocity.y > 0 then
        -- Apply springboard effect
        other.velocity.y = -self.boostStrength
        self:activate()
        
        -- Fire springboard jump event
        Events.fire("playerSpringboardJump", {
            x = self.x + self.width/2,
            y = self.y
        })
        
        -- Reset player's mid-air jumps
        if other.refreshJumps then
            other:refreshJumps()
        end
        
        -- We handled the collision
        return true
    end
    
    -- We didn't handle the collision
    return false
end
return Springboard