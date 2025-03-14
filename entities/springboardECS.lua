-- entities/springboardECS.lua
local ECSEntity = require("entities/ecsEntity")
local Events = require("lib/events")

local SpringboardECS = setmetatable({}, {__index = ECSEntity})
SpringboardECS.__index = SpringboardECS

function SpringboardECS:new(x, y, width, height)
    -- Create with ECSEntity first
    local self = ECSEntity:new(x, y, width, height, {
        type = "springboard",
        collisionLayer = "springboard",
        collidesWithLayers = {"player"},
    })
    
    -- Now set metatable to SpringboardECS
    setmetatable(self, SpringboardECS)
    
    -- Springboard-specific properties
    self.boingEffect = nil  -- Timer for activation effect
    self.boostStrength = 1000  -- How strong the boost is
    
    -- Add springboard-specific components to ECS entity if available
    if self.ecsEntity then
        -- Add renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "rectangle",
            layer = 6,
            width = width,
            height = height,
            color = {0.8, 0, 0, 1},
            mode = "fill"
        })
        
        -- Add springboard component
        self.ecsEntity:addComponent("springboard", {
            boingEffect = self.boingEffect,
            boostStrength = self.boostStrength
        })
    end
    
    return self
end

function SpringboardECS:update(dt)
    -- Update activation effect timer
    if self.boingEffect and self.boingEffect > 0 then
        self.boingEffect = self.boingEffect - dt
        if self.boingEffect < 0 then
            self.boingEffect = nil
        end
        
        -- Update ECS entity if available
        if self.ecsEntity and self.ecsEntity:hasComponent("springboard") then
            self.ecsEntity:getComponent("springboard").boingEffect = self.boingEffect
        end
    end
    
    -- Call parent update
    ECSEntity.update(self, dt)
end

function SpringboardECS:draw()
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

function SpringboardECS:activate()
    self.boingEffect = 0.5  -- Time the effect will last
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("springboard") then
        self.ecsEntity:getComponent("springboard").boingEffect = self.boingEffect
    end
end

function SpringboardECS:onCollision(other, collisionData)
    -- Only boost player when coming from above
    local fromAbove = collisionData and collisionData.fromAbove
    
    if other.type == "player" and fromAbove then
        -- Get the player's movement component
        local movementComponent = nil
        if other.ecsEntity then
            movementComponent = other.ecsEntity:getComponent("movement")
        end
        
        -- Apply springboard effect
        if movementComponent then
            movementComponent.velocityY = -self.boostStrength
        else
            other.velocity.y = -self.boostStrength
        end
        
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
    return ECSEntity.onCollision(self, other, collisionData)
end

-- Destroy the springboard
function SpringboardECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to springboards
    self.active = false
end

return SpringboardECS 