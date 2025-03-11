-- states/idleState.lua - Idle/Ground state for the player

local BaseState = require("states/baseState")
local IdleState = setmetatable({}, BaseState)
IdleState.__index = IdleState

function IdleState:new(player)
    local self = BaseState.new(self, player)
    return self
end

-- Update IdleState:enter to reset midair jumps when landing
function IdleState:enter(prevState)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    
    -- Reset velocity and set onGround
    self.player.xVelocity = 0
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
function IdleState:update(dt)
    -- Handle horizontal movement (keyboard controls)
    self.player.xVelocity = 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.player.xVelocity = -self.player.horizontalSpeed
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.player.xVelocity = self.player.horizontalSpeed
    end
    
    -- Apply velocities to position
    self.player.x = self.player.x + self.player.xVelocity * dt
        
    -- Reset combo if on ground with active combo
    if self.player.comboCount > 0 then
        self.player:resetCombo()
    end
end

function IdleState:keypressed(key)
    -- Jump when space/up is pressed
    if key == "space" or key == "up" or key == "w" then
        -- Set up dash parameters
        self.player.dashTimeLeft = 0.3 -- Use a medium-length dash for keyboard controls
        self.player.dashDirection = {
            x = 0,
            y = -1 -- Straight up
        }
        
        -- Change to dashing state
        self.player.stateMachine:change("Dashing")
        
        -- Fire dash event with medium power
        self.events.fire("playerDashStarted", {
            power = 0.7,
            direction = {x = 0, y = -1},
            fromGround = true
        })
    end
end

function IdleState:onDragStart(x, y)
    -- Store drag start position
    self.player.dragStartX = x
    self.player.dragStartY = y
    
    -- Change to dragging state
    self.player.stateMachine:change("Dragging")
end

function IdleState:onLeftGround()
    -- Change to falling state
    self.player.stateMachine:change("Falling")
end

function IdleState:onLandOnGround()
    -- Already on ground, nothing to do
    self.player.onGround = true
end

function IdleState:checkHorizontalBounds(screenWidth)
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

function IdleState:handleCollision(enemy)
    local result = {
        enemyHit = false,
        playerHit = false
    }
    
    -- Default collision behavior if state didn't handle it
    if enemy.state ~= "stunned" then
        -- Enemy hits player - player takes damage
        self.player:takeDamage()
        
        -- Reset combo when hit
        self.player:resetCombo()
        
        result.playerHit = true
    end
    
    return result
end

function IdleState:draw()
    -- Draw player in green when on ground
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function IdleState:getName()
    return "Idle"
end

return IdleState