-- lib/animationComponent.lua - Animation component for entities
local Events = require("lib/events")
local AssetManager = require("lib/assetManager")

local AnimationComponent = {}
AnimationComponent.__index = AnimationComponent

function AnimationComponent:new(entity)
    local self = setmetatable({}, AnimationComponent)
    
    -- Store reference to parent entity
    self.entity = entity
    
    -- Animation properties
    self.animations = {}        -- Table of animation objects by name
    self.currentAnimation = nil -- Current animation name
    self.lastAnimation = nil    -- Previous animation name for transition handling
    self.flipX = false          -- Horizontal flip flag
    self.flipY = false          -- Vertical flip flag
    self.rotation = 0           -- Rotation in radians
    self.scale = 1              -- Scale factor
    self.color = {1, 1, 1, 1}   -- Color tint
    self.offset = {x = 0, y = 0}-- Offset from entity position
    
    -- Visual effects
    self.flash = {active = false, duration = 0, timer = 0, color = {1, 1, 1, 1}}
    self.trail = {active = false, positions = {}, maxPositions = 5, interval = 0.05, timer = 0}
    
    -- Callbacks
    self.onAnimationEnd = nil   -- Function to call when non-looping animation ends
    self.onFrameChange = nil    -- Function to call when animation frame changes
    
    return self
end

-- Add a new animation to this component
function AnimationComponent:addAnimation(name, spriteSheet, frames, frameTime, loop)
    -- Create the animation using AssetManager
    self.animations[name] = AssetManager.createAnimation(
        spriteSheet, frames, frameTime, loop, name
    )
    
    -- If this is the first animation, set it as current
    if not self.currentAnimation then
        self:play(name)
    end
    
    return self
end

-- Load animations from a definition file
function AnimationComponent:loadAnimations(entityType, spriteSheet)
    -- Try to load the animation definitions
    local path = "assets/animations/definitions/" .. entityType
    local definitions = AssetManager.loadAnimationDefinition(path)
    
    -- Add each animation from the definitions
    for name, def in pairs(definitions) do
        if name ~= "default" then  -- Skip the default entry which is just metadata
            self:addAnimation(
                name,
                spriteSheet,
                def.frames,
                def.frameTime,
                def.loop
            )
        end
    end
    
    -- Set default animation if specified
    if definitions.default then
        self:play(definitions.default)
    end
    
    return self
end

-- Play an animation
function AnimationComponent:play(name, forceRestart)
    -- Skip if already playing this animation and not forcing restart
    if self.currentAnimation == name and not forceRestart then
        return self
    end
    
    -- Store the last animation for transition handling
    self.lastAnimation = self.currentAnimation
    
    -- Set the new animation
    self.currentAnimation = name
    
    -- Reset the animation if it exists
    local anim = self.animations[name]
    if anim then
        AssetManager.resetAnimation(anim)
    else
        print("Warning: Animation '" .. name .. "' not found")
    end
    
    -- Fire animation change event
    Events.fire("entityAnimationChanged", {
        entity = self.entity,
        animationName = name,
        previousAnimation = self.lastAnimation
    })
    
    return self
end

-- Update the current animation
function AnimationComponent:update(dt)
    -- Skip if no current animation
    if not self.currentAnimation then
        return self
    end
    
    local anim = self.animations[self.currentAnimation]
    if not anim then
        return self
    end
    
    -- Store current frame for change detection
    local previousFrame = anim.currentFrame
    
    -- Update the animation
    AssetManager.updateAnimation(anim, dt)
    
    -- Check for frame change
    if previousFrame ~= anim.currentFrame and self.onFrameChange then
        self.onFrameChange(self.currentAnimation, anim.currentFrame, anim.frames[anim.currentFrame])
    end
    
    -- Check for animation end
    if anim.finished and self.onAnimationEnd then
        self.onAnimationEnd(self.currentAnimation)
    end
    
    -- Update flash effect
    if self.flash.active then
        self.flash.timer = self.flash.timer - dt
        if self.flash.timer <= 0 then
            self.flash.active = false
        end
    end
    
    -- Update trail effect
    if self.trail.active then
        self.trail.timer = self.trail.timer - dt
        if self.trail.timer <= 0 then
            self.trail.timer = self.trail.interval
            
            -- Add current position to trail
            table.insert(self.trail.positions, {
                x = self.entity.x,
                y = self.entity.y,
                rotation = self.rotation,
                flipX = self.flipX,
                flipY = self.flipY,
                frame = anim.currentFrame
            })
            
            -- Limit trail length
            if #self.trail.positions > self.trail.maxPositions then
                table.remove(self.trail.positions, 1)
            end
        end
    end
    
    return self
end

-- Draw the current animation
function AnimationComponent:draw()
    -- Skip if no current animation
    if not self.currentAnimation then
        return self
    end
    
    local anim = self.animations[self.currentAnimation]
    if not anim then
        return self
    end
    
    -- Draw trail effect first (if active)
    if self.trail.active and #self.trail.positions > 0 then
        for i, pos in ipairs(self.trail.positions) do
            -- Calculate alpha based on position in trail
            local alpha = i / #self.trail.positions * 0.7
            
            -- Set trail color (faded)
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
            
            -- Get the frame for this trail position
            local frameIndex = anim.frames[pos.frame]
            local quad = anim.spriteSheet.quads[frameIndex]
            
            -- Calculate scale with horizontal flip if needed
            local sx = self.scale * (pos.flipX and -1 or 1)
            local sy = self.scale * (pos.flipY and -1 or 1)
            
            -- Calculate origin
            local originX = anim.spriteSheet.frameWidth / 2
            local originY = anim.spriteSheet.frameHeight / 2
            
            -- Draw the trail frame
            love.graphics.draw(
                anim.spriteSheet.image,
                quad,
                pos.x + self.entity.width/2 + self.offset.x,
                pos.y + self.entity.height/2 + self.offset.y,
                pos.rotation,
                sx, sy,
                originX, originY
            )
        end
    end
    
    -- Set color based on flash effect or normal color
    if self.flash.active then
        love.graphics.setColor(
            self.flash.color[1],
            self.flash.color[2],
            self.flash.color[3],
            self.flash.color[4]
        )
    else
        love.graphics.setColor(
            self.color[1],
            self.color[2],
            self.color[3],
            self.color[4]
        )
    end
    
    -- Calculate scale with horizontal flip if needed
    local sx = self.scale * (self.flipX and -1 or 1)
    local sy = self.scale * (self.flipY and -1 or 1)
    
    -- Draw the current animation frame
    AssetManager.drawAnimation(
        anim,
        self.entity.x + self.entity.width/2 + self.offset.x,
        self.entity.y + self.entity.height/2 + self.offset.y,
        sx, sy,
        self.rotation
    )
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    
    return self
end

-- Set horizontal flip based on velocity or specified value
function AnimationComponent:setFlipX(value)
    if value ~= nil then
        self.flipX = value
    else
        -- Auto-flip based on entity's velocity if available
        if self.entity.velocity and self.entity.velocity.x then
            self.flipX = self.entity.velocity.x < 0
        end
    end
    return self
end

-- Set vertical flip based on velocity or specified value
function AnimationComponent:setFlipY(value)
    if value ~= nil then
        self.flipY = value
    else
        -- Auto-flip based on entity's velocity if available
        if self.entity.velocity and self.entity.velocity.y then
            self.flipY = self.entity.velocity.y < 0
        end
    end
    return self
end

-- Set rotation (in radians)
function AnimationComponent:setRotation(radians)
    self.rotation = radians
    return self
end

-- Set scale
function AnimationComponent:setScale(scale)
    self.scale = scale
    return self
end

-- Set color tint
function AnimationComponent:setColor(r, g, b, a)
    self.color = {r, g, b, a or 1}
    return self
end

-- Set offset from entity position
function AnimationComponent:setOffset(x, y)
    self.offset = {x = x, y = y}
    return self
end

-- Start flash effect
function AnimationComponent:startFlash(duration, color)
    self.flash.active = true
    self.flash.duration = duration or 0.1
    self.flash.timer = self.flash.duration
    self.flash.color = color or {1, 1, 1, 1}
    return self
end

-- Start trail effect
function AnimationComponent:startTrail(maxPositions, interval)
    self.trail.active = true
    self.trail.positions = {}
    self.trail.maxPositions = maxPositions or 5
    self.trail.interval = interval or 0.05
    self.trail.timer = 0
    return self
end

-- Stop trail effect
function AnimationComponent:stopTrail()
    self.trail.active = false
    self.trail.positions = {}
    return self
end

-- Check if an animation exists
function AnimationComponent:hasAnimation(name)
    return self.animations[name] ~= nil
end

-- Check if an animation is playing
function AnimationComponent:isPlaying(name)
    return self.currentAnimation == name
end

-- Get current animation name
function AnimationComponent:getCurrentAnimationName()
    return self.currentAnimation
end

-- Check if current animation is finished (for non-looping animations)
function AnimationComponent:isFinished()
    if not self.currentAnimation then
        return true
    end
    
    local anim = self.animations[self.currentAnimation]
    return anim and anim.finished
end

-- Set callback for animation end
function AnimationComponent:onEnd(callback)
    self.onAnimationEnd = callback
    return self
end

-- Set callback for frame change
function AnimationComponent:onFrame(callback)
    self.onFrameChange = callback
    return self
end

return AnimationComponent