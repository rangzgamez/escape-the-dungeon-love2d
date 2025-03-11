-- collisionManager.lua - Collision handling for Love2D Vertical Jumper

local Events = require('lib/events')
local CollisionManager = {}
CollisionManager.__index = CollisionManager

function CollisionManager:new(player, platforms, springboards, particleManager)
    local self = setmetatable({}, CollisionManager)
    
    self.player = player
    self.platforms = platforms
    self.springboards = springboards
    self.particleManager = particleManager
    
    return self
end

-- Check if two objects overlap
function CollisionManager:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

-- Check if player is colliding with platforms and springboards
function CollisionManager:handleCollisions(dt)
    local wasOnGround = self.player.onGround
    local playerHitPlatform = false
    
    -- Store player's position before movement
    local prevX = self.player.x - self.player.xVelocity * dt
    local prevY = self.player.y - self.player.yVelocity * dt
    
    -- Check platform collisions
    playerHitPlatform = self:checkPlatformCollisions(dt, prevX, prevY)
    
    -- Handle player ground state based on collision results
    self:updatePlayerGroundState(playerHitPlatform, wasOnGround)
    
    -- Handle springboard collisions separately
    self:handleSpringboardCollisions(dt, prevX, prevY)
end

function CollisionManager:checkPlatformCollisions(dt, prevX, prevY)
    -- Calculate player movement speed
    local playerSpeed = math.sqrt(self.player.xVelocity^2 + self.player.yVelocity^2)
    local minDimension = math.min(self.player.width, self.player.height) / 2
    
    -- Determine if we need substeps based on speed
    if playerSpeed * dt <= minDimension then
        -- Low speed - use simple collision check
        return self:simplePlatformCollision(prevY)
    else
        -- High speed - use continuous collision detection
        return self:continuousPlatformCollision(dt, prevX, prevY, playerSpeed, minDimension)
    end
end

function CollisionManager:simplePlatformCollision(prevY)
    for _, platform in ipairs(self.platforms) do
        if self:checkCollision(self.player, platform) then
            -- Only check for collision from above (one-way platforms)
            if prevY + self.player.height <= platform.y and self.player.yVelocity >= 0 then
                self.player.y = platform.y - self.player.height
                self.player.yVelocity = 0
                self.player.onGround = true
                return true
            end
        end
    end
    return false
end

function CollisionManager:continuousPlatformCollision(dt, prevX, prevY, playerSpeed, minDimension)
    -- Calculate number of steps needed based on speed
    local steps = math.ceil(playerSpeed * dt / minDimension)
    steps = math.min(steps, 10) -- Cap at 10 steps to prevent performance issues
    
    local stepX = self.player.xVelocity * dt / steps
    local stepY = self.player.yVelocity * dt / steps
    
    -- Create a test player for collision checks
    local testPlayer = {
        width = self.player.width,
        height = self.player.height
    }
    
    -- Check collision at each step
    for i = 1, steps do
        testPlayer.x = prevX + stepX * i
        testPlayer.y = prevY + stepY * i
        
        for _, platform in ipairs(self.platforms) do
            if self:checkCollision(testPlayer, platform) then
                -- Only check for collision from above (one-way platforms)
                if prevY + self.player.height <= platform.y then
                    self.player.y = platform.y - self.player.height
                    self.player.yVelocity = 0
                    self.player.onGround = true
                    return true
                end
            end
        end
    end
    return false
end

function CollisionManager:updatePlayerGroundState(playerHitPlatform, wasOnGround)
    if playerHitPlatform and not wasOnGround then
        -- Player just landed on a platform
        self.player:landOnGround()
        
        -- Fire landed event (for particles etc)
        Events.fire("playerLanded", {
            x = self.player.x,
            y = self.player.y
        })
    elseif wasOnGround and not playerHitPlatform then
        -- Player just left the ground
        self.player.onGround = false
        self.player:leftGround()
    end
end
function CollisionManager:handleSpringboardCollisions(dt, prevX, prevY)
    -- Calculate player movement speed
    local playerSpeed = math.sqrt(self.player.xVelocity^2 + self.player.yVelocity^2)
    local minDimension = math.min(self.player.width, self.player.height) / 2
    
    -- Determine collision check method based on speed
    if playerSpeed * dt <= minDimension then
        -- Simple collision for low speeds
        self:simpleSpringboardCollision(prevY)
    else
        -- Continuous collision for high speeds
        self:continuousSpringboardCollision(dt, prevX, prevY, playerSpeed, minDimension)
    end
end

function CollisionManager:simpleSpringboardCollision(prevY)
    for _, spring in ipairs(self.springboards) do
        if self:checkCollision(self.player, spring) then
            -- Only apply springboard if coming from above
            if prevY + self.player.height <= spring.y and self.player.yVelocity >= 0 then
                self:applySpringboardEffect(spring)
                return true
            end
        end
    end
    return false
end

function CollisionManager:continuousSpringboardCollision(dt, prevX, prevY, playerSpeed, minDimension)
    -- Calculate number of steps needed based on speed
    local steps = math.ceil(playerSpeed * dt / minDimension)
    steps = math.min(steps, 10) -- Cap at 10 steps
    
    local stepX = self.player.xVelocity * dt / steps
    local stepY = self.player.yVelocity * dt / steps
    
    -- Create a test player for collision checks
    local testPlayer = {
        width = self.player.width,
        height = self.player.height
    }
    
    -- Check collision at each step
    for i = 1, steps do
        testPlayer.x = prevX + stepX * i
        testPlayer.y = prevY + stepY * i
        
        for _, spring in ipairs(self.springboards) do
            if self:checkCollision(testPlayer, spring) then
                -- Only apply springboard if coming from above
                if prevY + self.player.height <= spring.y then
                    self:applySpringboardEffect(spring)
                    return true
                end
            end
        end
    end
    return false
end

function CollisionManager:applySpringboardEffect(spring)
    -- Apply springboard effect
    self.player.y = spring.y - self.player.height
    self.player.yVelocity = -self.player.springJumpStrength
    spring:activate()
    
    -- Reset midair jumps when hitting a springboard
    self.player.midairJumps = self.player.maxMidairJumps
    
    -- Fire springboard jump event
    Events.fire("playerSpringboardJump", {
        x = self.player.x + self.player.width/2,
        y = self.player.y
    })
end
return CollisionManager
