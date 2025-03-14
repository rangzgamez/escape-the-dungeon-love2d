-- batECS.lua - Bat enemy for Love2D Vertical Jumper (ECS version)
local ECSEntity = require("entities/ecsEntity")
local Events = require("lib/events")

local BatECS = setmetatable({}, {__index = ECSEntity})
BatECS.__index = BatECS

function BatECS:new(x, y)
    -- Create with ECSEntity first
    local self = ECSEntity.new(x, y, 24, 24, {
        type = "enemy",
        collisionLayer = "enemy",
        collidesWithLayers = {"player"},
        isSolid = false,
        color = {0.4, 0.2, 0.4, 1} -- Purple-ish color
    })
    
    -- Now set metatable to BatECS
    setmetatable(self, BatECS)
    
    -- Store bat-specific properties
    self.radius = 12 -- Main body radius
    
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
    
    -- Add bat-specific components to ECS entity if available
    if self.ecsEntity then
        -- Add renderer component
        self.ecsEntity:addComponent("renderer", {
            type = "custom",
            layer = 10,
            drawFunction = function(entity)
                -- This will be handled by the draw method
            end
        })
        
        -- Add bat component
        self.ecsEntity:addComponent("bat", {
            radius = self.radius,
            speed = self.speed,
            maxSpeed = self.maxSpeed,
            detectionRadius = self.detectionRadius,
            wingAngle = self.wingAngle,
            wingSpeed = self.wingSpeed,
            wingDirection = self.wingDirection,
            maxWingAngle = self.maxWingAngle,
            state = self.state,
            stunnedTime = self.stunnedTime,
            stunnedDuration = self.stunnedDuration,
            patrolTimer = self.patrolTimer,
            patrolDirection = self.patrolDirection,
            patrolDuration = self.patrolDuration
        })
        
        -- Add physics component with flying properties
        self.ecsEntity:addComponent("physics", {
            velocity = {x = 0, y = 0},
            acceleration = {x = 0, y = 0},
            gravity = 0, -- No gravity for flying bats
            friction = 0.1,
            mass = 1,
            affectedByGravity = false -- Bats fly, not affected by gravity unless stunned
        })
        
        -- Add AI component
        self.ecsEntity:addComponent("ai", {
            type = "bat",
            state = self.state,
            targetType = "player",
            detectionRadius = self.detectionRadius
        })
        
        -- Add enemy component
        self.ecsEntity:addComponent("enemy", {
            health = 1,
            damage = 1,
            flying = true,
            value = 5 -- XP value when defeated
        })
    end
    
    return self
end

function BatECS:update(dt)
    -- If we have an ECS entity, sync with it
    if self.ecsEntity then
        -- Sync position from ECS entity
        local transform = self.ecsEntity:getComponent("transform")
        if transform and transform.position then
            self.x = transform.position.x
            self.y = transform.position.y
        end
        
        -- Sync bat properties from ECS entity
        local bat = self.ecsEntity:getComponent("bat")
        if bat then
            self.state = bat.state
            self.wingAngle = bat.wingAngle
            self.wingDirection = bat.wingDirection
            self.stunnedTime = bat.stunnedTime
        end
        
        -- Update wing animation
        self:updateWings(dt)
        
        -- Update ECS components based on state
        self:updateECSComponents(dt)
    else
        -- Legacy update if no ECS entity
        self:legacyUpdate(dt)
    end
end

function BatECS:updateECSComponents(dt)
    if not self.ecsEntity then return end
    
    local bat = self.ecsEntity:getComponent("bat")
    local physics = self.ecsEntity:getComponent("physics")
    local ai = self.ecsEntity:getComponent("ai")
    
    if not bat or not physics or not ai then return end
    
    -- Update wing animation in bat component
    bat.wingAngle = self.wingAngle
    bat.wingDirection = self.wingDirection
    
    -- Update state based on AI
    if bat.state == "stunned" then
        -- When stunned, enable gravity
        physics.affectedByGravity = true
        physics.gravity = 800
        
        -- Decrease stunned time
        bat.stunnedTime = bat.stunnedTime - dt
        
        -- Recover from stunned state
        if bat.stunnedTime <= 0 then
            bat.state = "idle"
            physics.affectedByGravity = false
            physics.gravity = 0
            physics.velocity.x = 0
            physics.velocity.y = 0
        end
    else
        -- Not stunned, so no gravity
        physics.affectedByGravity = false
        physics.gravity = 0
        
        -- Update patrol timer
        if bat.state == "idle" then
            bat.patrolTimer = bat.patrolTimer + dt
            
            -- Change direction periodically
            if bat.patrolTimer >= bat.patrolDuration then
                bat.patrolTimer = 0
                bat.patrolDuration = love.math.random(1, 3)
                bat.patrolDirection.x = love.math.random(-1, 1)
                bat.patrolDirection.y = love.math.random(-1, 1)
            end
            
            -- Set patrol velocity (slower than chase)
            physics.velocity.x = bat.patrolDirection.x * bat.speed * 0.5
            physics.velocity.y = bat.patrolDirection.y * bat.speed * 0.5
            
            -- Normal wing speed during patrol
            bat.wingSpeed = 10
        end
    end
    
    -- Update AI component
    ai.state = bat.state
end

function BatECS:legacyUpdate(dt, player)
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
    
    -- Apply velocity
    self.x = self.x + self.velocity.x * dt
    self.y = self.y + self.velocity.y * dt
end

function BatECS:updateWings(dt)
    -- Update wing flapping animation
    self.wingAngle = self.wingAngle + self.wingSpeed * self.wingDirection * dt
    
    -- Reverse direction when reaching max angle
    if self.wingAngle >= self.maxWingAngle then
        self.wingDirection = -1
    elseif self.wingAngle <= -self.maxWingAngle then
        self.wingDirection = 1
    end
end

function BatECS:stun()
    if self.ecsEntity then
        local bat = self.ecsEntity:getComponent("bat")
        local physics = self.ecsEntity:getComponent("physics")
        
        if bat and physics then
            bat.state = "stunned"
            bat.stunnedTime = bat.stunnedDuration
            
            -- Bounce effect when stunned
            physics.velocity.y = -300
            physics.velocity.x = love.math.random(-100, 100)
            physics.affectedByGravity = true
            physics.gravity = 800
        end
    else
        -- Legacy stun
        self.state = "stunned"
        self.stunnedTime = self.stunnedDuration
        self.velocity.y = -300
        self.velocity.x = love.math.random(-100, 100)
    end
    
    -- Fire event
    Events.fire("enemyStunned", {entity = self})
end

function BatECS:onCollision(other, collisionData)
    -- Call parent onCollision method
    ECSEntity.onCollision(self, other, collisionData)
    
    -- Handle collision with player
    if other.type == "player" then
        local playerVelocity = {x = 0, y = 0}
        
        -- Get player velocity
        if other.ecsEntity then
            local physics = other.ecsEntity:getComponent("physics")
            if physics then
                playerVelocity = physics.velocity
            end
        elseif other.velocity then
            playerVelocity = other.velocity
        end
        
        -- If player is falling onto bat, stun the bat
        if playerVelocity.y > 0 then
            self:stun()
            
            -- Bounce player
            if other.bounce then
                other:bounce()
            end
            
            -- Fire event
            Events.fire("enemyHit", {
                enemy = self,
                player = other,
                damage = 0
            })
        else
            -- Otherwise damage player
            if other.takeDamage then
                other:takeDamage(1, self)
            end
            
            -- Fire event
            Events.fire("playerHit", {
                player = other,
                source = self,
                damage = 1
            })
        end
    end
end

function BatECS:draw()
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

function BatECS:drawBatBody(upsideDown)
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

-- Destroy the bat
function BatECS:destroy()
    -- Call parent destroy method
    ECSEntity.destroy(self)
    
    -- Additional cleanup specific to bats
    self.active = false
end

return BatECS 