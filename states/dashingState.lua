-- states/dashingState.lua - Dashing state for the player

local BaseState = require("states/baseState")

local DashingState = setmetatable({}, BaseState)
DashingState.__index = DashingState

function DashingState:new(player)
    local self = BaseState.new(self, player)
    -- Dash specific state values
    self.afterImageTimer = nil
    self.dashTimeLeft = nil
    self.dashDirection = nil
    return self
end

function DashingState:enter(prevState, data)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)

    -- only deduct midairJumps if dashing midair
    if not prevState:getName() == 'Idle' then
        self.player.deductJump()
    end

    -- Initialize afterImageTimer when entering dashing state
    self.afterImageTimer = 0.02
    -- Clear after image positions
    self.player.afterImagePositions = {}
            
    -- Set up dash parameters
    self.dashTimeLeft = self.player.minDashDuration + data.power * (self.player.maxDashDuration - self.player.minDashDuration)
    self.dashDirection = data.direction
                
    -- for visual effects and potentially other items
    self.events.fire("playerDashStarted", {
        power = data.power,
        direction = data.direction,
        fromGround = prevState:getName() == 'Idle'
    })
end

function DashingState:update(dt)
    -- Store positions for after-images
    if not self.afterImageTimer or self.afterImageTimer <= 0 then
        -- Store up to 5 recent positions
        if #self.player.afterImagePositions >= 5 then
            table.remove(self.player.afterImagePositions, 1) -- Remove oldest
        end
        table.insert(self.player.afterImagePositions, {x = self.player.x, y = self.player.y})
        self.afterImageTimer = 0.02 -- Store position every 0.02 seconds
    else
        self.afterImageTimer = self.afterImageTimer - dt
    end
    
    -- Update dash timer
    self.player.dashTimeLeft = self.player.dashTimeLeft - dt
    
    -- Apply dash velocity
    self.player.x = self.player.x + self.dashDirection.x * self.player.dashSpeed * dt
    self.player.y = self.player.y + self.dashDirection.y * self.player.dashSpeed * dt
    
    -- End dash when timer runs out
    if self.dashTimeLeft <= 0 then
        -- Set vertical velocity to 0 for instant drop
        self.player.xVelocity = 0  --self.player.dashDirection.x * self.player.dashSpeed * 0.2 -- Keep a small horizontal momentum
        self.player.yVelocity = 0 -- Reset vertical velocity for straight drop
        
        -- Switch to falling state
        self.player:changeState("Falling")
    end
end

function DashingState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
        
        -- Bounce off wall by reversing horizontal direction
        if self.player.dashDirection.x < 0 then
            self.player.dashDirection.x = -self.player.dashDirection.x
        end
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
        
        -- Bounce off wall by reversing horizontal direction
        if self.player.dashDirection.x > 0 then
            self.player.dashDirection.x = -self.player.dashDirection.x
        end
    end
end

function DashingState:handleCollision(enemy)
    local result = {
        enemyHit = false,
        playerHit = false
    }
    
    -- Only stun enemy if not already stunned
    if enemy.state and enemy.state ~= "stunned" and enemy.stun then
        enemy:stun()
        result.enemyHit = true
        
        -- Refresh the player's dash
        self.player:refreshJumps()
        
        -- Increment combo counter
        self.player:incrementCombo()
        
        -- Fire enemy kill event for other systems to handle
        self.events.fire("enemyKill", {
            comboCount = self.player.comboCount,
            enemy = enemy
        })
        
        return result
    end
    
    -- No collision handling done
    return false
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
            self.player.x + self.player.width/2 - self.player.dashDirection.x * dashLength,
            self.player.y + self.player.height/2 - self.player.dashDirection.y * dashLength
        )
    end
end

function DashingState:getName()
    return "Dashing"
end

return DashingState