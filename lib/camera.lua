-- camera.lua - Simple camera module for Love2D
-- Simplified version for the PlayerECS test example

local Camera = {}
Camera.__index = Camera

function Camera.new(x, y)
    local self = setmetatable({}, Camera)
    
    self.x = x or 0
    self.y = y or 0
    self.targetX = self.x
    self.targetY = self.y
    self.smoothness = 0.1 -- Lower = smoother camera follow
    self.followStyle = "LOCKON" -- Default follow style
    self.followOffsetX = 0
    self.followOffsetY = 0
    self.deadzone = {
        x = 0,
        y = 0,
        width = 0,
        height = 0
    }
    self.bounds = nil
    
    return self
end

-- Set the camera follow style
function Camera:setFollowStyle(style)
    self.followStyle = style
    
    -- Configure deadzone based on style
    local w, h = love.graphics.getDimensions()
    
    if style == "LOCKON" then
        -- No deadzone, camera directly follows target
        self.deadzone.x = w/2
        self.deadzone.y = h/2
        self.deadzone.width = 0
        self.deadzone.height = 0
    elseif style == "PLATFORMER" then
        -- Deadzone for platformer games
        self.deadzone.x = w/2 - 100
        self.deadzone.y = h/2 - 50
        self.deadzone.width = 200
        self.deadzone.height = 100
    elseif style == "TOPDOWN" then
        -- Deadzone for top-down games
        self.deadzone.x = w/2 - 80
        self.deadzone.y = h/2 - 80
        self.deadzone.width = 160
        self.deadzone.height = 160
    end
end

-- Set camera bounds
function Camera:setBounds(x, y, width, height)
    self.bounds = {
        x = x,
        y = y,
        width = width,
        height = height
    }
end

-- Set the camera to follow a target entity or position
function Camera:follow(target)
    if type(target) == "table" then
        -- Following an entity
        if target.x and target.y then
            self.target = target
        end
    else
        -- Following a position
        self.targetX = target
        self.targetY = y
        self.target = nil
    end
end

-- Update the camera position
function Camera:update(dt)
    -- Update target position if following an entity
    if self.target then
        if self.target.x and self.target.y then
            local targetX = self.target.x
            local targetY = self.target.y
            
            -- Add width/2 and height/2 if available to center on entity
            if self.target.width then targetX = targetX + self.target.width/2 end
            if self.target.height then targetY = targetY + self.target.height/2 end
            
            -- Apply follow style
            if self.followStyle == "LOCKON" then
                -- Direct follow
                self.targetX = targetX + self.followOffsetX
                self.targetY = targetY + self.followOffsetY
            else
                -- Apply deadzone
                local dx = targetX - self.x
                local dy = targetY - self.y
                
                -- X-axis deadzone
                if dx > self.deadzone.x + self.deadzone.width/2 then
                    self.targetX = self.x + (dx - self.deadzone.x - self.deadzone.width/2)
                elseif dx < self.deadzone.x - self.deadzone.width/2 then
                    self.targetX = self.x + (dx - self.deadzone.x + self.deadzone.width/2)
                end
                
                -- Y-axis deadzone
                if dy > self.deadzone.y + self.deadzone.height/2 then
                    self.targetY = self.y + (dy - self.deadzone.y - self.deadzone.height/2)
                elseif dy < self.deadzone.y - self.deadzone.height/2 then
                    self.targetY = self.y + (dy - self.deadzone.y + self.deadzone.height/2)
                end
            end
        end
    end
    
    -- Smooth movement toward target
    self.x = self.x + (self.targetX - self.x) * self.smoothness
    self.y = self.y + (self.targetY - self.y) * self.smoothness
    
    -- Apply bounds if set
    if self.bounds then
        local w, h = love.graphics.getDimensions()
        
        -- Limit camera position to bounds
        self.x = math.max(self.bounds.x + w/2, math.min(self.bounds.x + self.bounds.width - w/2, self.x))
        self.y = math.max(self.bounds.y + h/2, math.min(self.bounds.y + self.bounds.height - h/2, self.y))
    end
end

-- Apply camera transformations
function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-self.x + love.graphics.getWidth() / 2, -self.y + love.graphics.getHeight() / 2)
end

-- Reset camera transformations
function Camera:detach()
    love.graphics.pop()
end

return Camera 