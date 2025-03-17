-- managers/comboManager.lua - Handles combo tracking and visualization
local Events = require("lib/events")

local ComboManager = {}

-- Private state
local comboCount = 0
local lastPlayerY = 0

-- Text display variables
local comboText = nil      -- Current combo text to display
local comboTimer = 0       -- Timer for combo text display
local comboMaxTime = 2     -- How long to show combo text (seconds)
local comboScale = 1       -- Size scaling for animation
local comboAngle = 0       -- Rotation angle for animation
local comboX = 0           -- X position for text
local comboY = 0           -- Y position for text
local comboOffsetX = 0     -- Animation offset X
local comboOffsetY = 0     -- Animation offset Y

-- Affirmation text variables
local affirmationText = nil    -- Random affirmation to display
local affirmationTimer = 0     -- Timer for affirmation display
local affirmationScale = 1     -- Size scaling for animation
local affirmationAngle = 0     -- Rotation angle for animation
local affirmationX = 0         -- X position for text
local affirmationY = 0         -- Y position for text
local affirmationOffsetX = 0   -- Animation offset X
local affirmationOffsetY = 0   -- Animation offset Y

-- Cache player position for animations
local playerPosition = { x = 0, y = 0, width = 0, height = 0 }

-- Affirmation messages
local affirmations = {
    "Nice!",
    "Awesome!",
    "Great!",
    "Wow!",
    "Amazing!",
    "Killer!",
    "Fantastic!",
    "Sweet!",
    "Boom!",
    "Unstoppable!"
}

-- Initialize the combo manager and set up event listeners
function ComboManager.initialize()
    -- Reset combo state
    comboCount = 0
    comboText = nil
    comboTimer = 0
    affirmationText = nil
    affirmationTimer = 0
    
end

-- Event handler for enemy kills - increments combo
function ComboManager.onEnemyKill(data)
    -- Increment combo counter
    comboCount = comboCount + 1
    -- Set up combo text display
    comboText = comboCount .. "X"  -- Simple counter
    comboTimer = comboMaxTime
    comboScale = 1.0  -- No scaling for regular counter
    comboAngle = 0    -- No rotation for regular counter
    
    -- Position the combo text directly above the player's head
    comboX = playerPosition.x + playerPosition.width/2
    comboY = playerPosition.y - 60
    
    -- No offset for the counter display - keep it steady
    comboOffsetX = 0
    comboOffsetY = 0
    
    -- Only show affirmation when reaching 5 or higher
    if comboCount == 5 then
        ComboManager.showAffirmation(true)  -- true indicates this is the first time reaching 5
    elseif comboCount > 5 and comboCount % 3 == 0 then
        -- Additional affirmations at every 3rd combo after 5
        ComboManager.showAffirmation(false)
    end
    
    -- Notify other systems of the combo increment
    Events.fire("comboIncremented", {
        count = comboCount,
        x = comboX,
        y = comboY
    })
end

-- Handle player being hit - resets combo
function ComboManager.onPlayerHit()
    -- Only do something if we actually have a combo to reset
    if comboCount > 0 then
        ComboManager.resetCombo()
    end
end

-- Handle player landing on ground - resets combo
function ComboManager.onPlayerLanded()
    -- Only do something if we actually have a combo to reset
    if comboCount > 0 then
        ComboManager.resetCombo()
    end
end

-- Display affirmation text (for combo milestones)
function ComboManager.showAffirmation(isFirstThreshold)
    -- Only show affirmation for combos of 5 or higher
    if comboCount < 5 then
        return
    end
    
    -- Different text for first time reaching 5
    local displayText
    if isFirstThreshold then
        displayText = "COMBO STARTED! " .. affirmations[1]
    else
        -- Higher combo = stronger affirmations
        local affirmationIndex = math.min(math.floor((comboCount - 5) / 3) + 2, #affirmations)
        displayText = comboCount .. "X COMBO! " .. affirmations[affirmationIndex]
    end
    
    affirmationText = displayText
    
    -- Position affirmation text slightly above combo text
    affirmationX = playerPosition.x + playerPosition.width/2
    affirmationY = playerPosition.y - 90
    affirmationTimer = comboMaxTime
    affirmationScale = 1.5  -- Larger initial scale for pop effect
    affirmationAngle = love.math.random(-15, 15) * 0.01
    affirmationOffsetX = love.math.random(-15, 15)
    affirmationOffsetY = -love.math.random(10, 20)
    
    -- Make affirmation effects more dramatic for higher combos
    if comboCount >= 8 then
        -- Bigger scale and movement for higher combos
        affirmationScale = affirmationScale + ((comboCount - 5) * 0.1)
        affirmationOffsetX = affirmationOffsetX * (1 + (comboCount - 5) * 0.1)
        affirmationOffsetY = affirmationOffsetY * (1 + (comboCount - 5) * 0.1)
    end
end

-- Reset the current combo
function ComboManager.resetCombo()
    -- Store the combo count before resetting it
    local oldComboCount = comboCount
    
    -- Only show an affirmation if we had a significant combo
    if oldComboCount >= 5 then
        -- Show the combo text with animation as it's ending
        comboText = oldComboCount .. "X COMBO!"
        comboTimer = comboMaxTime
        
        -- Position the combo text directly above the player's head
        comboX = playerPosition.x + playerPosition.width/2
        comboY = playerPosition.y - 60
        
        -- Add subtle animation
        comboOffsetX = 0
        comboOffsetY = 0
        
        -- Create an affirmation message for ending the combo
        affirmationText = "Combo Ended!"
        
        -- Position affirmation text above combo text
        affirmationX = playerPosition.x + playerPosition.width/2
        affirmationY = playerPosition.y - 90
        affirmationTimer = comboMaxTime
        affirmationOffsetX = 0
        affirmationOffsetY = 0
    else
        -- For minor combos, just clear the display with no animation
        comboText = nil
        comboTimer = 0
        affirmationText = nil
        affirmationTimer = 0
    end
    
    -- Fire event before resetting count so listeners can get the final value
    Events.fire("comboReset", {
        finalCount = comboCount,
        x = comboX,
        y = comboY
    })
    
    -- Now reset the combo count
    comboCount = 0
end

-- Update animations and timers
function ComboManager.update(dt,player)
    playerPosition.x = player.x
    playerPosition.y = player.y
    playerPosition.width = player.width
    playerPosition.height = player.height
    
    -- Update combo text positions to follow player (but keep animation offsets)
    if comboText and comboTimer > 0 then
        comboX = playerPosition.x + playerPosition.width/2
        comboY = playerPosition.y - 60
    end
    
    -- Update affirmation text positions to follow player (but keep animation offsets)
    if affirmationText and affirmationTimer > 0 then
        affirmationX = playerPosition.x + playerPosition.width/2
        affirmationY = playerPosition.y - 90
    end
    -- Update combo text animation
    if comboText and comboTimer > 0 then
        -- Update timer
        comboTimer = comboTimer - dt
        
        -- Only animate when combo is reset/ending
        if comboCount == 0 then
            -- Subtle left-right movement
            comboOffsetX = 5 * math.sin(comboTimer * 8)
            
            -- Subtle rotation
            comboAngle = 0.05 * math.sin(comboTimer * 10)
            
            -- Gradual upward drift
            comboOffsetY = comboOffsetY - 15 * dt
        else
            -- Static position for active combo counter
            comboAngle = 0
            comboOffsetX = 0
            -- No vertical animation for active combo counter
        end
        
        -- Fade out when close to expiring
        if comboTimer <= 0 then
            comboText = nil
        end
    end
    
    -- Update affirmation text animation
    if affirmationText and affirmationTimer > 0 then
        -- Update timer
        affirmationTimer = affirmationTimer - dt
        
        -- Simple left-right movement
        affirmationOffsetX = 8 * math.sin(affirmationTimer * 6)
        
        -- Simple rotation
        affirmationAngle = 0.08 * math.sin(affirmationTimer * 8)
        
        -- Steady upward movement
        affirmationOffsetY = affirmationOffsetY - 25 * dt
        
        -- Fade out when close to expiring
        if affirmationTimer <= 0 then
            affirmationText = nil
        end
    end
end

-- Draw combo text and affirmations
function ComboManager.draw()
    -- Draw combo text with simpler effects if active
    if comboText and comboTimer > 0 then
        -- Calculate opacity based on remaining time
        local opacity = math.min(1, comboTimer / (comboMaxTime * 0.5))
        
        -- Get text width for centering
        local textWidth = love.graphics.getFont():getWidth(comboText)
        
        -- Calculate display position (centered on player)
        local displayX = comboX + comboOffsetX - textWidth/2
        local displayY = comboY + comboOffsetY
        
        -- Save current transform state
        love.graphics.push()
        
        -- Apply rotation from center point - simpler transformation
        love.graphics.translate(displayX + textWidth/2, displayY)
        love.graphics.rotate(comboAngle)
        
        -- Just a single shadow for active combo counter
        if comboCount > 0 then
            -- Simple display for active combo
            love.graphics.setColor(0.5, 0.5, 0.5, opacity * 0.7)
            love.graphics.print(comboText, -textWidth/2 + 1, 1)
            
            -- Main text - neutral color for active combo
            love.graphics.setColor(1, 1, 1, opacity)
            love.graphics.print(comboText, -textWidth/2, 0)
        else
            -- More visible styling for ended combo animation
            -- Shadow
            love.graphics.setColor(0.6, 0.2, 0.2, opacity * 0.7)
            love.graphics.print(comboText, -textWidth/2 + 2, 2)
            
            -- Main text - red tint for ended combo
            love.graphics.setColor(1, 0.4, 0.4, opacity)
            love.graphics.print(comboText, -textWidth/2, 0)
        end
        
        -- Restore transform state
        love.graphics.pop()
    end
    
    -- Draw affirmation text with simplified effect if active
    if affirmationText and affirmationTimer > 0 then
        -- Calculate opacity based on remaining time
        local opacity = math.min(1, affirmationTimer / (comboMaxTime * 0.5))
        
        -- Get text width for centering
        local textWidth = love.graphics.getFont():getWidth(affirmationText)
        
        -- Calculate display position (centered on player)
        local displayX = affirmationX + affirmationOffsetX - textWidth/2
        local displayY = affirmationY + affirmationOffsetY
        
        -- Save current transform state
        love.graphics.push()
        
        -- Apply rotation from center point
        love.graphics.translate(displayX + textWidth/2, displayY)
        love.graphics.rotate(affirmationAngle)
        
        -- Draw shadow layer
        love.graphics.setColor(0.7, 0.2, 0.2, opacity * 0.7)
        love.graphics.print(affirmationText, -textWidth/2 + 2, 2)
        
        -- Draw main text
        love.graphics.setColor(1, 0.6, 0.6, opacity)
        love.graphics.print(affirmationText, -textWidth/2, 0)
        
        -- Restore transform state
        love.graphics.pop()
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Get the current combo count
function ComboManager.getComboCount()
    return comboCount
end

-- Reset the combo display parameters (for game restart)
function ComboManager.reset()
    comboCount = 0
    comboText = nil
    comboTimer = 0
    affirmationText = nil
    affirmationTimer = 0
end

-- Helper function to set combo max time (for upgrades)
function ComboManager.setComboMaxTime(time)
    comboMaxTime = time
end

-- Export the module
return ComboManager