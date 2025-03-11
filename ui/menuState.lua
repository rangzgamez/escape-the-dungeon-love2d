-- menuState.lua

local MenuState = {}
MenuState.__index = MenuState

function MenuState:new()
    local self = setmetatable({}, MenuState)
    
    self.options = {
        { title = "Play Game", action = "startGame" },
        { title = "Settings", action = "showSettings" },
        { title = "How to Play", action = "showTutorial" },
        { title = "Credits", action = "showCredits" },
        { title = "Quit", action = "quitGame" }
    }
    
    self.selectedOption = 1
    self.titleFont = love.graphics.newFont(48)
    self.menuFont = love.graphics.newFont(32)
    
    -- Add particle system for background effect
    self.particles = love.graphics.newParticleSystem(love.graphics.newCanvas(4, 4), 100)
    self.particles:setParticleLifetime(2, 6)
    self.particles:setEmissionRate(20)
    self.particles:setSizeVariation(1)
    self.particles:setLinearAcceleration(-20, 20, 20, 40)
    self.particles:setColors(0.3, 0.3, 0.5, 1, 0.1, 0.1, 0.3, 0)
    self.particles:setSizes(2, 5, 3)
    
    return self
end

function MenuState:update(dt)
    self.particles:update(dt)
end

function MenuState:draw()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw particles
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.particles, love.graphics.getWidth()/2, 0)
    
    -- Draw title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Vertical Jumper", 0, 100, love.graphics.getWidth(), "center")
    
    -- Draw menu options
    love.graphics.setFont(self.menuFont)
    for i, option in ipairs(self.options) do
        if i == self.selectedOption then
            love.graphics.setColor(1, 0.8, 0)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        
        love.graphics.printf(option.title, 0, 250 + (i-1) * 60, love.graphics.getWidth(), "center")
    end
    
    -- Draw version
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Version 1.0", 0, love.graphics.getHeight() - 30, love.graphics.getWidth(), "center")
end

function MenuState:keypressed(key)
    if key == "up" then
        self.selectedOption = self.selectedOption - 1
        if self.selectedOption < 1 then
            self.selectedOption = #self.options
        end
    elseif key == "down" then
        self.selectedOption = self.selectedOption + 1
        if self.selectedOption > #self.options then
            self.selectedOption = 1
        end
    elseif key == "return" or key == "space" then
        self:selectOption()
    end
end

function MenuState:mousemoved(x, y)
    -- Check if mouse is over any option
    for i, option in ipairs(self.options) do
        local optionY = 250 + (i-1) * 60
        if y >= optionY and y <= optionY + 40 then
            self.selectedOption = i
            break
        end
    end
end

function MenuState:mousepressed(x, y, button)
    if button == 1 then -- Left click
        -- Check if clicked on any option
        for i, option in ipairs(self.options) do
            local optionY = 250 + (i-1) * 60
            if y >= optionY and y <= optionY + 40 then
                self.selectedOption = i
                self:selectOption()
                break
            end
        end
    end
end

function MenuState:selectOption()
    local action = self.options[self.selectedOption].action
    
    if action == "startGame" then
        -- Start the game
        gameState = "playing"
    elseif action == "showSettings" then
        -- Show settings menu
        gameState = "settings"
    elseif action == "showTutorial" then
        -- Show tutorial
        gameState = "tutorial"
    elseif action == "showCredits" then
        -- Show credits
        gameState = "credits"
    elseif action == "quitGame" then
        -- Quit the game
        love.event.quit()
    end
end

return MenuState
