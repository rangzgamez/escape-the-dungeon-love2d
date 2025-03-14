-- states/fallingState.lua - Falling/Airborne state for the player

local BaseState = require("states/baseState")

local FallingState = setmetatable({}, BaseState)
FallingState.__index = FallingState

function FallingState:new(player)
    local self = BaseState.new(player)
    setmetatable(self, FallingState)
    return self
end

function FallingState:enter(prevState)
    if self.player.ecsEntity then
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        movementComponent.isGrounded = false
    else
        self.player.onGround = false
    end
end

function FallingState:update(dt)
    -- Check if we've landed on a platform
    if self.player.ecsEntity then
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        if movementComponent.isGrounded then
            self.player.stateMachine:change("grounded")
        end
    else
        if self.player.onGround then
            self.player.stateMachine:change("grounded")
        end
    end
end

function FallingState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
        if self.player.ecsEntity then
            local movementComponent = self.player.ecsEntity:getComponent("movement")
            movementComponent.velocityX = 0
        else
            self.player.velocity.x = 0
        end
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
        if self.player.ecsEntity then
            local movementComponent = self.player.ecsEntity:getComponent("movement")
            movementComponent.velocityX = 0
        else
            self.player.velocity.x = 0
        end
    end
end

function FallingState:draw()
    -- Draw player in orange when in air
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function FallingState:getName()
    return "falling"
end

function FallingState:onDragEnd(data)
    if self.player.ecsEntity then
        -- ECS implementation
        self.player:dash(data.direction)
    else
        -- Legacy implementation
        self.player.stateMachine:change("dashing", data)
    end
end

function FallingState:enemyCollision(enemy)
    -- Enemy hits player - player takes damage
    self.player:takeDamage()
    -- Reset combo when hit
    if self.player.resetCombo then
        self.player:resetCombo()
    end
end

function FallingState:onLandOnGround()
    -- Change to Grounded state
    self.player.stateMachine:change("grounded")
end

return FallingState