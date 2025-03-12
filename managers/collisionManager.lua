-- collisionManager.lua - Collision handling for Love2D Vertical Jumper

local Events = require('lib/events')
local CollisionManager = {}
CollisionManager.__index = CollisionManager

function CollisionManager:new(player, platforms, springboards, particleManager, xpManager)
    local self = setmetatable({}, CollisionManager)
    
    self.player = player
    self.platforms = platforms
    self.springboards = springboards
    self.particleManager = particleManager
    self.xpManager = xpManager
    return self
end

-- Check if two objects overlap
function CollisionManager:checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end
function CollisionManager:handleXpCollisions()
    if not self.xpManager then return 0 end
    
    local playerBounds = self.player:getBounds()
    local totalXp = 0
    
    -- Get player center
    local playerCenterX = playerBounds.x + playerBounds.width/2
    local playerCenterY = playerBounds.y + playerBounds.height/2
    
    -- Collection radius (can be modified by powerups)
    local collectionRadius = 75 + (self.xpManager.collectionRadiusBonus or 0)
    
    -- Check each pellet
    local pellets = self.xpManager.pellets
    for i = #pellets, 1, -1 do
        local pellet = pellets[i]
        if pellet.active and pellet.collectible then
            -- Get pellet center
            local pelletBounds = pellet:getBounds()
            local pelletCenterX = pelletBounds.x + pelletBounds.width/2
            local pelletCenterY = pelletBounds.y + pelletBounds.height/2
            
            -- Calculate distance between centers
            local dx = playerCenterX - pelletCenterX
            local dy = playerCenterY - pelletCenterY
            local distance = math.sqrt(dx*dx + dy*dy)
            
            -- Check if within collection radius
            if distance < collectionRadius then
                -- Collect the pellet
                local xpValue = pellet:collect()
                totalXp = totalXp + xpValue
                table.remove(pellets, i)
            elseif distance < collectionRadius * 2 then
                -- Attract the pellet towards the player
                local nx = dx / distance
                local ny = dy / distance
                
                -- Movement speed based on distance (faster when closer)
                local speed = 400 * (1 - distance/collectionRadius/2)
                
                -- Move pellet towards player
                pellet.x = pellet.x + nx * speed * love.timer.getDelta()
                pellet.y = pellet.y + ny * speed * love.timer.getDelta()
            end
        end
    end
    
    return totalXp
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

    -- Handle XP pellet collisions and return collected XP
    local collectedXp = self:handleXpCollisions()
    if collectedXp > 0 then
        print(collectedXp)
        self.player:addExperience(collectedXp)
    end
end

function CollisionManager:updatePlayerGroundState(playerHitPlatform, wasOnGround)
    if playerHitPlatform and not wasOnGround then
        -- Player just landed on a platform
        self.player:landOnGround()
        
    elseif wasOnGround and not playerHitPlatform then
        -- Player just left the ground
        self.player:leftGround()
    end
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
                    return true
                end
            end
        end
    end
    return false
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
