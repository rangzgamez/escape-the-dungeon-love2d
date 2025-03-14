-- entities/slimeECS.lua
local ECSEntity = require("entities/ecsEntity")
local Events = require("lib/events")

local SlimeECS = setmetatable({}, {__index = ECSEntity})
SlimeECS.__index = SlimeECS

function SlimeECS:new(x, y, platform)
    -- Create with ECSEntity first
    local self = ECSEntity:new(x, y, 32, 20, {
        type = "enemy",
        collisionLayer = "enemy",
        collidesWithLayers = {"player"},
    })
    
    -- Now set metatable to SlimeECS
    setmetatable(self, SlimeECS)
    
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
    self.dripTimer = love.math.random(1, 3)
    
    -- Add slime-specific components to ECS entity if available
    if self.ecsEntity then
        -- Add renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "custom",
            layer = 10,
            drawFunction = function(entity)
                -- This will be handled by the draw method
            end
        })
        
        -- Add slime component
        self.ecsEntity:addComponent("slime", {
            platform = platform,
            patrolSpeed = self.patrolSpeed,
            gravityValue = self.gravityValue,
            state = self.state,
            direction = self.direction,
            directionChangeTimer = self.directionChangeTimer,
            stunnedTime = self.stunnedTime,
            stunnedDuration = self.stunnedDuration,
            detectionRadius = self.detectionRadius,
            aggro = self.aggro,
            squishFactor = self.squishFactor,
            squishDirection = self.squishDirection,
            colorPulse = self.colorPulse,
            colorPulseDirection = self.colorPulseDirection,
            dripTimer = self.dripTimer
        })
        
        -- Add AI component
        self.ecsEntity:addComponent("ai", {
            type = "slime",
            state = self.state,
            targetType = "player",
            detectionRadius = self.detectionRadius
        })
    end
    
    return self
end

function SlimeECS:update(dt)
    -- If we have an ECS entity, sync with it
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        
        -- Update our local properties from the ECS entity
        self.state = slime.state
        self.direction = slime.direction
        self.directionChangeTimer = slime.directionChangeTimer
        self.stunnedTime = slime.stunnedTime
        self.aggro = slime.aggro
        self.squishFactor = slime.squishFactor
        self.squishDirection = slime.squishDirection
        self.colorPulse = slime.colorPulse
        self.colorPulseDirection = slime.colorPulseDirection
        self.dripTimer = slime.dripTimer
        
        -- Call parent update to sync position and velocity
        ECSEntity.update(self, dt)
        
        return
    end
    
    -- Legacy update if no ECS entity
    
    -- Update based on current state
    if self.state == "patrolling" then
        self:updatePatrolling(dt)
    elseif self.state == "stunned" then
        self:updateStunned(dt)
    end
    
    -- Update animation
    self:updateAnimation(dt)
    
    -- Update drip effect
    self:updateDripEffect(dt)
    
    -- Call parent update to apply velocity and position
    ECSEntity.update(self, dt)
end

function SlimeECS:updatePatrolling(dt)
    -- Move in current direction
    self.velocity.x = self.patrolSpeed * self.direction
    
    -- Check if we need to change direction
    self.directionChangeTimer = self.directionChangeTimer - dt
    if self.directionChangeTimer <= 0 then
        self.direction = -self.direction
        self.directionChangeTimer = love.math.random(2, 5)
    end
    
    -- Stay on platform
    if self.platform then
        if self.x < self.platform.x then
            self.x = self.platform.x
            self.direction = 1
        elseif self.x + self.width > self.platform.x + self.platform.width then
            self.x = self.platform.x + self.platform.width - self.width
            self.direction = -1
        end
    end
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        slime.direction = self.direction
        slime.directionChangeTimer = self.directionChangeTimer
    end
end

function SlimeECS:updateStunned(dt)
    -- Apply gravity when stunned
    self.velocity.y = self.velocity.y + self.gravityValue * dt
    
    -- Reduce stunned time
    self.stunnedTime = self.stunnedTime - dt
    if self.stunnedTime <= 0 then
        self.state = "patrolling"
        self.velocity.y = 0
    end
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        slime.state = self.state
        slime.stunnedTime = self.stunnedTime
    end
end

function SlimeECS:updateAnimation(dt)
    -- Update squish animation
    if self.squishDirection ~= 0 then
        self.squishFactor = self.squishFactor + self.squishDirection * dt * 2
        
        -- Limit squish factor
        if self.squishFactor > 1.2 then
            self.squishFactor = 1.2
            self.squishDirection = -1
        elseif self.squishFactor < 0.8 then
            self.squishFactor = 0.8
            self.squishDirection = 1
        end
    end
    
    -- Update color pulse
    self.colorPulse = self.colorPulse + self.colorPulseDirection * dt
    if self.colorPulse > 1 then
        self.colorPulse = 1
        self.colorPulseDirection = -1
    elseif self.colorPulse < 0 then
        self.colorPulse = 0
        self.colorPulseDirection = 1
    end
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        slime.squishFactor = self.squishFactor
        slime.squishDirection = self.squishDirection
        slime.colorPulse = self.colorPulse
        slime.colorPulseDirection = self.colorPulseDirection
    end
end

function SlimeECS:updateDripEffect(dt)
    -- Update drip timer
    self.dripTimer = self.dripTimer - dt
    if self.dripTimer <= 0 then
        -- Reset timer
        self.dripTimer = love.math.random(1, 3)
        
        -- Create drip effect
        -- This would typically create a particle, but we'll skip that for now
    end
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        slime.dripTimer = self.dripTimer
    end
end

function SlimeECS:draw()
    if not self.active then return end
    
    -- Base color (green for slime)
    local r, g, b = 0.2, 0.8, 0.2
    
    -- Adjust color based on state
    if self.state == "stunned" then
        -- Stunned slimes are more pale
        r, g, b = 0.5, 0.8, 0.5
    elseif self.aggro then
        -- Aggro slimes are more red
        r, g, b = 0.8, 0.5, 0.2
    end
    
    -- Apply color pulse
    r = r + self.colorPulse * 0.2
    g = g + self.colorPulse * 0.2
    b = b + self.colorPulse * 0.2
    
    -- Draw slime body
    love.graphics.setColor(r, g, b)
    
    -- Apply squish factor to drawing
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local drawWidth = self.width * self.squishFactor
    local drawHeight = self.height / self.squishFactor
    
    love.graphics.ellipse("fill", 
        centerX, 
        centerY, 
        drawWidth/2, 
        drawHeight/2
    )
    
    -- Draw eyes
    love.graphics.setColor(1, 1, 1)
    local eyeSize = self.width * 0.15
    local eyeY = centerY - eyeSize/2
    
    -- Left eye
    local leftEyeX = centerX - self.width * 0.2
    love.graphics.circle("fill", leftEyeX, eyeY, eyeSize)
    
    -- Right eye
    local rightEyeX = centerX + self.width * 0.2
    love.graphics.circle("fill", rightEyeX, eyeY, eyeSize)
    
    -- Draw pupils (looking in direction of movement)
    love.graphics.setColor(0, 0, 0)
    local pupilSize = eyeSize * 0.6
    local pupilOffset = self.direction * eyeSize * 0.3
    
    love.graphics.circle("fill", leftEyeX + pupilOffset, eyeY, pupilSize)
    love.graphics.circle("fill", rightEyeX + pupilOffset, eyeY, pupilSize)
    
    -- Draw mouth
    local mouthWidth = self.width * 0.4
    local mouthHeight = self.height * 0.1
    local mouthY = centerY + self.height * 0.1
    
    if self.state == "stunned" then
        -- X mouth when stunned
        love.graphics.setLineWidth(2)
        love.graphics.line(
            centerX - mouthWidth/2, mouthY - mouthHeight/2,
            centerX + mouthWidth/2, mouthY + mouthHeight/2
        )
        love.graphics.line(
            centerX - mouthWidth/2, mouthY + mouthHeight/2,
            centerX + mouthWidth/2, mouthY - mouthHeight/2
        )
        love.graphics.setLineWidth(1)
    else
        -- Smile or frown based on aggro
        local mouthCurve = self.aggro and -0.5 or 0.5
        
        love.graphics.arc(
            "line",
            centerX,
            mouthY,
            mouthWidth/2,
            0,
            math.pi,
            20
        )
    end
    
    -- Debug draw collision bounds if needed
    if self.debug then
        local bounds = self:getBounds()
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.width, bounds.height)
    end
end

function SlimeECS:onCollision(other, collisionData)
    -- Handle collision with player
    if other.type == "player" then
        -- Check if player is attacking from above
        if collisionData.fromAbove and other.velocity.y > 0 then
            -- Player jumped on slime, stun it
            self.state = "stunned"
            self.stunnedTime = self.stunnedDuration
            self.velocity.y = -200 -- Bounce up when stunned
            
            -- Update ECS entity if available
            if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
                local slime = self.ecsEntity:getComponent("slime")
                slime.state = self.state
                slime.stunnedTime = self.stunnedTime
            end
            
            -- Fire event for player to handle bounce
            Events.fire("enemyBounce", {
                enemy = self,
                player = other
            })
            
            return true
        else
            -- Player collided with slime from side or below, hurt player
            Events.fire("enemyCollision", {
                enemy = self,
                player = other,
                collisionData = collisionData
            })
            
            return true
        end
    end
    
    -- Let parent handle other collisions
    return ECSEntity.onCollision(self, other, collisionData)
end

function SlimeECS:setAggro(value)
    self.aggro = value
    
    -- Start squishing when aggro changes
    if self.squishDirection == 0 then
        self.squishDirection = 1
    end
    
    -- Update ECS entity if available
    if self.ecsEntity and self.ecsEntity:hasComponent("slime") then
        local slime = self.ecsEntity:getComponent("slime")
        slime.aggro = self.aggro
        slime.squishDirection = self.squishDirection
    end
end

-- Destroy the slime
function SlimeECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to slimes
    self.active = false
end

return SlimeECS 