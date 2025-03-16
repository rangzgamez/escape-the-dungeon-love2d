-- states/fallingState.lua - Falling/Airborne state for the player

local BaseState = require("states/baseState")

local FallingState = setmetatable({}, BaseState)
FallingState.__index = FallingState

function FallingState:new(player)
    local self = BaseState.new(self, player)
    return self
end

function FallingState:enter(prevState)
    self.player.onGround = false
end

function FallingState:update(dt)
    -- Apply gravity
    self.player.velocity.y = self.player.velocity.y + self.player.gravity * dt
    
    -- Cap maximum fall speed to prevent tunneling through platforms
    self.player.velocity.y = math.min(self.player.velocity.y, 800)
    
    -- Apply velocities to position
    self.player.x = self.player.x + self.player.velocity.x * dt
    self.player.y = self.player.y + self.player.velocity.y * dt
end

function FallingState:checkHorizontalBounds(screenWidth)
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

-- Update FallingState's draw method to use jump-based colors
function FallingState:draw()
    -- Get color based on remaining jumps
    local jumpColor = self.player:getJumpColor()
    
    -- Draw player with jump-based color
    love.graphics.setColor(jumpColor)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
    
    -- Add a subtle glow that increases with more available jumps
    local glowIntensity = self.player.midairJumps / math.max(1, self.player.maxMidairJumps) * 0.4
    if glowIntensity > 0 then
        -- Draw glow around player
        love.graphics.setColor(jumpColor[1], jumpColor[2], jumpColor[3], glowIntensity)
        love.graphics.rectangle("fill", 
            self.player.x - 5, 
            self.player.y - 5, 
            self.player.width + 10, 
            self.player.height + 10,
            5, 5 -- Rounded corners
        )
    end
    
    -- Draw jump indicators - small circles showing available jumps
    if self.player.midairJumps > 0 then
        -- Distance between indicators
        local spacing = self.player.width / (self.player.maxMidairJumps + 1)
        
        -- Draw one indicator per available jump
        for i = 1, self.player.midairJumps do
            -- Position indicator evenly across player width
            local x = self.player.x + spacing * i
            local y = self.player.y - 10
            local radius = 3
            
            -- Draw white indicator with colored border
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", x, y, radius)
            love.graphics.setColor(jumpColor)
            love.graphics.circle("line", x, y, radius)
        end
    end
end

function FallingState:getName()
    return "Falling"
end
function FallingState:onDragEnd(data)
    if self.player:canJump() then
        self.player:deductJump()
        self.player.stateMachine:change("Dashing", data)
    end
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