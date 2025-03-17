-- states/GroundedState.lua - Grounded/Ground state for the player

local BaseState = require("states/baseState")
local GroundedState = setmetatable({}, BaseState)
GroundedState.__index = GroundedState

function GroundedState:new(player)
    local self = BaseState.new(self, player)
    return self
end

-- Update GroundedState:enter to reset midair jumps when landing
function GroundedState:enter(prevState)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    -- Reset velocity and set onGround
    self.player.velocity.x = 0
    self.player.velocity.y = 0
    self.player.onGround = true
    -- Reset midair jumps when landing
    self.player:refreshJumps()
    
    -- Fire landed event if coming from falling or dashing
    if prevState and (prevState:getName() == "Falling" or prevState:getName() == "Dashing") then
        self.events.fire("playerLanded", {
            x = self.player.x,
            y = self.player.y
        })
    end
end

function GroundedState:onDragEnd(data)
    self.player.stateMachine:change("Dashing", data)
end
function GroundedState:update(dt)
    -- Handle horizontal movement (keyboard controls)
    self.player.velocity.x = 0
    self.player.velocity.y = 0

    -- Apply velocities to position
    self.player.x = self.player.x + self.player.velocity.x * dt
        
end

function GroundedState:onLeftGround()
    -- Change to falling state
    if self.player.velocity.y > 5 then
        -- Change to falling state
        self.player.stateMachine:change("Falling")
    end
end

function GroundedState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
        self.player.velocity.x = 0
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
        self.player.velocity.x = 0
    end
end

function GroundedState:enemyCollision(enemy)
    -- Enemy hits player - player takes damage
    self.player:takeDamage()
end

function GroundedState:draw()
    -- Draw player in green when on ground
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function GroundedState:getName()
    return "Grounded"
end

return GroundedState