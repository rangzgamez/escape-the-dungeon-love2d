local Background = {}
Background.__index = Background

function Background:new()
    local self = setmetatable({}, Background)
    
    -- Create canvas for each layer
    self.layers = {
        -- Far mountains (slow)
        {
            canvas = love.graphics.newCanvas(love.graphics.getWidth() * 1.5, 300),
            speed = 0.1,
            y = love.graphics.getHeight() - 300,
            offset = 0
        },
        -- Clouds (medium)
        {
            canvas = love.graphics.newCanvas(love.graphics.getWidth() * 2, 200),
            speed = 0.3,
            y = love.graphics.getHeight() - 500,
            offset = 0
        },
        -- Foreground elements (fast)
        {
            canvas = love.graphics.newCanvas(love.graphics.getWidth() * 2, 150),
            speed = 0.5,
            y = love.graphics.getHeight() - 150,
            offset = 0
        }
    }
    
    -- Initialize canvases with layer contents
    self:initializeLayers()
    
    return self
end

function Background:initializeLayers()
    -- Far mountains
    love.graphics.setCanvas(self.layers[1].canvas)
    love.graphics.clear()
    love.graphics.setColor(0.3, 0.3, 0.4)
    
    -- Generate mountains
    local width = self.layers[1].canvas:getWidth()
    local height = self.layers[1].canvas:getHeight()
    
    -- Draw several mountains
    for i = 0, width, 100 do
        local mHeight = love.math.random(100, 250)
        love.graphics.polygon("fill", 
            i, height, 
            i + 50, height - mHeight,
            i + 100, height
        )
    end
    
    -- Clouds
    love.graphics.setCanvas(self.layers[2].canvas)
    love.graphics.clear()
    
    -- Draw clouds
    for i = 0, width, 150 do
        local cloudWidth = love.math.random(80, 150)
        local cloudHeight = love.math.random(40, 80)
        local yPos = love.math.random(20, 150)
        
        love.graphics.setColor(0.8, 0.8, 0.9, 0.7)
        for j = 0, 3 do
            local xOffset = love.math.random(-20, 20)
            local yOffset = love.math.random(-10, 10)
            love.graphics.circle("fill", i + xOffset, yPos + yOffset, cloudHeight/2)
        end
    end
    
    -- Foreground elements
    love.graphics.setCanvas(self.layers[3].canvas)
    love.graphics.clear()
    
    -- Draw trees or buildings
    for i = 0, width, 70 do
        if love.math.random() < 0.7 then
            -- Tree
            local treeHeight = love.math.random(80, 120)
            love.graphics.setColor(0.5, 0.3, 0.2)
            love.graphics.rectangle("fill", i, height - treeHeight, 10, treeHeight)
            
            love.graphics.setColor(0.2, 0.5, 0.3)
            love.graphics.circle("fill", i + 5, height - treeHeight, 20)
        else
            -- Building
            local buildingHeight = love.math.random(60, 100)
            local buildingWidth = love.math.random(30, 50)
            
            love.graphics.setColor(0.5, 0.5, 0.6)
            love.graphics.rectangle("fill", i, height - buildingHeight, buildingWidth, buildingHeight)
            
            -- Windows
            love.graphics.setColor(0.9, 0.9, 0.6, 0.7)
            for y = height - buildingHeight + 10, height - 10, 15 do
                for x = i + 5, i + buildingWidth - 10, 10 do
                    if love.math.random() < 0.7 then
                        love.graphics.rectangle("fill", x, y, 5, 5)
                    end
                end
            end
        end
    end
    
    -- Reset canvas
    love.graphics.setCanvas()
end

function Background:update(dt, cameraY)
    -- Update layer offsets based on camera position
    for i, layer in ipairs(self.layers) do
        layer.offset = cameraY * layer.speed % layer.canvas:getWidth()
    end
end

function Background:draw()
    love.graphics.setColor(1, 1, 1)
    
    -- Draw each layer with parallax effect
    for i, layer in ipairs(self.layers) do
        local x = -layer.offset
        
        -- Draw main section
        love.graphics.draw(layer.canvas, x, layer.y)
        
        -- Draw repeated section if needed
        if x + layer.canvas:getWidth() < love.graphics.getWidth() then
            love.graphics.draw(layer.canvas, x + layer.canvas:getWidth(), layer.y)
        end
    end
end

return Background