-- lib/assetManager.lua - Centralized asset loading and caching system

-- Private cache tables
local imageCache = {}
local spriteSheetCache = {}
local animationCache = {}
local fontCache = {}
local soundCache = {}

-- Create the module
local AssetManager = {}

---------------------------
-- Image Loading Functions
---------------------------
function AssetManager.loadImage(path)
    -- Return cached image if available
    if imageCache[path] then
        return imageCache[path]
    end
    
    -- Load and cache the image
    local success, result = pcall(function()
        return love.graphics.newImage(path)
    end)
    
    if not success then
        print("ERROR: Failed to load image: " .. path)
        print(result)
        -- Return a placeholder/error image
        local errorImg = love.graphics.newCanvas(32, 32)
        love.graphics.setCanvas(errorImg)
        love.graphics.clear(1, 0, 1) -- Magenta to make it obvious
        love.graphics.setCanvas()
        imageCache[path] = errorImg
        return errorImg
    end
    
    -- Enable nearest-neighbor filtering for crisp pixel art
    result:setFilter("nearest", "nearest")
    
    -- Cache and return the image
    imageCache[path] = result
    return result
end

---------------------------
-- Sprite Sheet Functions
---------------------------
function AssetManager.loadSpriteSheet(path, frameWidth, frameHeight, padding, spacing)
    -- Cache key includes all parameters to handle different frame configurations
    local cacheKey = path .. "_" .. frameWidth .. "x" .. frameHeight
    if padding then cacheKey = cacheKey .. "_p" .. padding end
    if spacing then cacheKey = cacheKey .. "_s" .. spacing end
    
    -- Return cached sprite sheet if available
    if spriteSheetCache[cacheKey] then
        return spriteSheetCache[cacheKey]
    end
    
    -- Default values
    padding = padding or 0
    spacing = spacing or 0
    
    -- Load the image
    local image = AssetManager.loadImage(path)
    
    -- Create sprite sheet definition
    local sheet = {
        image = image,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        padding = padding,
        spacing = spacing,
        quads = {},
        width = image:getWidth(),
        height = image:getHeight()
    }
    
    -- Calculate number of frames in each row and column
    local columns = math.floor((sheet.width - padding) / (frameWidth + spacing))
    local rows = math.floor((sheet.height - padding) / (frameHeight + spacing))
    
    -- Generate quads (frame rectangles)
    local frameIndex = 1
    for row = 0, rows - 1 do
        for col = 0, columns - 1 do
            local x = padding + col * (frameWidth + spacing)
            local y = padding + row * (frameHeight + spacing)
            
            -- Create quad
            local quad = love.graphics.newQuad(
                x, y, frameWidth, frameHeight,
                sheet.width, sheet.height
            )
            
            -- Store quad with 1-based index
            sheet.quads[frameIndex] = quad
            frameIndex = frameIndex + 1
        end
    end
    
    -- Store the total frames count
    sheet.frameCount = frameIndex - 1
    
    -- Cache and return the sprite sheet
    spriteSheetCache[cacheKey] = sheet
    return sheet
end

---------------------------
-- Animation Functions
---------------------------
function AssetManager.createAnimation(spriteSheet, frames, frameTime, loop, name)
    -- Create animation definition
    local animation = {
        spriteSheet = spriteSheet,
        frames = frames or {}, -- Array of frame indices
        frameTime = frameTime or 0.1, -- Seconds per frame
        loop = loop == nil and true or loop, -- Loop by default
        name = name or "unnamed", -- Animation name for debugging
        currentFrame = 1, -- Current frame index in the frames table
        timer = 0, -- Time since last frame change
        finished = false -- Whether a non-looping animation has finished
    }
    
    -- If frames is not provided, use all frames in sequence
    if #frames == 0 and spriteSheet then
        for i = 1, spriteSheet.frameCount do
            table.insert(animation.frames, i)
        end
    end
    
    return animation
end

function AssetManager.loadAnimationDefinition(path)
    -- Return cached animation if available
    if animationCache[path] then
        return animationCache[path]
    end
    
    -- Load the animation definition file (JSON or Lua)
    local success, result = pcall(function()
        if path:match("%.json$") then
            -- JSON loading would go here - you might need a JSON library
            error("JSON loading not implemented yet")
        else
            -- Assume Lua file that returns a table
            return require(path)
        end
    end)
    
    if not success then
        print("ERROR: Failed to load animation definition: " .. path)
        print(result)
        return {}
    end
    
    -- Cache and return the animation definition
    animationCache[path] = result
    return result
end

function AssetManager.updateAnimation(animation, dt)
    -- Skip update if animation is finished
    if animation.finished then
        return animation
    end
    
    -- Update timer
    animation.timer = animation.timer + dt
    
    -- Check if it's time to advance to the next frame
    if animation.timer >= animation.frameTime then
        animation.timer = animation.timer - animation.frameTime
        animation.currentFrame = animation.currentFrame + 1
        
        -- Check for end of animation
        if animation.currentFrame > #animation.frames then
            if animation.loop then
                animation.currentFrame = 1
            else
                animation.currentFrame = #animation.frames
                animation.finished = true
            end
        end
    end
    
    return animation
end

function AssetManager.resetAnimation(animation)
    animation.currentFrame = 1
    animation.timer = 0
    animation.finished = false
    return animation
end

function AssetManager.drawAnimation(animation, x, y, scaleX, scaleY, rotation, originX, originY)
    -- Skip drawing if animation has no frames
    if #animation.frames == 0 or not animation.spriteSheet then
        return
    end
    
    -- Default values
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    rotation = rotation or 0
    
    -- Get the current frame index from the animation's frames table
    local frameIndex = animation.frames[animation.currentFrame]
    local quad = animation.spriteSheet.quads[frameIndex]
    
    -- Calculate origin if not provided
    if not originX or not originY then
        originX = animation.spriteSheet.frameWidth / 2
        originY = animation.spriteSheet.frameHeight / 2
    end
    
    -- Draw the frame
    love.graphics.draw(
        animation.spriteSheet.image,
        quad,
        x, y,
        rotation,
        scaleX, scaleY,
        originX, originY
    )
end

---------------------------
-- Font Loading Functions
---------------------------
function AssetManager.loadFont(path, size)
    local cacheKey = path .. "_" .. size
    
    -- Return cached font if available
    if fontCache[cacheKey] then
        return fontCache[cacheKey]
    end
    
    -- Load and cache the font
    local success, result = pcall(function()
        return love.graphics.newFont(path, size)
    end)
    
    if not success then
        print("ERROR: Failed to load font: " .. path)
        print(result)
        -- Return the default font
        result = love.graphics.newFont(size)
    end
    
    -- Cache and return the font
    fontCache[cacheKey] = result
    return result
end

---------------------------
-- Sound Loading Functions
---------------------------
function AssetManager.loadSound(path)
    -- Return cached sound if available
    if soundCache[path] then
        return soundCache[path]
    end
    
    -- Load and cache the sound
    local success, result = pcall(function()
        return love.audio.newSource(path, "static")
    end)
    
    if not success then
        print("ERROR: Failed to load sound: " .. path)
        print(result)
        return nil
    end
    
    -- Cache and return the sound
    soundCache[path] = result
    return result
end

---------------------------
-- Cache Management
---------------------------
function AssetManager.clearCache(cacheType)
    if cacheType == "images" or cacheType == "all" then
        imageCache = {}
    end
    
    if cacheType == "spritesheets" or cacheType == "all" then
        spriteSheetCache = {}
    end
    
    if cacheType == "animations" or cacheType == "all" then
        animationCache = {}
    end
    
    if cacheType == "fonts" or cacheType == "all" then
        fontCache = {}
    end
    
    if cacheType == "sounds" or cacheType == "all" then
        soundCache = {}
    end
end

function AssetManager.getCacheInfo()
    return {
        images = #imageCache,
        spritesheets = #spriteSheetCache,
        animations = #animationCache,
        fonts = #fontCache,
        sounds = #soundCache
    }
end

---------------------------
-- Batch Loading Functions
---------------------------
function AssetManager.preloadAssets(assetList)
    local loaded = 0
    local total = 0
    
    -- Count total assets
    for _, category in pairs(assetList) do
        total = total + #category
    end
    
    -- Load images
    if assetList.images then
        for _, path in ipairs(assetList.images) do
            AssetManager.loadImage(path)
            loaded = loaded + 1
        end
    end
    
    -- Load sprite sheets
    if assetList.spritesheets then
        for _, sheetInfo in ipairs(assetList.spritesheets) do
            AssetManager.loadSpriteSheet(
                sheetInfo.path,
                sheetInfo.frameWidth,
                sheetInfo.frameHeight,
                sheetInfo.padding,
                sheetInfo.spacing
            )
            loaded = loaded + 1
        end
    end
    
    -- Load animations
    if assetList.animations then
        for _, path in ipairs(assetList.animations) do
            AssetManager.loadAnimationDefinition(path)
            loaded = loaded + 1
        end
    end
    
    -- Load fonts
    if assetList.fonts then
        for _, fontInfo in ipairs(assetList.fonts) do
            AssetManager.loadFont(fontInfo.path, fontInfo.size)
            loaded = loaded + 1
        end
    end
    
    -- Load sounds
    if assetList.sounds then
        for _, path in ipairs(assetList.sounds) do
            AssetManager.loadSound(path)
            loaded = loaded + 1
        end
    end
    
    return loaded, total
end

-- Return the module
return AssetManager