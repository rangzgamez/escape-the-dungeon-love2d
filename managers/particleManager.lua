-- particleManager.lua - Particle system manager for Love2D Vertical Jumper

local ParticleManager = {}
ParticleManager.__index = ParticleManager

function ParticleManager:new()
    local self = setmetatable({}, ParticleManager)
    
    self.particleSystems = {}
    
    -- Create a small canvas for dust particles
    self.dustCanvas = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(self.dustCanvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 4, 4)
    love.graphics.setCanvas()
    
    return self
end

function ParticleManager:createDustEffect(x, y, height)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    -- Create a new particle system
    local dust = love.graphics.newParticleSystem(self.dustCanvas, 50)
    -- Set particle properties
    dust:setParticleLifetime(0.2, 0.8)
    dust:setEmissionRate(200)
    dust:setSizeVariation(1)
    dust:setLinearAcceleration(-20, -30, 20, -10)
    dust:setColors(0.8, 0.8, 0.7, 1, 0.8, 0.8, 0.7, 0)
    dust:setSizes(1, 3, 2)
    dust:setPosition(x, y + height)
    dust:setSpread(math.pi/4)
    -- Emit particles
    dust:emit(20)
    -- Store the system with timer info
    table.insert(self.particleSystems, {
        system = dust,
        timer = 1  -- How long to keep this particle system
    })
end

function ParticleManager:createDashEffect(player, direction)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    local x = player.x + player.width/2
    local y = player.y + player.height/2
    
    -- Create a new particle system
    local dust = love.graphics.newParticleSystem(self.dustCanvas, 50)
    -- Set particle properties
    dust:setParticleLifetime(0.1, 0.4)
    dust:setEmissionRate(100)
    dust:setSizeVariation(1)
    
    -- Set direction based on player's dash direction
    if direction > 0 then
        dust:setLinearAcceleration(-80, -10, -40, 10)
        dust:setPosition(x - 10, y)
    else
        dust:setLinearAcceleration(40, -10, 80, 10)
        dust:setPosition(x + 10, y)
    end
    
    dust:setColors(1, 0.8, 0.2, 1, 1, 0.5, 0.1, 0)
    dust:setSizes(2, 3, 1)
    dust:setSpread(math.pi/6)
    dust:emit(15)
    
    -- Store the system with timer info
    table.insert(self.particleSystems, {
        system = dust,
        timer = 0.5
    })
end

function ParticleManager:createDoubleJumpEffect(player)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    local x = player.x + player.width/2
    local y = player.y + player.height
    
    -- Create a new particle system
    local dust = love.graphics.newParticleSystem(self.dustCanvas, 50)
    -- Set particle properties for double jump effect
    dust:setParticleLifetime(0.2, 0.6)
    dust:setEmissionRate(150)
    dust:setSizeVariation(1)
    dust:setLinearAcceleration(-40, 10, 40, 50)
    dust:setColors(0.3, 0.5, 1, 1, 0.5, 0.7, 1, 0)  -- Blue-tinted particles
    dust:setSizes(2, 3, 1)
    dust:setPosition(x, y)
    dust:setSpread(math.pi)  -- Full circle spread
    dust:emit(25)
    
    -- Store the system with timer info
    table.insert(self.particleSystems, {
        system = dust,
        timer = 0.8
    })
end

function ParticleManager:update(dt)
    -- Update particle systems
    for i = #self.particleSystems, 1, -1 do
        local p = self.particleSystems[i]
        p.system:update(dt)
        
        -- Remove expired particle systems
        p.timer = p.timer - dt
        if p.timer <= 0 then
            table.remove(self.particleSystems, i)
        end
    end
end

function ParticleManager:draw()
    love.graphics.setColor(1, 1, 1)
    for _, p in ipairs(self.particleSystems) do
        love.graphics.draw(p.system)
    end
end

-- Add this function to particleManager.lua
function ParticleManager:createRefreshEffect(player)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    local x = player.x + player.width/2
    local y = player.y + player.height/2
    
    -- Create a new particle system
    local refresh = love.graphics.newParticleSystem(self.dustCanvas, 50)
    -- Set particle properties
    refresh:setParticleLifetime(0.2, 0.7)
    refresh:setEmissionRate(200)
    refresh:setSizeVariation(1)
    refresh:setLinearAcceleration(-100, -100, 100, 100)
    refresh:setColors(0, 1, 0.5, 1, 0, 1, 0.8, 0)  -- Cyan/teal particles
    refresh:setSizes(3, 4, 2)
    refresh:setPosition(x, y)
    refresh:setSpread(math.pi*2)  -- Full circle spread
    -- Emit particles
    refresh:emit(25)
    -- Store the system with timer info
    table.insert(self.particleSystems, {
        system = refresh,
        timer = 0.8  -- How long to keep this particle system
    })
end

function ParticleManager:createImpactEffect(x, y)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    -- Create a new particle system
    local impact = love.graphics.newParticleSystem(self.dustCanvas, 50)
    -- Set particle properties
    impact:setParticleLifetime(0.1, 0.3)
    impact:setEmissionRate(300)
    impact:setSizeVariation(1)
    impact:setLinearAcceleration(-80, -80, 80, 80)
    impact:setColors(1, 1, 0, 1, 1, 0.6, 0, 0)  -- Yellow to red particles
    impact:setSizes(3, 2, 1)
    impact:setPosition(x, y)
    impact:setSpread(math.pi*2)  -- Full 360 degree spread
    -- Emit particles
    impact:emit(30)
    -- Store the system with timer info
    table.insert(self.particleSystems, {
        system = impact,
        timer = 0.5  -- How long to keep this particle system
    })
end

function ParticleManager:createBurnEffect(x, y)
    -- Check if particles are disabled globally
    if _G.disableParticles then return end
    
    -- Check if the canvas exists
    if not self.dustCanvas then return end
    
    -- Create a new particle system
    local burn = love.graphics.newParticleSystem(self.dustCanvas, 100)
    
    -- Set particle properties for burning effect
    burn:setParticleLifetime(0.3, 1.2)
    burn:setEmissionRate(200)
    burn:setSizeVariation(1)
    burn:setLinearAcceleration(-50, -150, 50, -50) -- Particles go upward
    burn:setColors(
        1, 0.7, 0.1, 1,     -- Start as bright yellow/orange
        1, 0.3, 0, 0.8,     -- Fade to orange
        0.7, 0, 0, 0        -- End as dark red and fade out
    )
    burn:setSizes(3, 2, 1)   -- Start larger, end smaller
    burn:setPosition(x, y)
    burn:setSpread(math.pi*2) -- Full 360 degree spread
    
    -- Emit a burst of particles
    burn:emit(50)
    
    -- Store the system with a longer timer for burn effect
    table.insert(self.particleSystems, {
        system = burn,
        timer = 1.5
    })
end

return ParticleManager