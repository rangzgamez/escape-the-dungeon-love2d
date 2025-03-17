-- managers/platformFactory.lua - Factory for creating different platform types
local PlatformWithAnimations = require("entities/platform")

local PlatformFactory = {}

-- Define platform types with their characteristics and probabilities
local PLATFORM_TYPES = {
    normal = {
        probability = 60,  -- Higher probability = more common (base 100)
        color = {0.5, 0.5, 0.5},
        applyColor = false, -- Use the sprite coloring instead
        minWidth = 60,
        maxWidth = 150
    },
    cracked = {
        probability = 15,
        color = {0.4, 0.4, 0.45},
        applyColor = false,
        minWidth = 50,
        maxWidth = 100
    },
    mossy = {
        probability = 10,
        color = {0.3, 0.6, 0.3},
        applyColor = false,
        minWidth = 60,
        maxWidth = 120
    },
    icy = {
        probability = 8,
        color = {0.7, 0.8, 0.9},
        applyColor = false,
        minWidth = 70,
        maxWidth = 130
    },
    lava = {
        probability = 7,
        color = {0.8, 0.3, 0.1},
        applyColor = false,
        minWidth = 40,
        maxWidth = 90
    }
}

-- Create a platform with random type based on probabilities
function PlatformFactory.createRandomPlatform(x, y, assetManager, height, options)
    -- Get total probability
    local totalProbability = 0
    for _, info in pairs(PLATFORM_TYPES) do
        totalProbability = totalProbability + info.probability
    end
    
    -- Optional overrides
    options = options or {}
    local forcedType = options.type
    local minWidth = options.minWidth
    local maxWidth = options.maxWidth
    local minHeight = options.minHeight or 16
    local maxHeight = options.maxHeight or 20
    
    -- Select a random platform type based on probabilities
    local selectedType = forcedType
    if not selectedType then
        local rand = love.math.random(1, totalProbability)
        local cumulativeProbability = 0
        
        for typeName, info in pairs(PLATFORM_TYPES) do
            cumulativeProbability = cumulativeProbability + info.probability
            if rand <= cumulativeProbability then
                selectedType = typeName
                break
            end
        end
    end
    
    -- Get platform type info
    local typeInfo = PLATFORM_TYPES[selectedType] or PLATFORM_TYPES.normal
    
    -- Determine platform dimensions
    local width = love.math.random(
        minWidth or typeInfo.minWidth,
        maxWidth or typeInfo.maxWidth
    )
    
    local height = height or love.math.random(minHeight, maxHeight)
    
    -- Create the platform
    local platform = PlatformWithAnimations:new(x, y, width, height, assetManager, selectedType)
    
    -- Apply color if specified
    if typeInfo.applyColor then
        platform.color = typeInfo.color
    end
    
    -- Add type-specific properties
    if selectedType == "cracked" then
        platform.durability = love.math.random(1, 3)
        platform.breakOnTouch = love.math.random() < 0.3
    elseif selectedType == "icy" then
        platform.slipperiness = 0.9
    elseif selectedType == "lava" then
        platform.damageAmount = 1
    end
    
    return platform
end

-- Create a specific platform type
function PlatformFactory.createPlatform(x, y, width, height, platformType, assetManager)
    -- Use normal as default type
    platformType = platformType or "normal"
    
    -- Create the platform
    local platform = PlatformWithAnimations:new(
        x, y, width, height, 
        assetManager, platformType
    )
    
    -- Apply type-specific properties
    local typeInfo = PLATFORM_TYPES[platformType]
    if typeInfo and typeInfo.applyColor then
        platform.color = typeInfo.color
    end
    
    return platform
end

-- Calculate probabilities for different platform types based on height/progress
function PlatformFactory.adjustProbabilities(height)
    -- Make platforms more challenging as player goes higher
    local normalFactor = math.max(0.2, 1 - height / 10000)
    local specialFactor = math.min(3, 1 + height / 5000)
    
    -- Adjust probabilities
    PLATFORM_TYPES.normal.probability = 60 * normalFactor
    PLATFORM_TYPES.cracked.probability = 15 * specialFactor
    PLATFORM_TYPES.icy.probability = 8 * specialFactor
    PLATFORM_TYPES.lava.probability = 7 * specialFactor
end

return PlatformFactory