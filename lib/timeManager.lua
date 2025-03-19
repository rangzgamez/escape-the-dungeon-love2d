-- timeManager.lua - Manages time effects for Love2D Vertical Jumper

local Events = require("lib/events")

local TimeManager = {}
TimeManager.__index = TimeManager

function TimeManager:new()
    local self = setmetatable({}, TimeManager)
    
    self.timeScale = 1        -- Time scale factor (1 = normal speed, < 1 = slow motion)
    self.freezeTimer = 0      -- Timer for screen freeze effect
    self.freezeDuration = 0   -- How long the freeze lasts
    
    -- Dynamic drag slowdown properties
    self.dragActive = false
    self.dragStartTime = 0
    self.initialDragSlowdown = 0.05  -- Start at 5% speed (very slow)
    self.normalTimeScale = 1.0       -- Normal game speed
    self.dragSlowdownDuration = 1.5  -- Time in seconds to return to normal speed
    
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

-- Start drag slowdown
function TimeManager:startDragSlowdown()
    self.dragActive = true
    self.dragStartTime = love.timer.getTime()
    self.timeScale = self.initialDragSlowdown
end

-- End drag slowdown
function TimeManager:endDragSlowdown()
    self.dragActive = false
    self.timeScale = self.normalTimeScale
end

-- Update time scaling
function TimeManager:update(dt)
    -- Handle dynamic drag slowdown
    if self.dragActive then
        local elapsedTime = love.timer.getTime() - self.dragStartTime
        
        -- Calculate time scale based on how long the drag has been active
        -- Start very slow and gradually return to normal speed
        if elapsedTime < self.dragSlowdownDuration then
            -- Linear interpolation from initialDragSlowdown to normalTimeScale
            local progress = elapsedTime / self.dragSlowdownDuration
            self.timeScale = self.initialDragSlowdown + 
                            (self.normalTimeScale - self.initialDragSlowdown) * progress
        else
            -- After the duration, return to normal speed
            self.timeScale = self.normalTimeScale
        end
    end

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
        
        return scaledDt
    end
    
    return dt * self.timeScale
end

-- Get current time scale
function TimeManager:getTimeScale()
    return self.timeScale
end

-- Set time scale (optionally with smooth transition)
function TimeManager:setTimeScale(scale, smooth)
    -- if smooth then
    -- let's only apply smoothing on BIG hits. so like, boss kills
    -- this will be a TODO
    --     -- Store as target and transition gradually in update
    --     self.targetTimeScale = scale
    -- else
     -- Set immediately
    self.timeScale = scale
    --end
end

-- Set drag slowdown parameters (for power-ups)
function TimeManager:setDragSlowdownParams(initialSlowdown, duration)
    if initialSlowdown then
        self.initialDragSlowdown = initialSlowdown
    end
    
    if duration then
        self.dragSlowdownDuration = duration
    end
end

-- Enhance the initial slowdown (slower initial time)
function TimeManager:enhanceInitialSlowdown(factor)
    -- Make the initial slowdown even slower (multiply by a value < 1)
    -- Ensure it doesn't go below 0.01 (1% speed) to prevent complete freezing
    self.initialDragSlowdown = math.max(0.01, self.initialDragSlowdown * factor)
    return self.initialDragSlowdown
end

-- Extend the duration of the slowdown effect
function TimeManager:extendSlowdownDuration(amount)
    -- Add time to the slowdown duration (in seconds)
    self.dragSlowdownDuration = self.dragSlowdownDuration + amount
    return self.dragSlowdownDuration
end

return TimeManager