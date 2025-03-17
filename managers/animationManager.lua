-- managers/animationManager.lua
local AnimationManager = {}

-- Store loaded sprite sheets
local spriteSheets = {}

-- Store loaded animation definitions
local animationDefinitions = {}

-- Store active animations
local activeAnimations = {}

-- Load a sprite sheet and store it
function AnimationManager.loadSpriteSheet(name, path)
    if not spriteSheets[name] then
        local image = love.graphics.newImage(path)
        spriteSheets[name] = image
    end
    return spriteSheets[name]
end

-- Load an animation definition file
function AnimationManager.loadAnimationDefinition(name, path)
    if not animationDefinitions[name] then
        local definition = require(path)
        animationDefinitions[name] = definition
    end
    return animationDefinitions[name]
end

-- Create a new animation for an entity
function AnimationManager.createAnimation(entityId, spriteSheetName, definitionName)
    if not spriteSheets[spriteSheetName] then
        error("Sprite sheet '" .. spriteSheetName .. "' not loaded")
    end
    
    if not animationDefinitions[definitionName] then
        error("Animation definition '" .. definitionName .. "' not loaded")
    end
    
    local animation = {
        entityId = entityId,
        spriteSheet = spriteSheets[spriteSheetName],
        definition = animationDefinitions[definitionName],
        currentAnimation = animationDefinitions[definitionName].default,
        currentFrame = 1,
        timer = 0,
        flipX = false,
        flipY = false,
        rotation = 0,
        scale = 1,
        frameWidth = 0,
        frameHeight = 0,
        rows = 1,
        columns = 1
    }
    
    activeAnimations[entityId] = animation
    return animation
end

-- Set the frame dimensions for a sprite sheet
function AnimationManager.setFrameDimensions(entityId, frameWidth, frameHeight, columns, rows)
    if not activeAnimations[entityId] then
        error("No animation found for entity ID: " .. entityId)
    end
    
    local animation = activeAnimations[entityId]
    animation.frameWidth = frameWidth
    animation.frameHeight = frameHeight
    animation.columns = columns or 1
    animation.rows = rows or 1
end

-- Play a specific animation
function AnimationManager.play(entityId, animationName, resetFrame)
    if not activeAnimations[entityId] then
        return
    end
    
    local animation = activeAnimations[entityId]
    
    -- Don't restart if already playing this animation unless forced
    if animation.currentAnimation == animationName and not resetFrame then
        return
    end
    
    -- Check if the animation exists in the definition
    if not animation.definition[animationName] then
        print("Warning: Animation '" .. animationName .. "' not found in definition")
        return
    end
    
    animation.currentAnimation = animationName
    animation.currentFrame = 1
    animation.timer = 0
end

-- Update animation state
function AnimationManager.update(dt)
    for entityId, animation in pairs(activeAnimations) do
        local currentAnim = animation.definition[animation.currentAnimation]
        
        if currentAnim then
            animation.timer = animation.timer + dt
            
            if animation.timer >= currentAnim.frameTime then
                animation.timer = animation.timer - currentAnim.frameTime
                animation.currentFrame = animation.currentFrame + 1
                
                -- Handle looping
                if animation.currentFrame > #currentAnim.frames then
                    if currentAnim.loop then
                        animation.currentFrame = 1
                    else
                        animation.currentFrame = #currentAnim.frames
                    end
                end
            end
        end
    end
end

-- Draw the current animation frame for an entity
function AnimationManager.draw(entityId, x, y)
    if not activeAnimations[entityId] then
        return
    end
    
    local animation = activeAnimations[entityId]
    local currentAnim = animation.definition[animation.currentAnimation]
    
    if not currentAnim then
        return
    end
    
    local frameIndex = currentAnim.frames[animation.currentFrame]
    local row = math.floor((frameIndex - 1) / animation.columns) + 1
    local col = ((frameIndex - 1) % animation.columns) + 1
    
    local quad = love.graphics.newQuad(
        (col - 1) * animation.frameWidth,
        (row - 1) * animation.frameHeight,
        animation.frameWidth,
        animation.frameHeight,
        animation.spriteSheet:getDimensions()
    )
    
    -- Draw with appropriate transformations
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        animation.spriteSheet,
        quad,
        x + animation.frameWidth / 2,
        y + animation.frameHeight / 2,
        animation.rotation,
        animation.flipX and -animation.scale or animation.scale,
        animation.flipY and -animation.scale or animation.scale,
        animation.frameWidth / 2,
        animation.frameHeight / 2
    )
end

-- Set horizontal flip state
function AnimationManager.setFlipX(entityId, flip)
    if activeAnimations[entityId] then
        activeAnimations[entityId].flipX = flip
    end
end

-- Set vertical flip state
function AnimationManager.setFlipY(entityId, flip)
    if activeAnimations[entityId] then
        activeAnimations[entityId].flipY = flip
    end
end

-- Set rotation angle
function AnimationManager.setRotation(entityId, angle)
    if activeAnimations[entityId] then
        activeAnimations[entityId].rotation = angle
    end
end

-- Set scale factor
function AnimationManager.setScale(entityId, scale)
    if activeAnimations[entityId] then
        activeAnimations[entityId].scale = scale
    end
end

-- Remove an animation when entity is destroyed
function AnimationManager.removeAnimation(entityId)
    activeAnimations[entityId] = nil
end

-- Clear all animations
function AnimationManager.clear()
    activeAnimations = {}
end

return AnimationManager 