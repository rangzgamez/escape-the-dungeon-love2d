-- transitionManager.lua - Handles screen transitions between game states
local Events = require("lib/events")

local TransitionManager = {}
TransitionManager.__index = TransitionManager

function TransitionManager:new()
    local self = setmetatable({}, TransitionManager)
    
    -- Transition state
    self.active = false
    self.type = nil       -- "fade", "slide", "wipe", "circle"
    self.direction = nil  -- "in" or "out"
    self.progress = 0     -- 0 to 1
    self.duration = 1     -- seconds
    self.callback = nil   -- function to call when complete
    self.easing = nil     -- easing function to use
    self.color = {0, 0, 0, 1} -- transition color (default: black)
    
    -- Chain transitions (for in/out sequence)
    self.nextTransition = nil
    
    -- Register for game state change events
    Events.on("gameStateChange", function(data)
        if data.transition then
            self:startTransition(data.transition, 0.5, "out", function()
                -- Change game state
                data.callback()
                
                -- Start the reverse transition
                self:startTransition(data.transition, 0.5, "in")
            end)
        end
    end)
    
    return self
end

-- Start a transition effect
function TransitionManager:startTransition(type, duration, direction, callback, color)
    self.active = true
    self.type = type or "fade"
    self.direction = direction or "out" -- "out" means transitioning to black
    self.progress = 0
    self.duration = duration or 1
    self.callback = callback
    
    -- Set transition color
    if color then
        self.color = color
    else
        self.color = {0, 0, 0, 1} -- Default to black
    end
    
    -- Select easing function based on direction
    if self.direction == "out" then
        -- Ease out transitions (slow start, fast finish)
        self.easing = self.easeInQuad
    else
        -- Ease in transitions (fast start, slow finish)
        self.easing = self.easeOutQuad
    end
end

-- Chain a second transition to occur after this one completes
function TransitionManager:chainTransition(type, duration, direction, callback, color)
    self.nextTransition = {
        type = type or "fade",
        duration = duration or 1,
        direction = direction or "in",
        callback = callback,
        color = color or {0, 0, 0, 1}
    }
end

-- Update transition progress
function TransitionManager:update(dt)
    if not self.active then return false end
    
    -- Update progress
    self.progress = self.progress + dt / self.duration
    
    -- Finished transition
    if self.progress >= 1 then
        self.progress = 1
        
        -- Store callback to execute after this update
        local currentCallback = self.callback
        
        -- If there's a chained transition, start it
        if self.nextTransition then
            self:startTransition(
                self.nextTransition.type,
                self.nextTransition.duration,
                self.nextTransition.direction,
                self.nextTransition.callback,
                self.nextTransition.color
            )
            self.nextTransition = nil
        else
            self.active = false
        end
        
        -- Execute callback if provided
        if currentCallback then
            currentCallback()
        end
    end
    
    return self.active
end

-- Draw transition effect
function TransitionManager:draw()
    if not self.active then return end
    
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Apply easing to progress
    local easedProgress = self.easing(self.progress)
    
    -- Adjust for transition direction
    local displayProgress = self.direction == "out" and easedProgress or (1 - easedProgress)
    
    -- Set color with adjusted alpha
    love.graphics.setColor(
        self.color[1], 
        self.color[2], 
        self.color[3], 
        displayProgress * self.color[4]
    )
    
    -- Draw different transition types
    if self.type == "fade" then
        -- Simple fade to/from color
        love.graphics.rectangle("fill", 0, 0, width, height)
        
    elseif self.type == "slide" then
        -- Slide from left or right
        local slideWidth = width * displayProgress
        
        if self.direction == "out" then
            -- Slide from left to right
            love.graphics.rectangle("fill", 0, 0, slideWidth, height)
        else
            -- Slide from right to left
            love.graphics.rectangle("fill", width - slideWidth, 0, slideWidth, height)
        end
        
    elseif self.type == "wipe" then
        -- Wipe from top to bottom or bottom to top
        local wipeHeight = height * displayProgress
        
        if self.direction == "out" then
            -- Wipe from top to bottom
            love.graphics.rectangle("fill", 0, 0, width, wipeHeight)
        else
            -- Wipe from bottom to top
            love.graphics.rectangle("fill", 0, height - wipeHeight, width, wipeHeight)
        end
        
    elseif self.type == "circle" then
        -- Circle expand from center or contract to center
        local maxRadius = math.sqrt(width*width + height*height) / 2
        local radius = maxRadius * displayProgress
        
        -- Draw filled circle
        love.graphics.stencil(function()
            love.graphics.circle("fill", width/2, height/2, radius)
        end, "replace", 1)
        
        love.graphics.setStencilTest("equal", 1)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setStencilTest()
        
    elseif self.type == "blinds" then
        -- Venetian blind effect
        local numBlinds = 12
        local blindHeight = height / numBlinds
        local blindWidth = width * displayProgress
        
        for i = 0, numBlinds-1 do
            love.graphics.rectangle("fill", 0, i * blindHeight, blindWidth, blindHeight * 0.8)
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Check if transition is currently active
function TransitionManager:isActive()
    return self.active
end

-- Easing functions
function TransitionManager:linearInterpolation(t)
    return t
end

function TransitionManager:easeInQuad(t)
    return t * t
end

function TransitionManager:easeOutQuad(t)
    return t * (2 - t)
end

function TransitionManager:easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

return TransitionManager