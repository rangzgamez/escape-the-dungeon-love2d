-- states/fallingState.lua - Falling/Airborne state for the player

local BaseState = require("states/baseState")

local FallingState = setmetatable({}, BaseState)
FallingState.__index = FallingState

function FallingState:new(player)
    local self = BaseState.new(self, player)
    return self
end

function FallingState:enter(prevState)
    if prevState then
        print(prevState:getName())
    end
    self.player.onGround = false
end

function FallingState:update(dt)
    -- Apply gravity
    self.player.yVelocity = self.player.yVelocity + self.player.gravity * dt
    
    -- Cap maximum fall speed to prevent tunneling through platforms
    self.player.yVelocity = math.min(self.player.yVelocity, 800)
    
    -- Apply velocities to position
    self.player.x = self.player.x + self.player.xVelocity * dt
    self.player.y = self.player.y + self.player.yVelocity * dt
end

function FallingState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
        self.player.xVelocity = 0
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
        self.player.xVelocity = 0
    end
end

function FallingState:draw()
    -- Draw player in orange when in air
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function FallingState:getName()
    return "Falling"
end

function FallingState:enemyCollision(enemy)
    -- Enemy hits player - player takes damage
    self.player:takeDamage()
    -- Reset combo when hit
    self.player:resetCombo()
end

function FallingState:onLandOnGround()
    -- Change to Grounded state
    self.player.stateMachine:change("Grounded")
end
return FallingState