-- levelUpMenu.lua - Menu shown when player levels up to select a powerup
local Events = require("lib/events")

local LevelUpMenu = {}
LevelUpMenu.__index = LevelUpMenu

-- Powerup definitions with descriptions and visuals
local POWERUP_DEFINITIONS = {
    HEALTH_MAX = {
        name = "Max Health",
        description = "Increase your maximum health by 1",
        icon = "heart",
        color = {1, 0.2, 0.2}
    },
    DOUBLE_JUMP = {
        name = "Air Mastery",
        description = "Gain an additional mid-air jump",
        icon = "wings",
        color = {0.2, 1, 0.2}
    },
    DASH_POWER = {
        name = "Dash Power",
        description = "Increase dash speed by 20%",
        icon = "lightning",
        color = {0.2, 0.2, 1}
    },
    DASH_DURATION = {
        name = "Dash Duration",
        description = "Increase maximum dash duration by 20%",
        icon = "clock",
        color = {0.2, 0.8, 1}
    },
    COLLECTION_RADIUS = {
        name = "XP Magnet",
        description = "Increase XP collection radius by 20",
        icon = "magnet",
        color = {1, 0.5, 0.8}
    },
    SPEED = {
        name = "Swift Movement",
        description = "Increase horizontal movement speed by 15%",
        icon = "boots",
        color = {1, 0.8, 0.2}
    },
    SHIELD = {
        name = "Shield",
        description = "Gain a shield that absorbs damage",
        icon = "shield",
        color = {0.5, 0.5, 1}
    },
    COMBO_DURATION = {
        name = "Combo Master",
        description = "Increase combo duration by 1 second",
        icon = "star",
        color = {1, 0.5, 0.2}
    },
    TIME_DILATION = {
        name = "Time Dilation",
        description = "Increase initial time slowdown when aiming",
        icon = "clock-slow",
        color = {0.7, 0.3, 1.0}
    },
    TIME_EXTENSION = {
        name = "Time Extension",
        description = "Extend duration of time slowdown effect",
        icon = "hourglass",
        color = {1.0, 0.5, 0.8}
    },
}

function LevelUpMenu:new(player)
    local self = setmetatable({}, LevelUpMenu)
    
    self.player = player
    self.visible = false
    self.options = {}
    self.selectedOption = nil
    
    -- UI properties - Fixed dimensions that work for 3 options
    self.width = 320
    self.height = 480  -- Increased height to ensure everything fits
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    
    -- Option positions - These won't change
    self.optionHeight = 100
    self.optionPadding = 15
    self.optionsStartY = 120
    
    -- Animation properties
    self.animationTime = 0
    self.animationDuration = 0.5
    self.scale = 0.8
    
    return self
end

function LevelUpMenu:show()
    -- Generate three random unique options
    self.options = self:generateOptions(3)
    
    -- Reset selection
    self.selectedOption = nil
    
    -- Start animation
    self.visible = true
    self.animationTime = 0
    self.scale = 0.8
    
    -- Fire event
    Events.fire("levelUpMenuShown", {})
    
    return true
end

function LevelUpMenu:hide()
    self.visible = false
    self.options = {}
    self.selectedOption = nil
    
    -- Fire event
    Events.fire("levelUpMenuHidden", {})
    
    return true
end

function LevelUpMenu:generateOptions(count)
    local options = {}
    local availableTypes = {}
    
    -- Build list of available powerup types
    for type, _ in pairs(POWERUP_DEFINITIONS) do
        table.insert(availableTypes, type)
    end
    
    -- Shuffle the list
    for i = #availableTypes, 2, -1 do
        local j = love.math.random(i)
        availableTypes[i], availableTypes[j] = availableTypes[j], availableTypes[i]
    end
    
    -- Take the first 'count' options
    for i = 1, math.min(count, #availableTypes) do
        local optionType = availableTypes[i]
        local definition = POWERUP_DEFINITIONS[optionType]
        
        -- Determine current level and enhancement text
        local currentLevel = 0
        if self.player.powerupLevels then
            currentLevel = self.player.powerupLevels[optionType] or 0
        end
        local levelText = currentLevel > 0 and " (Level " .. currentLevel .. " → " .. (currentLevel + 1) .. ")" or ""
        
        -- Create option data
        table.insert(options, {
            type = optionType,
            name = definition.name .. levelText,
            description = definition.description,
            icon = definition.icon,
            color = definition.color,
            hover = false
        })
    end
    
    return options
end

function LevelUpMenu:update(dt)
    if not self.visible then return end
    
    -- Update animation
    if self.animationTime < self.animationDuration then
        self.animationTime = self.animationTime + dt
        local progress = math.min(1, self.animationTime / self.animationDuration)
        self.scale = 0.8 + progress * 0.2 -- Scale from 0.8 to 1.0
    end
end
function LevelUpMenu:handleInputStart(x, y, button)
    return self:mousepressed(x, y, button or 1)
end

function LevelUpMenu:handleInputMove(x, y)
    return self:mousemoved(x, y)
end
function LevelUpMenu:draw()
    if not self.visible then return end
    
    -- Create a full-screen modal overlay
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Darken background - 70% opaque black overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw menu panel with scale animation
    love.graphics.push()
    love.graphics.translate(
        self.x + self.width/2, 
        self.y + self.height/2
    )
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(
        -self.width/2, 
        -self.height/2
    )
    
    -- Menu background with subtle shadow effect
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 4, 4, self.width, self.height, 10, 10)
    
    -- Menu background
    love.graphics.setColor(0.15, 0.15, 0.22)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 10, 10)
    
    -- Menu border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", 0, 0, self.width, self.height, 10, 10)
    
    -- Header background
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 0, 0, self.width, 50, 10, 10)
    love.graphics.rectangle("fill", 0, 40, self.width, 30)
    
    -- Title with glow effect
    -- Glow
    love.graphics.setColor(0.4, 0.6, 1, 0.3)
    love.graphics.printf("LEVEL UP!", -2, 18, self.width, "center")
    love.graphics.printf("LEVEL UP!", 2, 22, self.width, "center")
    love.graphics.printf("LEVEL UP!", -2, 22, self.width, "center")
    love.graphics.printf("LEVEL UP!", 2, 18, self.width, "center")
    
    -- Main title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("LEVEL UP!", 0, 20, self.width, "center")
    
    -- Subtitle
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.printf("Level " .. (self.player.level or "?"), 0, 60, self.width, "center")
    love.graphics.printf("Choose an upgrade:", 0, 85, self.width, "center")
    
    -- Draw options
    for i, option in ipairs(self.options) do
        self:drawOption(option, i)
    end
    
    -- Instructions at the bottom
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.printf("Click on an upgrade to select it", 0, self.height - 30, self.width, "center")
    
    love.graphics.pop()
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function LevelUpMenu:drawOption(option, index)
    local y = self.optionsStartY + (index - 1) * (self.optionHeight + self.optionPadding)
    
    -- Background color (highlight if hovered)
    if option.hover then
        love.graphics.setColor(0.3, 0.3, 0.4)
    else
        love.graphics.setColor(0.2, 0.2, 0.3)
    end
    
    -- Option background
    love.graphics.rectangle("fill", 10, y, self.width - 20, self.optionHeight, 5, 5)
    
    -- Color accent on the left
    love.graphics.setColor(option.color)
    love.graphics.rectangle("fill", 10, y, 5, self.optionHeight, 2, 2)
    
    -- Icon (placeholder - we'll use basic shapes for now)
    love.graphics.setColor(option.color)
    love.graphics.circle("fill", 35, y + self.optionHeight/2, 15)
    
    -- Option text - now with proper wrapping
    love.graphics.setColor(1, 1, 1)
    
    -- For title, ensure it doesn't get too long by trimming if needed
    local title = option.name
    local font = love.graphics.getFont()
    local maxWidth = self.width - 90 -- Available width for text
    
    if font:getWidth(title) > maxWidth then
        -- Trim title and add ellipsis if too long
        local trimmed = ""
        for i = 1, #title do
            local testStr = title:sub(1, i) .. "..."
            if font:getWidth(testStr) > maxWidth then
                trimmed = title:sub(1, i-1) .. "..."
                break
            end
        end
        title = trimmed
    end
    
    -- Draw the title
    love.graphics.printf(title, 60, y + 15, maxWidth, "left")
    
    -- For description, use printf with wrapping
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf(option.description, 60, y + 40, maxWidth, "left")
end

-- Mouse moved - check for option hover
function LevelUpMenu:mousemoved(x, y)
    if not self.visible then return false end
    
    -- Convert to local coordinates
    local localX, localY = self:globalToLocal(x, y)
    
    -- Check each option with proper spacing
    for i, option in ipairs(self.options) do
        local optionY = self.optionsStartY + (i - 1) * (self.optionHeight + self.optionPadding)
        
        -- Check if mouse is over this option
        if localX >= 10 and localX <= self.width - 10 and
           localY >= optionY and localY <= optionY + self.optionHeight then
            option.hover = true
        else
            option.hover = false
        end
    end
    
    return true
end

-- Mouse pressed - check for option selection
function LevelUpMenu:mousepressed(x, y, button)
    if not self.visible or button ~= 1 then return false end
    
    -- Convert to local coordinates
    local localX, localY = self:globalToLocal(x, y)
    
    -- Check each option with proper spacing
    for i, option in ipairs(self.options) do
        local optionY = self.optionsStartY + (i - 1) * (self.optionHeight + self.optionPadding)
        
        -- Check if mouse is over this option
        if localX >= 10 and localX <= self.width - 10 and
           localY >= optionY and localY <= optionY + self.optionHeight then
            -- Select this option
            self:selectOption(i)
            return true
        end
    end
    
    return false
end

-- Touch pressed - same as mouse pressed
function LevelUpMenu:touchpressed(id, x, y)
    return self:mousepressed(x, y, 1)
end

-- Global to local coordinate conversion (accounts for scale and translation)
function LevelUpMenu:globalToLocal(x, y)
    -- Account for the panel's position and scale
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local s = self.scale
    
    -- Convert to local coordinates
    local localX = (x - centerX) / s + self.width/2
    local localY = (y - centerY) / s + self.height/2
    
    return localX, localY
end

-- Select an option
function LevelUpMenu:selectOption(index)
    if not self.options[index] then return false end
    
    self.selectedOption = index
    local option = self.options[index]
    
    -- Apply the powerup
    if self.player.applyPowerup then
        self.player:applyPowerup(option.type)
    end
    
    -- Fire event
    Events.fire("powerupSelected", {
        player = self.player,
        type = option.type,
        name = option.name
    })
    
    -- Hide the menu
    self:hide()
    
    -- Clear the level-up pending flag
    if self.player.levelUpPending ~= nil then
        self.player.levelUpPending = false
    end
    
    return true
end

-- Check if the menu is currently visible
function LevelUpMenu:isVisible()
    return self.visible
end

-- Get the currently selected option (if any)
function LevelUpMenu:getSelectedOption()
    if not self.selectedOption then return nil end
    return self.options[self.selectedOption]
end

return LevelUpMenu