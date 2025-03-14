-- states/GroundedState.lua - Grounded/Ground state for the player

local BaseState = require("states/baseState")
local GroundedState = setmetatable({}, BaseState)
GroundedState.__index = GroundedState

function GroundedState:new(player)
    local self = BaseState.new(player)
    setmetatable(self, GroundedState)
    return self
end

-- Update GroundedState:enter to reset midair jumps when landing
function GroundedState:enter(prevState)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    
    if self.player and self.player.ecsEntity then
        -- ECS implementation
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        movementComponent.velocityX = 0
        movementComponent.velocityY = 0
        movementComponent.isGrounded = true
        
        -- Reset midair jumps when landing
        self.player:refreshJumps()
    else
        -- Legacy implementation
        -- Reset velocity and set onGround
        self.player.velocity.x = 0
        self.player.velocity.y = 0
        self.player.onGround = true
        -- Reset midair jumps when landing
        self.player:refreshJumps()
    end
    
    -- Check if we're landing from a fall or dash
    if prevState and (prevState:getName() == "falling" or prevState:getName() == "dashing") then
        -- Fire landing event
        self.events.fire("playerLand", {
            x = self.player.x + self.player.width/2,
            y = self.player.y + self.player.height
        })
    end
end

function GroundedState:onDragEnd(data)
    if data.isSignificantDrag then
        -- Dash in the direction opposite to the drag
        if self.player.ecsEntity then
            -- ECS implementation
            self.player:dash(data.direction)
        else
            -- Legacy implementation
            self.player.stateMachine:change("dashing", data)
        end
    end
end

function GroundedState:update(dt)
    if self.player.ecsEntity then
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        
        -- Check if we're falling
        if not movementComponent.isGrounded then
            self.player.stateMachine:change("falling")
        end
    else
        -- Legacy implementation
        -- Check if we're falling
        if not self.player.onGround then
            self.player.stateMachine:change("falling")
        end
    end
end

function GroundedState:onLeftGround()
    -- Change to falling state
    if self.player.ecsEntity then
        -- ECS implementation
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        if movementComponent.velocityY > 5 then
            -- Change to falling state
            self.player.stateMachine:change("falling")
        end
    else
        -- Legacy implementation
        if self.player.velocity.y > 5 then
            -- Change to falling state
            self.player.stateMachine:change("falling")
        end
    end
end

function GroundedState:checkHorizontalBounds(screenWidth)
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

function GroundedState:enemyCollision(enemy)
    -- Enemy hits player - player takes damage
    self.player:takeDamage()
    -- Reset combo when hit
    if self.player.resetCombo then
        self.player:resetCombo()
    end
end

function GroundedState:draw()
    -- Draw player in green when on ground
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function GroundedState:getName()
    return "grounded"
end

return GroundedState