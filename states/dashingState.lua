-- states/dashingState.lua - Dashing state for the player

local BaseState = require("states/baseState")
local Physics = require('lib/physics')
local DashingState = setmetatable({}, BaseState)
DashingState.__index = DashingState

function DashingState:new(player)
    local self = BaseState.new(self, player)
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
    self.player.onGround = false
    
    -- Initialize afterImageTimer when entering dashing state
    self.afterImageTimer = 0.02
    
    -- Clear after image positions
    self.player.afterImagePositions = {}
    -- Set up dash parameters
    self.dashDirection = data.direction
    self.dashPower = data.power
    self.dashTimeLeft = self.player.minDashDuration + data.power * (self.player.maxDashDuration - self.player.minDashDuration)
    -- Fire event for visual effects
    self.events.fire("playerDashStarted", {
        power = self.dashPower,
        direction = self.dashDirection,
        fromGround = prevState and prevState:getName() == "Grounded"
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
    
    -- End dash when timer runs out
    if self.dashTimeLeft <= 0 then
        -- Set velocities for transition to falling
        self.player.velocity.x = self.dashDirection.x * self.player.dashSpeed * 0.2 * self.dashPower
        self.player.velocity.y = 0
        
        -- Change to falling state
        self.player.stateMachine:change("Falling")
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
    self.player:refreshJumps() -- CORRECTED METHOD NAME
    
    -- Increment combo counter
    self.player:incrementCombo()
end

-- Update DashingState's draw method to incorporate jump-based colors
function DashingState:draw()
    -- Get base color from jump status - but enhance it for dash effect
    local jumpColor = self.player:getJumpColor()
    
    -- Enhance color for dashing - make it more vibrant/lighter
    local dashColor = {
        math.min(1, jumpColor[1] + 0.2),
        math.min(1, jumpColor[2] + 0.2),
        math.min(1, jumpColor[3] + 0.2)
    }
    
    -- Draw afterimages
    if self.player.afterImagePositions and #self.player.afterImagePositions > 0 then
        for i, pos in ipairs(self.player.afterImagePositions) do
            -- Fade opacity based on age of after-image
            local opacity = i / #self.player.afterImagePositions * 0.7
            
            -- Use a color based on the jump color but with fading opacity
            love.graphics.setColor(dashColor[1], dashColor[2], dashColor[3], opacity)
            love.graphics.rectangle("fill", pos.x, pos.y, self.player.width, self.player.height)
        end
    end
    
    -- Draw main player in dash color
    love.graphics.setColor(dashColor)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
    
    -- Draw dash streak/motion blur using jump colors
    love.graphics.setColor(dashColor[1], dashColor[2], dashColor[3], 0.5)
    for i = 1, 5 do
        local streakLength = i * 5
        love.graphics.line(
            self.player.x + self.player.width/2, 
            self.player.y + self.player.height/2,
            self.player.x + self.player.width/2 - self.dashDirection.x * streakLength,
            self.player.y + self.player.height/2 - self.dashDirection.y * streakLength
        )
    end
    
    -- Draw direction line with jump color
    love.graphics.setColor(dashColor[1], dashColor[2], dashColor[3], 0.8)
    love.graphics.line(
        self.player.x + self.player.width/2,
        self.player.y + self.player.height/2,
        self.player.x + self.player.width/2 + self.dashDirection.x * 30,
        self.player.y + self.player.height/2 + self.dashDirection.y * 30
    )
end
function DashingState:onDragEnd(data)
    if self.player:canJump() then
        self.player:deductJump()
        --reset dash parameters
        self.afterImageTimer = nil
        self.dashTimeLeft = 0
        self.dashDirection = nil
        self.dashPower = nil
        self.player.stateMachine:change("Dashing", data)
    end
end
function DashingState:getName()
    return "Dashing"
end

return DashingState