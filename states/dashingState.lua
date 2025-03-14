-- states/dashingState.lua - Dashing state for the player

local BaseState = require("states/baseState")
local Physics = require('lib/physics')
local DashingState = setmetatable({}, BaseState)
DashingState.__index = DashingState

function DashingState:new(player)
    local self = BaseState.new(player)
    setmetatable(self, DashingState)
    -- Dash specific state values
    self.afterImageTimer = nil
    self.dashTimeLeft = nil
    self.dashDirection = nil
    self.dashPower = nil
    return self
end

function DashingState:enter(prevState, data)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    
    if self.player.ecsEntity then
        -- ECS implementation
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        movementComponent.isGrounded = false
        
        -- Set up dash parameters
        if data then
            -- Use provided dash data
            self.dashDirection = data.direction
            self.dashPower = data.power or 1.0
            
            -- Make sure dashDirection is set in the movement component
            movementComponent.dashDirection = {
                x = self.dashDirection.x,
                y = self.dashDirection.y
            }
            
            -- Calculate dash duration based on power
            self.dashTimeLeft = movementComponent.minDashDuration + self.dashPower * (movementComponent.maxDashDuration - movementComponent.minDashDuration)
        end
    else
        -- Legacy implementation
        self.player.onGround = false
    end
    
    -- Initialize afterImageTimer when entering dashing state
    self.afterImageTimer = 0.02
    
    -- Clear after image positions
    self.player.afterImagePositions = {}
    
    -- Check if we're coming from grounded state
    local fromGround = prevState and prevState:getName() == "grounded"
    
    -- Set up dash parameters
    if data then
        -- Use provided dash data
        self.dashDirection = data.direction
        self.dashPower = data.power or 1.0
        
        -- Calculate dash duration based on power
        if self.player.ecsEntity then
            local movementComponent = self.player.ecsEntity:getComponent("movement")
            self.dashTimeLeft = movementComponent.minDashDuration + self.dashPower * (movementComponent.maxDashDuration - movementComponent.minDashDuration)
        else
            -- Legacy player
            self.dashTimeLeft = self.player.minDashDuration + self.dashPower * (self.player.maxDashDuration - self.player.minDashDuration)
        end
    end
    
    -- Fire event for visual effects
    self.events.fire("playerDashStarted", {
        power = self.dashPower,
        direction = self.dashDirection,
        fromGround = fromGround
    })
end

function DashingState:update(dt)
    -- Update afterimage timer
    if not self.afterImageTimer or self.afterImageTimer <= 0 then
        if #self.player.afterImagePositions >= 5 then
            table.remove(self.player.afterImagePositions, 1) -- Remove oldest
        end
        -- Store center position for consistent comparison with trajectory
        table.insert(self.player.afterImagePositions, {x = self.player.x, y = self.player.y})
        self.afterImageTimer = 0.02 -- Store position every 0.02 seconds
    else
        self.afterImageTimer = self.afterImageTimer - dt
    end
    
    if self.player.ecsEntity then
        -- ECS implementation
        local movementComponent = self.player.ecsEntity:getComponent("movement")
        
        -- Update dash timer
        self.dashTimeLeft = self.dashTimeLeft - dt
        
        -- Apply dash movement directly
        if movementComponent.dashDirection then
            -- Apply dash velocity continuously during the dash
            movementComponent.velocityX = movementComponent.dashDirection.x * movementComponent.dashSpeed * self.dashPower
            movementComponent.velocityY = movementComponent.dashDirection.y * movementComponent.dashSpeed * self.dashPower
        end
        
        -- End dash and transition to falling state
        if self.dashTimeLeft <= 0 then
            -- Set velocities for transition to falling
            if movementComponent.dashDirection then
                movementComponent.velocityX = movementComponent.dashDirection.x * movementComponent.dashSpeed * 0.2 * self.dashPower
                movementComponent.velocityY = 0
            end
            
            -- Reset dash state
            movementComponent.isDashing = false
            
            -- Transition to falling state
            self.player.stateMachine:change("falling")
        end
    else
        -- Legacy implementation
        -- Use the shared Physics module to move the player exactly as calculated in the trajectory
        local centerX, centerY = Physics.applyDashMovement(
            self.player,       -- player object 
            self.dashDirection, -- dash direction
            self.player.dashSpeed, -- dash speed
            self.dashPower,    -- dash power
            dt                 -- delta time
        )
        
        -- Update player position from center to top-left
        self.player.x = centerX - self.player.width/2
        self.player.y = centerY - self.player.height/2
        
        -- Update dash timer
        self.dashTimeLeft = self.dashTimeLeft - dt
        
        -- End dash and transition to falling state
        if self.dashTimeLeft <= 0 then
            -- Set velocities for transition to falling
            self.player.velocity.x = self.dashDirection.x * self.player.dashSpeed * 0.2 * self.dashPower
            self.player.velocity.y = 0
            
            -- Transition to falling state
            self.player.stateMachine:change("falling")
        end
    end
end

function DashingState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
        
        -- Bounce off wall by reversing horizontal direction
        if self.dashDirection.x < 0 then
            self.dashDirection.x = -self.dashDirection.x
        end
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
        
        -- Bounce off wall by reversing horizontal direction
        if self.dashDirection.x > 0 then
            self.dashDirection.x = -self.dashDirection.x
        end
    end
end

function DashingState:enemyCollision(enemy)
    -- Player dashing into enemy - stun the enemy
    enemy:stun()
    -- Fire enemy kill event with combo count
    self.events.fire("enemyKill", {
        comboCount = self.player.comboCount,
        enemy = enemy
    })
    -- Refresh the player's dash
    self.player:refreshJumps()
    
    -- Increment combo counter
    if self.player.incrementCombo then
        self.player:incrementCombo()
    end
end

function DashingState:draw()
    -- Draw player in red when dashing
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
    
    -- Draw after-images
    if self.player.afterImagePositions and #self.player.afterImagePositions > 0 then
        for i, pos in ipairs(self.player.afterImagePositions) do
            -- Fade opacity based on age of after-image
            local opacity = i / #self.player.afterImagePositions * 0.7
            love.graphics.setColor(1, 0.3, 0.3, opacity)
            love.graphics.rectangle("fill", pos.x, pos.y, self.player.width, self.player.height)
        end
    end
    
    -- Draw motion blur lines behind player to indicate speed
    love.graphics.setColor(1, 0.3, 0.3, 0.5) -- Red with transparency
    for i = 1, 5 do
        local dashLength = i * 5
        love.graphics.line(
            self.player.x + self.player.width/2, 
            self.player.y + self.player.height/2,
            self.player.x + self.player.width/2 - self.dashDirection.x * dashLength,
            self.player.y + self.player.height/2 - self.dashDirection.y * dashLength
        )
    end
end

function DashingState:onDragEnd(data)
    if self.player.ecsEntity then
        -- ECS implementation
        self.player:dash(data.direction)
    else
        -- Legacy implementation
        if self.player:canJump() then
            self.player:deductJump()
            self.player.stateMachine:change("Dashing", data)
        end
    end
end

function DashingState:getName()
    return "dashing"
end

return DashingState