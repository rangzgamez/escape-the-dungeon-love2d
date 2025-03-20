-- managers/particlePool.lua
-- Specialized object pool for particle effects

local ObjectPool = require("lib/objectPool")
local Events = require("lib/events")

local ParticlePool = {}
ParticlePool.__index = ParticlePool

-- Particle effect prototype
local ParticleEffect = {}
ParticleEffect.__index = ParticleEffect

-- Particle types/templates
local PARTICLE_TEMPLATES = {
    dust = {
        image = nil, -- Will be created on first use
        settings = {
            lifetime = {0.2, 0.8},
            emission = 20,
            size = {1, 3, 2},
            sizeVariation = 0.5,
            acceleration = {-20, -30, 20, -10},
            colors = {
                {0.8, 0.8, 0.7, 1},  -- Start color
                {0.8, 0.8, 0.7, 0}   -- End color
            },
            spread = math.pi/4
        }
    },
    
    dash = {
        image = nil,
        settings = {
            lifetime = {0.1, 0.4},
            emission = 30,
            size = {2, 3, 1},
            sizeVariation = 0.5,
            acceleration = {-80, -10, -40, 10},
            colors = {
                {1, 0.8, 0.2, 1},    -- Start color (yellow)
                {1, 0.5, 0.1, 0}     -- End color (orange)
            },
            spread = math.pi/6
        }
    },
    
    doubleJump = {
        image = nil,
        settings = {
            lifetime = {0.2, 0.6},
            emission = 25,
            size = {2, 3, 1},
            sizeVariation = 0.5,
            acceleration = {-40, 10, 40, 50},
            colors = {
                {0.3, 0.5, 1, 1},    -- Start color (blue)
                {0.5, 0.7, 1, 0}     -- End color (light blue)
            },
            spread = math.pi
        }
    },
    
    impact = {
        image = nil,
        settings = {
            lifetime = {0.1, 0.3},
            emission = 30,
            size = {3, 2, 1},
            sizeVariation = 0.5,
            acceleration = {-80, -80, 80, 80},
            colors = {
                {1, 1, 0, 1},        -- Start color (yellow)
                {1, 0.6, 0, 0}       -- End color (orange)
            },
            spread = math.pi*2
        }
    },
    
    refresh = {
        image = nil,
        settings = {
            lifetime = {0.2, 0.7},
            emission = 25,
            size = {3, 4, 2},
            sizeVariation = 0.5,
            acceleration = {-100, -100, 100, 100},
            colors = {
                {0, 1, 0.5, 1},      -- Start color (teal)
                {0, 1, 0.8, 0}       -- End color (cyan)
            },
            spread = math.pi*2
        }
    },
    
    burn = {
        image = nil,
        settings = {
            lifetime = {0.3, 1.2},
            emission = 50,
            size = {3, 2, 1},
            sizeVariation = 0.3,
            acceleration = {-50, -150, 50, -50},
            colors = {
                {1, 0.7, 0.1, 0.7},  -- Start color (yellow)
                {1, 0.3, 0, 0.3},    -- Mid color (orange)
                {0.7, 0, 0, 0}       -- End color (red)
            },
            spread = math.pi*2
        }
    },
    
    levelUp = {
        image = nil,
        settings = {
            lifetime = {0.5, 1.5},
            emission = 50,
            size = {2, 4, 1},
            sizeVariation = 0.5,
            acceleration = {-50, -50, 50, 50},
            colors = {
                {0.2, 0.8, 1, 1},    -- Start color (light blue)
                {0.4, 0.6, 1, 0},    -- End color (blue)
            },
            spread = math.pi*2
        }
    }
}

--[[
    Create a new particle effect object
    
    @return A new particle effect object
]]
function ParticleEffect:new()
    return setmetatable({
        x = 0,
        y = 0,
        system = nil,
        type = nil,
        active = false,
        duration = 0,
        timer = 0,
        autoRemove = false,
        additiveBlending = false
    }, ParticleEffect)
end

--[[
    Initialize the particle effect
    
    @param x - X position
    @param y - Y position
    @param type - Particle type (dust, dash, etc.)
    @param options - Additional options:
        - duration: How long the effect lasts (0 for infinite)
        - emitOnCreate: Whether to emit particles immediately
        - particleCount: How many particles to emit
        - autoRemove: Whether to automatically deactivate when done
        - additiveBlending: Whether to use additive blending
        - direction: Direction angle (radians)
]]
function ParticleEffect:initialize(x, y, type, options)
    options = options or {}
    
    -- Position
    self.x = x or 0
    self.y = y or 0
    
    -- State
    self.active = true
    self.type = type
    self.duration = options.duration or 1
    self.timer = self.duration
    self.autoRemove = options.autoRemove ~= nil and options.autoRemove or true
    self.additiveBlending = options.additiveBlending ~= nil and options.additiveBlending or false
    
    -- Get template
    local template = PARTICLE_TEMPLATES[type]
    if not template then
        print("Warning: Unknown particle type '" .. tostring(type) .. "'")
        self.active = false
        return self
    end
    
    -- Create particle system if needed
    if not self.system then
        -- Create image if needed
        if not template.image then
            template.image = self:createParticleImage()
        end
        
        -- Create particle system
        self.system = love.graphics.newParticleSystem(template.image, 100)
    else
        -- Reset existing system
        self.system:reset()
    end
    
    -- Apply template settings
    local settings = template.settings
    self.system:setParticleLifetime(settings.lifetime[1], settings.lifetime[2])
    
    if settings.emission then
        self.system:setEmissionRate(settings.emission)
    end
    
    if settings.size then
        self.system:setSizes(unpack(settings.size))
    end
    
    if settings.sizeVariation then
        self.system:setSizeVariation(settings.sizeVariation)
    end
    
    if settings.acceleration then
        local accel = settings.acceleration
        self.system:setLinearAcceleration(accel[1], accel[2], accel[3], accel[4])
    end
    
    if settings.colors then
        self.system:setColors(unpack(settings.colors))
    end
    
    if settings.spread then
        self.system:setSpread(settings.spread)
    end
    
    -- Apply custom options
    if options.direction then
        self.system:setDirection(options.direction)
        if settings.spread then
            self.system:setSpread(settings.spread)
        end
    end
    
    -- Emit initial particles if requested
    if options.emitOnCreate then
        local particleCount = options.particleCount or 10
        self.system:emit(particleCount)
    end
    
    return self
end

--[[
    Reset the particle effect
]]
function ParticleEffect:reset()
    self.active = false
    self.x = 0
    self.y = 0
    self.timer = 0
    
    if self.system then
        self.system:reset()
    end
end

--[[
    Update the particle effect
    
    @param dt - Delta time
]]
function ParticleEffect:update(dt)
    if not self.active then return end
    
    -- Update particle system
    if self.system then
        self.system:update(dt)
    end
    
    -- Update timer
    if self.duration > 0 then
        self.timer = self.timer - dt
        
        -- Check for auto-removal
        if self.timer <= 0 and self.autoRemove then
            -- Only deactivate if there are no active particles
            if self.system:getCount() == 0 then
                self.active = false
            end
        end
    end
end

--[[
    Draw the particle effect
    
    @param camera - Optional camera object for position adjustment
]]
function ParticleEffect:draw(camera)
    if not self.active or not self.system then return end
    
    -- Save current state
    local prevBlendMode = love.graphics.getBlendMode()
    
    -- Apply additive blending if enabled
    if self.additiveBlending then
        love.graphics.setBlendMode("add")
    end
    
    -- Adjust position for camera if provided
    local x, y = self.x, self.y
    if camera then
        -- Simple camera adjustment (modify based on your camera system)
        x = x - camera.x
        y = y - camera.y
    end
    
    -- Draw the particle system
    love.graphics.draw(self.system, x, y)
    
    -- Restore blend mode
    love.graphics.setBlendMode(prevBlendMode)
end

--[[
    Create a generic particle image (small white circle)
    
    @return Canvas with a circle drawn on it
]]
function ParticleEffect:createParticleImage()
    local size = 8
    local canvas = love.graphics.newCanvas(size, size)
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", size/2, size/2, size/2)
    love.graphics.setCanvas()
    
    return canvas
end

--[[
    Emit additional particles
    
    @param count - Number of particles to emit
]]
function ParticleEffect:emit(count)
    if self.active and self.system then
        self.system:emit(count or 10)
    end
end

--[[
    Move the particle effect
    
    @param x - New X position
    @param y - New Y position
]]
function ParticleEffect:setPosition(x, y)
    self.x = x
    self.y = y
end


--[[
    Create a new particle pool
    
    @return A new ParticlePool instance
]]
function ParticlePool:new()
    local pool = {
        pool = ObjectPool:new(ParticleEffect, 50), -- Start with 50 particles
        disableParticles = false
    }
    
    setmetatable(pool, ParticlePool)
    
    -- Register event handlers
    pool:setupEventHandlers()
    
    return pool
end

--[[
    Setup event handlers for common particle effects
]]
function ParticlePool:setupEventHandlers()
    -- Player landed event
    Events.on("playerLanded", function(data)
        self:createDustEffect(data.x, data.y)
    end)
    
    -- Player dash started event
    Events.on("playerDashStarted", function(data)
        self:createDashEffect(data.player, data.direction)
    end)
    
    -- Enemy kill event
    Events.on("enemyKill", function(data)
        local enemy = data.enemy
        self:createImpactEffect(enemy.x + enemy.width/2, enemy.y + enemy.height/2)
        
        -- Create dash refresh effect on player
        if data.player then
            self:createRefreshEffect(data.player)
        end
    end)
    
    -- Springboard jump event
    Events.on("playerSpringboardJump", function(data)
        self:createDustEffect(data.x, data.y)
        self:createDustEffect(data.x - 10, data.y)
        self:createDustEffect(data.x + 10, data.y)
    end)
    
    -- Double jump event (fired when player uses mid-air jump)
    Events.on("playerDoubleJump", function(data)
        local player = data.player
        self:createDoubleJumpEffect(player)
    end)
    
    -- Level up event
    Events.on("playerLevelUp", function(data)
        local player = data.player
        self:createLevelUpEffect(player.x + player.width/2, player.y + player.height/2)
    end)
end

--[[
    Create a dust effect when landing
    
    @param x - X position
    @param y - Y position
    @param height - Optional height override
    @return The particle effect object
]]
function ParticlePool:createDustEffect(x, y, height)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(x, y, "dust", {
        emitOnCreate = true,
        particleCount = 20,
        autoRemove = true
    })
    
    return particle
end

--[[
    Create a dash effect
    
    @param player - Player entity
    @param direction - Direction vector
    @return The particle effect object
]]
function ParticlePool:createDashEffect(player, direction)
    if self.disableParticles then return nil end
    
    -- Calculate angle from direction
    local angle = math.atan2(direction.y, direction.x)
    -- Invert angle for proper particle direction
    angle = angle + math.pi
    
    local particle = self.pool:get(
        player.x + player.width/2,
        player.y + player.height/2,
        "dash",
        {
            emitOnCreate = true,
            particleCount = 15,
            autoRemove = true,
            direction = angle,
            additiveBlending = true
        }
    )
    
    return particle
end

--[[
    Create a double jump effect
    
    @param player - Player entity
    @return The particle effect object
]]
function ParticlePool:createDoubleJumpEffect(player)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(
        player.x + player.width/2,
        player.y + player.height,
        "doubleJump",
        {
            emitOnCreate = true,
            particleCount = 25,
            autoRemove = true,
            additiveBlending = true
        }
    )
    
    return particle
end

--[[
    Create an impact effect (for enemy defeat)
    
    @param x - X position
    @param y - Y position
    @return The particle effect object
]]
function ParticlePool:createImpactEffect(x, y)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(x, y, "impact", {
        emitOnCreate = true,
        particleCount = 30,
        autoRemove = true,
        additiveBlending = true
    })
    
    return particle
end

--[[
    Create a refresh effect (for dash/jump refresh)
    
    @param player - Player entity
    @return The particle effect object
]]
function ParticlePool:createRefreshEffect(player)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(
        player.x + player.width/2,
        player.y + player.height/2,
        "refresh",
        {
            emitOnCreate = true,
            particleCount = 25,
            autoRemove = true,
            additiveBlending = true
        }
    )
    
    return particle
end

--[[
    Create a burn effect
    
    @param x - X position
    @param y - Y position
    @return The particle effect object
]]
function ParticlePool:createBurnEffect(x, y)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(x, y, "burn", {
        emitOnCreate = true,
        particleCount = 50,
        autoRemove = true,
        additiveBlending = true
    })
    
    return particle
end

--[[
    Create a level up effect
    
    @param x - X position
    @param y - Y position
    @return The particle effect object
]]
function ParticlePool:createLevelUpEffect(x, y)
    if self.disableParticles then return nil end
    
    local particle = self.pool:get(x, y, "levelUp", {
        emitOnCreate = true,
        particleCount = 50,
        autoRemove = true,
        duration = 2.0,
        additiveBlending = true
    })
    
    return particle
end

--[[
    Update all active particle effects
    
    @param dt - Delta time
]]
function ParticlePool:update(dt)
    self.pool:update(dt)
end

--[[
    Draw all active particle effects
    
    @param camera - Optional camera object
]]
function ParticlePool:draw(camera)
    self.pool:draw(camera)
end

--[[
    Toggle particle effects on/off
    
    @param disabled - Whether particles should be disabled
]]
function ParticlePool:setParticlesDisabled(disabled)
    self.disableParticles = disabled
    
    -- If disabling, release all active particles
    if disabled then
        self.pool:releaseAll()
    end
end

--[[
    Enable debug mode
    
    @param enabled - Whether debug mode should be enabled
]]
function ParticlePool:setDebugMode(enabled)
    self.pool:setDebugMode(enabled)
end

--[[
    Get particle count statistics
    
    @return Table with active, available, and total counts
]]
function ParticlePool:getStats()
    return {
        active = self.pool:getActiveCount(),
        available = self.pool:getAvailableCount(),
        total = self.pool:getTotalSize()
    }
end

return ParticlePool