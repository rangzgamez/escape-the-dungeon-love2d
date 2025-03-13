-- entities/slime.lua
local BaseEntity = require("entities/baseEntity")
local Events = require("lib/events")

local Slime = setmetatable({}, {__index = BaseEntity})
Slime.__index = Slime

function Slime:new(x, y, platform)
    -- Create with BaseEntity first
    local self = BaseEntity:new(x, y, 32, 20, {
        type = "enemy",
        collisionLayer = "enemy",
        collidesWithLayers = {"player"},
    })
    
    -- Now set metatable to Slime
    setmetatable(self, Slime)
    
    -- Store reference to the platform this slime patrols on
    self.platform = platform
    
    -- Reposition on top of platform if provided
    if platform then
        self.y = platform.y - self.height
    end
    
    -- Movement properties
    self.patrolSpeed = 40
    self.gravityValue = 800 -- Only used when stunned
    
    -- Patrol behavior
    self.state = "patrolling"  -- patrolling or stunned
    self.direction = love.math.random() > 0.5 and 1 or -1 -- Random initial direction
    self.directionChangeTimer = love.math.random(2, 5) -- Random time until direction change
    
    -- Stunned state properties
    self.stunnedTime = 0
    self.stunnedDuration = 2 -- How long slime stays stunned when hit
    
    -- Detection properties
    self.detectionRadius = 150 -- How far the slime can "see" the player
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
    -- Skip update if not active
    if not self.active then return end
    
    -- Update animation
    self:updateAnimation(dt)
    
    -- Update drip timer for visual effects
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
    
    -- Check for player detection to determine aggro state
    if player and self:canDetectPlayer(player) then
        self.aggro = true
    else
        self.aggro = false
    end
    
    -- State machine for slime behavior
    if self.state == "stunned" then
        self:updateStunned(dt)
    else
        self:updatePatrolling(dt, player)
    end
    
    -- No need to call BaseEntity.update - we handle movement ourselves
    -- Note: We're using our own state-based physics instead of BaseEntity's
    -- But we're still using BaseEntity properties like x, y, and velocity
    
    -- If not stunned, ensure slime stays on platform
    if self.state ~= "stunned" and self.platform then
        self.y = self.platform.y - self.height -- Keep aligned to platform
    end
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
    
    -- Handle squish/stretch animation based on state and movement
    if self.state == "patrolling" then
        -- When moving, squish slightly with movement
        if self.velocity.x ~= 0 then
            -- Oscillate squish based on movement
            self.squishFactor = 1 + 0.1 * math.sin(love.timer.getTime() * 5)
        else
            -- Return to normal when not moving
            self.squishFactor = 1
        end
    elseif self.state == "stunned" then
        -- When stunned, flatten
        self.squishFactor = math.max(self.squishFactor - dt * 3, 0.5)
    end
end

function Slime:updateStunned(dt)
    self.stunnedTime = self.stunnedTime - dt
    
    -- Apply gravity when stunned
    self.velocity.y = self.velocity.y + self.gravityValue * dt
    
    -- Apply movement
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
    
    -- Recover from stunned state
    if self.stunnedTime <= 0 then
        self.state = "patrolling"
        -- Reset velocity when recovering
        self.velocity.x = 0
        self.velocity.y = 0
        
        -- If we have a platform, return to it
        if self.platform then
            self.y = self.platform.y - self.height
        end
    end
end

function Slime:updatePatrolling(dt, player)
    -- Direction change timer
    self.directionChangeTimer = self.directionChangeTimer - dt
    if self.directionChangeTimer <= 0 then
        -- Randomly change direction
        self.direction = self.direction * -1
        self.directionChangeTimer = love.math.random(2, 5)
    end
    
    -- If we have a platform, check for edges
    if self.platform then
        -- Check if at left edge of platform
        if self.x <= self.platform.x and self.direction < 0 then
            self.direction = 1
            self.x = self.platform.x -- Ensure slime stays on platform
        end
        
        -- Check if at right edge of platform
        if self.x + self.width >= self.platform.x + self.platform.width and self.direction > 0 then
            self.direction = -1
            self.x = self.platform.x + self.platform.width - self.width -- Ensure slime stays on platform
        end
    end
    
    -- Set horizontal velocity based on direction and state
    if self.aggro then
        -- Move faster when player is detected
        self.velocity.x = self.direction * self.patrolSpeed * 1.5
    else
        self.velocity.x = self.direction * self.patrolSpeed
    end
    
    -- No vertical velocity while patrolling
    self.velocity.y = 0
    
    -- Apply horizontal movement
    self.x = self.x + self.velocity.x * dt
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
        self.velocity.y = -200
        self.velocity.x = love.math.random(-50, 50)
        
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
    -- Skip if not active
    if not self.active then return end
    
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
            pupilOffsetX = eyeSize * 0.3 * (self.velocity.x > 0 and 1 or -1)
        elseif self.velocity.x > 5 then
            pupilOffsetX = eyeSize * 0.3
        elseif self.velocity.x < -5 then
            pupilOffsetX = -eyeSize * 0.3
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
    
    -- Debug: draw platform boundaries if in debug mode
    if false then -- Set to true to enable debugging
        if self.platform then
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.rectangle("line", self.platform.x, self.platform.y, self.platform.width, self.platform.height)
        end
    end
end

-- Override onCollision to handle player collision
function Slime:onCollision(other, collisionData)
    if other.type == "player" then
        -- Let the collision system handle it based on player state
        return false
    end
    
    return false
end

return Slime