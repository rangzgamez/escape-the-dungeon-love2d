-- states/fallingState.lua - Falling/Airborne state for the player

local BaseState = require("states/baseState")

local FallingState = setmetatable({}, BaseState)
FallingState.__index = FallingState

function FallingState:new(player)
    local self = BaseState.new(self, player)
    return self
end

function FallingState:enter()
    -- Nothing special needed when entering falling state
end

function FallingState:update(dt)
    -- Handle horizontal movement (keyboard controls)
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.player.xVelocity = -self.player.horizontalSpeed
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.player.xVelocity = self.player.horizontalSpeed
    end
    
    -- Apply gravity
    self.player.yVelocity = self.player.yVelocity + self.player.gravity * dt
    
    -- Cap maximum fall speed to prevent tunneling through platforms
    self.player.yVelocity = math.min(self.player.yVelocity, 800)
    
    -- Apply velocities to position
    self.player.x = self.player.x + self.player.xVelocity * dt
    self.player.y = self.player.y + self.player.yVelocity * dt
end

function FallingState:keypressed(key)
    -- Jump when space/up is pressed if we have midair jumps available
    if (key == "space" or key == "up" or key == "w") and self.player.midairJumps > 0 then
        -- Consume a midair jump
        self.player.midairJumps = self.player.midairJumps - 1
        
        -- Set up dash parameters
        self.player.dashTimeLeft = 0.3 -- Slightly shorter dash for midair jump
        self.player.dashDirection = {
            x = 0,
            y = -1 -- Straight up
        }
        
        -- Change to dashing state
        self.player.stateMachine:change("Dashing")
        
        -- Fire dash event with power data
        self.events.fire("playerDashStarted", {
            power = 0.5,
            direction = {x = 0, y = -1},
            fromGround = false
        })
    end
end

function FallingState:mousepressed(x, y, button)
    if button == 1 and self.player.canJump() then -- Left mouse button
        self.player:changeState("Dragging")
        self.player.dragStartX = x
        self.player.dragStartY = y
    end
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

function FallingState:onDragStart(x, y)
    -- Check if we have any midair jumps available
    if self.player.midairJumps > 0 then
        -- Store drag start position
        self.player.dragStartX = x
        self.player.dragStartY = y
        
        -- Change to dragging state
        self.player.stateMachine:change("Dragging")
    end
    -- Otherwise ignore the drag if we have no midair jumps left
end


function FallingState:onLandOnGround()
    -- Change to idle state
    self.player.stateMachine:change("Idle")
end
return FallingState