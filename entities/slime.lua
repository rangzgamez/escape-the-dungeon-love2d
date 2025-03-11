-- slime.lua - Slime enemy for Love2D Vertical Jumper
local Events = require("lib/events")

local Slime = {}
Slime.__index = Slime

function Slime:new(x, y)
    local self = setmetatable({}, Slime)
    
    -- Position and dimensions
    self.x = x
    self.y = y
    self.width = 32
    self.height = 20
    
    -- Movement properties
    self.speed = 40
    self.jumpStrength = 300
    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 800
    
    -- Behavior
    self.state = "idle"  -- idle, jumping, stunned
    self.stunnedTime = 0
    self.stunnedDuration = 2 -- How long slime stays stunned when hit
    self.jumpTimer = love.math.random(1, 3)
    self.jumpCooldown = 0.5 -- Time after landing before jumping again
    self.waitTimer = self.jumpCooldown -- Timer for waiting on ground
    
    -- Detection properties
    self.detectionRadius = 200 -- How far the slime can "see" the player
    self.aggroRange = 300 -- Range at which slime becomes aggressive
    self.aggro = false -- Whether slime is targeting player
    
    -- Animation properties
    self.squishFactor = 1.0 -- For squish/stretch animation
    self.squishDirection = 0 -- 1 = squishing, -1 = stretching
    self.colorPulse = 0 -- For color pulsing effect
    self.colorPulseDirection = 1 -- 1 = brightening, -1 = dimming
    
    -- Particle timer for dripping effect
    self.dripTimer = love.math.random(0.5, 2)
    
    return self
end

function Slime:update(dt, player)
    -- Update animation
    self:updateAnimation(dt)
    
    -- Update drip timer
    self.dripTimer = self.dripTimer - dt
    if self.dripTimer <= 0 then
        self.dripTimer = love.math.random(0.5, 2)
        -- Fire drip event for particle effects
        Events.fire("slimeDrip", {
            x = self.x + love.math.random(5, self.width - 5),
            y = self.y + self.height - 5,
            color = {0.2, 0.8, 0.2}
        })
    end
    
    -- Check for player detection
    if player and self:canDetectPlayer(player) then
        -- Only become aggressive if player is close enough
        local distToPlayer = self:distanceToPlayer(player)
        self.aggro = distToPlayer < self.aggroRange
    else
        self.aggro = false
    end
    
    -- State machine for slime behavior
    if self.state == "stunned" then
        self:updateStunned(dt)
    elseif self.state == "jumping" then
        self:updateJumping(dt)
    else
        self:updateIdle(dt, player)
    end
    
    -- Apply movement
    self.x = self.x + self.xVelocity * dt
    self.y = self.y + self.yVelocity * dt
end

function Slime:updateAnimation(dt)
    -- Update color pulse effect
    self.colorPulse = self.colorPulse + dt * self.colorPulseDirection * 0.5
    if self.colorPulse > 0.2 then
        self.colorPulse = 0.2
        self.colorPulseDirection = -1
    elseif self.colorPulse < 0 then
        self.colorPulse = 0
        self.colorPulseDirection = 1
    end
    
    -- Handle squish/stretch animation
    if self.state == "jumping" then
        -- When jumping, stretch vertically
        if self.yVelocity < 0 then  -- Moving up
            self.squishFactor = math.min(self.squishFactor + dt * 2, 1.3)
            self.squishDirection = -1  -- Stretching
        else  -- Falling down
            self.squishFactor = math.max(self.squishFactor - dt * 2, 0.7)
            self.squishDirection = 1  -- Squishing
        end
    elseif self.state == "idle" then
        -- When idle, gently pulse
        if self.squishDirection == 0 then
            self.squishDirection = 1  -- Start squishing
        end
        
        self.squishFactor = self.squishFactor + self.squishDirection * dt * 0.5
        
        if self.squishFactor > 1.1 then
            self.squishFactor = 1.1
            self.squishDirection = -1
        elseif self.squishFactor < 0.9 then
            self.squishFactor = 0.9
            self.squishDirection = 1
        end
    elseif self.state == "stunned" then
        -- When stunned, flatten
        self.squishFactor = math.max(self.squishFactor - dt * 3, 0.5)
    end
end

function Slime:updateStunned(dt)
    self.stunnedTime = self.stunnedTime - dt
    
    -- Apply gravity when stunned
    self.yVelocity = self.yVelocity + self.gravity * dt
    
    -- Recover from stunned state
    if self.stunnedTime <= 0 then
        self.state = "idle"
        -- Reset velocity when recovering
        self.xVelocity = 0
        self.yVelocity = 0
        self.jumpTimer = love.math.random(1, 3)  -- Set timer for next jump
    end
end

function Slime:updateJumping(dt)
    -- Apply gravity
    self.yVelocity = self.yVelocity + self.gravity * dt
    
    -- Check if slime is falling
    if self.yVelocity > 0 then
        -- Check for landing
        -- This is a placeholder - in the real game you'd check for platform collisions
        -- For now, we'll simulate landing when reaching a certain height
        if self.y > 600 then  -- Arbitrary ground level for testing
            self:land()
        end
    end
end

function Slime:land()
    self.state = "idle"
    self.yVelocity = 0
    self.waitTimer = self.jumpCooldown  -- Wait a bit before jumping again
    
    -- Squish effect on landing
    self.squishFactor = 0.6
    self.squishDirection = 1
    
    -- Fire landed event
    Events.fire("slimeLanded", {
        x = self.x + self.width/2,
        y = self.y + self.height
    })
end

function Slime:updateIdle(dt, player)
    -- Wait after landing
    if self.waitTimer > 0 then
        self.waitTimer = self.waitTimer - dt
        return
    end
    
    -- Update jump timer
    self.jumpTimer = self.jumpTimer - dt
    
    if self.jumpTimer <= 0 then
        -- Prepare to jump!
        self:jump(player)
    end
end

function Slime:jump(player)
    self.state = "jumping"
    self.yVelocity = -self.jumpStrength
    
    -- Determine jump direction
    if player and self.aggro then
        -- Aggressive jump - aim toward player
        local playerCenterX = player.x + player.width/2
        local slimeCenterX = self.x + self.width/2
        
        -- Calculate direction and normalize
        local direction = playerCenterX - slimeCenterX
        local distance = math.abs(direction)
        
        -- Scale jump strength based on distance
        local jumpStrength = math.min(distance / 200, 1) * self.speed * 1.5
        
        -- Apply horizontal velocity toward player
        if distance > 0 then
            self.xVelocity = direction / distance * jumpStrength
        end
        
        -- Fire event for aggressive jump
        Events.fire("slimeAggroJump", {
            x = self.x + self.width/2,
            y = self.y
        })
    else
        -- Normal random jump
        self.xVelocity = love.math.random(-self.speed/2, self.speed/2)
    end
    
    -- Reset squish animation
    self.squishFactor = 1.3  -- Start stretched for jump
    self.squishDirection = -1
    
    -- Fire jump event
    Events.fire("slimeJump", {
        x = self.x + self.width/2,
        y = self.y
    })
end

function Slime:canDetectPlayer(player)
    -- Calculate distance to player
    local distance = self:distanceToPlayer(player)
    
    -- Return true if player is within detection radius
    return distance <= self.detectionRadius
end

function Slime:distanceToPlayer(player)
    local slimeCenterX = self.x + self.width/2
    local slimeCenterY = self.y + self.height/2
    local playerCenterX = player.x + player.width/2
    local playerCenterY = player.y + player.height/2
    
    local dx = playerCenterX - slimeCenterX
    local dy = playerCenterY - slimeCenterY
    return math.sqrt(dx*dx + dy*dy)
end

function Slime:stun()
    if self.state ~= "stunned" then
        self.state = "stunned"
        self.stunnedTime = self.stunnedDuration
        
        -- Bounce effect when stunned
        self.yVelocity = -200
        self.xVelocity = love.math.random(-50, 50)
        
        -- Flatten animation
        self.squishFactor = 0.5
        
        -- Fire stun event
        Events.fire("slimeStunned", {
            x = self.x + self.width/2,
            y = self.y + self.height/2
        })
    end
end

function Slime:draw()
    -- Set color based on state
    if self.state == "stunned" then
        love.graphics.setColor(0.5, 0.5, 0.5)  -- Gray when stunned
    else
        -- Green slime with pulsing effect
        local pulse = self.aggro and 0.5 or self.colorPulse  -- More intense pulse when aggressive
        love.graphics.setColor(0.2 + pulse, 0.8 - pulse * 0.5, 0.2)
    end
    
    -- Draw slime body with squish factor
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local drawWidth = self.width * (1 / self.squishFactor)
    local drawHeight = self.height * self.squishFactor
    
    -- Draw main body (ellipse approximated with rectangle + circles)
    love.graphics.rectangle(
        "fill", 
        centerX - drawWidth/2, 
        centerY - drawHeight/2 + drawHeight/4,  -- Offset to align bottom
        drawWidth, 
        drawHeight/2
    )
    
    -- Rounded top
    love.graphics.ellipse(
        "fill",
        centerX,
        centerY - drawHeight/4,
        drawWidth/2,
        drawHeight/4
    )
    
    -- Eyes - positioned based on slime dimensions and state
    love.graphics.setColor(1, 1, 1)
    local eyeOffsetX = drawWidth * 0.15
    local eyeOffsetY = drawHeight * 0.1
    local eyeSize = drawWidth * 0.1
    
    -- Calculate eye positions
    local leftEyeX = centerX - eyeOffsetX
    local rightEyeX = centerX + eyeOffsetX
    local eyeY = centerY - eyeOffsetY
    
    love.graphics.circle("fill", leftEyeX, eyeY, eyeSize)
    love.graphics.circle("fill", rightEyeX, eyeY, eyeSize)
    
    -- Pupils - move based on state and velocity
    love.graphics.setColor(0, 0, 0)
    local pupilSize = eyeSize * 0.6
    
    -- Calculate pupil positions with some movement based on velocity or state
    local pupilOffsetX = 0
    local pupilOffsetY = 0
    
    if self.state == "stunned" then
        -- X-shaped pupils when stunned
        love.graphics.line(leftEyeX - pupilSize, eyeY - pupilSize, leftEyeX + pupilSize, eyeY + pupilSize)
        love.graphics.line(leftEyeX - pupilSize, eyeY + pupilSize, leftEyeX + pupilSize, eyeY - pupilSize)
        
        love.graphics.line(rightEyeX - pupilSize, eyeY - pupilSize, rightEyeX + pupilSize, eyeY + pupilSize)
        love.graphics.line(rightEyeX - pupilSize, eyeY + pupilSize, rightEyeX + pupilSize, eyeY - pupilSize)
    else
        -- Look in movement direction or at player if aggressive
        if self.aggro then
            -- Intense stare when aggressive
            pupilSize = eyeSize * 0.7
            pupilOffsetX = eyeSize * 0.3 * (self.xVelocity > 0 and 1 or -1)
        elseif self.xVelocity > 5 then
            pupilOffsetX = eyeSize * 0.3
        elseif self.xVelocity < -5 then
            pupilOffsetX = -eyeSize * 0.3
        end
        
        -- Look up/down based on vertical velocity
        if self.yVelocity < -5 then
            pupilOffsetY = -eyeSize * 0.2
        elseif self.yVelocity > 5 then
            pupilOffsetY = eyeSize * 0.2
        end
        
        -- Draw the pupils
        love.graphics.circle("fill", leftEyeX + pupilOffsetX, eyeY + pupilOffsetY, pupilSize)
        love.graphics.circle("fill", rightEyeX + pupilOffsetX, eyeY + pupilOffsetY, pupilSize)
    end
    
    -- Draw drip effect (handled by particle system in game)
    if self.state ~= "stunned" and love.math.random() < 0.05 then
        love.graphics.setColor(0.2, 0.8, 0.2, 0.7)
        local dripWidth = love.math.random(2, 5)
        local dripHeight = love.math.random(3, 8)
        local dripX = centerX + love.math.random(-drawWidth/3, drawWidth/3)
        love.graphics.rectangle("fill", dripX, centerY + drawHeight/4, dripWidth, dripHeight)
    end
end

function Slime:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return Slime