-- bat.lua - Bat enemy for Love2D Vertical Jumper
local BaseEntity = require("entities/baseEntity")

local Bat = setmetatable({}, {__index = BaseEntity})
Bat.__index = Bat

function Bat:new(x, y)
    local self = BaseEntity:new(x, y, 24, 24, {
        type = "enemy",
        collisionLayer = "enemy",
        collidesWithLayers = {"player"},
    })
    setmetatable(self, Bat)

    self.radius = 12 -- Main body radius
    self.width = self.radius * 2 -- For collision detection
    self.height = self.radius * 2 -- For collision detection
    
    -- Movement properties
    self.speed = 70 -- Slower to give player time to react
    self.maxSpeed = 120 -- Maximum speed when chasing
    self.detectionRadius = 200 -- How far the bat can "see" the player
    -- Animation properties
    self.wingAngle = 0
    self.wingSpeed = 10 -- Wing flap speed
    self.wingDirection = 1 -- 1 for flapping up, -1 for flapping down
    self.maxWingAngle = math.pi / 4 -- 45 degrees max wing angle
    
    -- Behavior
    self.state = "idle" -- idle, chase, stunned
    self.stunnedTime = 0
    self.stunnedDuration = 2 -- How long bat stays stunned when hit
    
    -- Movement pattern
    self.patrolTimer = 0
    self.patrolDirection = {x = love.math.random(-1, 1), y = love.math.random(-1, 1)}
    self.patrolDuration = love.math.random(1, 3) -- Random patrol time
    return self
end

function Bat:update(dt, player)
    -- Skip update if not active
    if not self.active then return end
    
    -- Update wing animation
    self:updateWings(dt)
    
    -- State machine for bat behavior
    if self.state == "stunned" then
        self:updateStunned(dt)
    elseif self:canDetectPlayer(player) then
        self.state = "chase"
        self:chasePlayer(dt, player)
    else
        self.state = "idle"
        self:patrol(dt)
    end
    
    -- Apply velocity (but don't call BaseEntity.update since we handle physics ourselves)
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
end

function Bat:updateStunned(dt)
    self.stunnedTime = self.stunnedTime - dt
    -- Apply gravity when stunned
    self.velocity.y = self.velocity.y + 800 * dt
    
    -- Recover from stunned state
    if self.stunnedTime <= 0 then
        self.state = "idle"
        -- Reset velocity when recovering
        self.velocity.x = 0
        self.velocity.y = 0
    end
end

function Bat:updateWings(dt)
    -- Update wing flapping animation
    self.wingAngle = self.wingAngle + self.wingSpeed * self.wingDirection * dt
    
    -- Reverse direction when reaching max angle
    if self.wingAngle >= self.maxWingAngle then
        self.wingDirection = -1
    elseif self.wingAngle <= -self.maxWingAngle then
        self.wingDirection = 1
    end
end

function Bat:canDetectPlayer(player)
    -- Calculate distance to player
    local dx = player.x + player.width/2 - (self.x + self.radius)
    local dy = player.y + player.height/2 - (self.y + self.radius)
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Return true if player is within detection radius
    return distance <= self.detectionRadius
end

function Bat:chasePlayer(dt, player)
    -- Get direction to player
    local dx = player.x + player.width/2 - (self.x + self.radius)
    local dy = player.y + player.height/2 - (self.y + self.radius)
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Normalize direction
    if distance > 0 then
        dx = dx / distance
        dy = dy / distance
    end
    
    -- Adjust speed based on distance (faster when closer)
    local chaseSpeed = self.speed + (self.maxSpeed - self.speed) * 
                      (1 - math.min(distance, self.detectionRadius) / self.detectionRadius)
    
    -- Set velocity towards player
    self.velocity.x = dx * chaseSpeed
    self.velocity.y = dy * chaseSpeed
    
    -- Increase wing speed during chase
    self.wingSpeed = 15
end

function Bat:patrol(dt)
    -- Update patrol timer
    self.patrolTimer = self.patrolTimer + dt
    
    -- Change direction periodically
    if self.patrolTimer >= self.patrolDuration then
        self.patrolTimer = 0
        self.patrolDuration = love.math.random(1, 3)
        self.patrolDirection.x = love.math.random(-1, 1)
        self.patrolDirection.y = love.math.random(-1, 1)
    end
    
    -- Set patrol velocity (slower than chase)
    self.velocity.x = self.patrolDirection.x * self.speed * 0.5
    self.velocity.y = self.patrolDirection.y * self.speed * 0.5
    
    -- Normal wing speed during patrol
    self.wingSpeed = 10
end

function Bat:stun()
    self.state = "stunned"
    self.stunnedTime = self.stunnedDuration
    -- Bounce effect when stunned
    self.velocity.y = -300
    self.velocity.x = love.math.random(-100, 100)
end

function Bat:draw()
    if self.state == "stunned" then
        -- Draw stunned bat (upside down)
        love.graphics.setColor(0.7, 0.7, 0.7) -- Grayish when stunned
        self:drawBatBody(true) -- true for upside down
    else
        -- Draw normal bat
        love.graphics.setColor(0.4, 0.2, 0.4) -- Purple-ish color
        self:drawBatBody(false)
    end
end

function Bat:drawBatBody(upsideDown)
    -- Draw main body (circle)
    love.graphics.circle("fill", self.x + self.radius, self.y + self.radius, self.radius)
    
    -- Draw eyes (small white circles)
    love.graphics.setColor(1, 1, 1)
    local eyeSize = self.radius * 0.3
    local eyeOffset = self.radius * 0.4
    
    -- Position eyes based on whether bat is upside down
    if upsideDown then
        -- Upside down eyes
        love.graphics.circle("fill", self.x + self.radius - eyeOffset, self.y + self.radius + eyeOffset, eyeSize)
        love.graphics.circle("fill", self.x + self.radius + eyeOffset, self.y + self.radius + eyeOffset, eyeSize)
    else
        -- Normal eyes
        love.graphics.circle("fill", self.x + self.radius - eyeOffset, self.y + self.radius - eyeOffset, eyeSize)
        love.graphics.circle("fill", self.x + self.radius + eyeOffset, self.y + self.radius - eyeOffset, eyeSize)
    end
    
    -- Draw pupils (small black dots in eyes)
    love.graphics.setColor(0, 0, 0)
    local pupilSize = eyeSize * 0.5
    if upsideDown then
        love.graphics.circle("fill", self.x + self.radius - eyeOffset, self.y + self.radius + eyeOffset, pupilSize)
        love.graphics.circle("fill", self.x + self.radius + eyeOffset, self.y + self.radius + eyeOffset, pupilSize)
    else
        love.graphics.circle("fill", self.x + self.radius - eyeOffset, self.y + self.radius - eyeOffset, pupilSize)
        love.graphics.circle("fill", self.x + self.radius + eyeOffset, self.y + self.radius - eyeOffset, pupilSize)
    end
    
    -- Set color for wings
    if upsideDown then
        love.graphics.setColor(0.5, 0.5, 0.5) -- Gray wings when stunned
    else
        love.graphics.setColor(0.3, 0.1, 0.3) -- Dark purple wings
    end
    
    -- Define wing properties with consistent scaling
    local wingLength = self.radius * 2 -- Define consistent wing length based on radius
    local wingHeight = self.radius * 0.7 -- Define wing height
    local centerY = self.y + self.radius
    
    -- Calculate wing positions based on angle and use wingLength consistently
    local leftWingX = self.x - wingLength * math.cos(self.wingAngle)
    local rightWingX = self.x + self.radius * 2 + wingLength * math.cos(self.wingAngle)
    
    -- Adjust wing offset for upside down
    local wingVerticalOffset = upsideDown and self.radius/2 or -self.radius/2
    
    -- Draw left wing
    love.graphics.polygon("fill", 
        self.x, centerY + wingVerticalOffset/2, -- Inner point (left edge of bat)
        leftWingX, centerY + wingVerticalOffset, -- Outer point
        self.x, self.y + self.radius * 2  -- Bottom point
    )
    
    -- Draw right wing
    love.graphics.polygon("fill", 
        self.x + self.radius * 2, centerY + wingVerticalOffset/2, -- Inner point (right edge of bat)
        rightWingX, centerY + wingVerticalOffset, -- Outer point
        self.x + self.radius * 2, self.y + self.radius * 2  -- Bottom point
    )
end


return Bat