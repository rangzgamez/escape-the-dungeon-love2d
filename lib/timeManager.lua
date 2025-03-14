-- timeManager.lua - Manages time effects for Love2D Vertical Jumper

local Events = require("lib/events")

local TimeManager = {}
TimeManager.__index = TimeManager

function TimeManager:new()
    local self = setmetatable({}, TimeManager)
    
    self.timeScale = 1        -- Time scale factor (1 = normal speed, < 1 = slow motion)
    self.freezeTimer = 0      -- Timer for screen freeze effect
    self.freezeDuration = 0   -- How long the freeze lasts
    
    -- Register event listeners
    Events.on("enemyKill", function(data) self:onEnemyKill(data) end)
    
    return self
end

-- Event handler for enemy kill
function TimeManager:onEnemyKill(data)
    local comboCount = data and data.comboCount or 0
    local freezeTime = math.min(0.05 + comboCount * 0.01, 0.15)  -- Longer freeze for higher combos
    self:triggerFreeze(freezeTime)
end

-- Trigger a screen freeze
function TimeManager:triggerFreeze(duration)
    self.freezeTimer = duration
    self.timeScale = 0.05  -- Start at 5% speed
end

-- Update time scaling
function TimeManager:update(dt)
    -- Handle screen freeze effect
    if self.freezeTimer > 0 then
        self.freezeTimer = self.freezeTimer - dt
        dt = dt * 0.05  -- 5% speed during freeze (almost stopped)
        
        if self.freezeTimer <= 0 then
            -- Return to normal speed when freeze ends
            self.timeScale = 1
        end
    else
        -- Apply normal time scale
        local scaledDt = dt * self.timeScale
        
        -- Gradually transition to target time scale if one is set
        if self.targetTimeScale and self.timeScale ~= self.targetTimeScale then
            -- Transition at a rate of 2 units per second
            local transitionRate = 2 * dt
            if self.timeScale < self.targetTimeScale then
                self.timeScale = math.min(self.targetTimeScale, self.timeScale + transitionRate)
            else
                self.timeScale = math.max(self.targetTimeScale, self.timeScale - transitionRate)
            end
            
            -- Clear target once reached
            if math.abs(self.timeScale - self.targetTimeScale) < 0.01 then
                self.timeScale = self.targetTimeScale
                self.targetTimeScale = nil
            end
        end
    end
    
    -- Return the scaled dt
    return dt * self.timeScale
end

-- Get current time scale
function TimeManager:getTimeScale()
    return self.timeScale
end

-- Set the time scale
function TimeManager:setTimeScale(scale, smooth)
    if smooth then
        -- Set target for smooth transition
        self.targetTimeScale = scale
    else
        -- Immediate change
        self.timeScale = scale
        self.targetTimeScale = nil
    end
end

-- Reset the time manager
function TimeManager:reset()
    self.timeScale = 1
    self.freezeTimer = 0
    self.freezeDuration = 0
    self.targetTimeScale = nil
    self.transitionSpeed = nil
    
    print("Time manager reset")
end

return TimeManager