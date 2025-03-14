-- lib/spatial/quadtree.lua
-- Quadtree implementation for spatial partitioning

local Quadtree = {}
Quadtree.__index = Quadtree

-- Constants
local MAX_OBJECTS = 10
local MAX_LEVELS = 5

-- Create a new quadtree
function Quadtree.create(level, bounds)
    local self = setmetatable({}, Quadtree)
    
    -- Current level (0 is top level)
    self.level = level or 0
    
    -- Bounds of this quadtree node
    self.bounds = bounds or {x = 0, y = 0, width = 0, height = 0}
    
    -- Objects in this node
    self.objects = {}
    
    -- Child nodes
    self.nodes = {}
    
    return self
end

-- Clear the quadtree
function Quadtree:clear()
    -- Clear objects
    self.objects = {}
    
    -- Clear child nodes
    for i = 1, 4 do
        if self.nodes[i] then
            self.nodes[i]:clear()
            self.nodes[i] = nil
        end
    end
end

-- Split the node into 4 subnodes
function Quadtree:split()
    local subWidth = self.bounds.width / 2
    local subHeight = self.bounds.height / 2
    local x = self.bounds.x
    local y = self.bounds.y
    
    -- Top right
    self.nodes[1] = Quadtree.create(self.level + 1, {
        x = x + subWidth,
        y = y,
        width = subWidth,
        height = subHeight
    })
    
    -- Top left
    self.nodes[2] = Quadtree.create(self.level + 1, {
        x = x,
        y = y,
        width = subWidth,
        height = subHeight
    })
    
    -- Bottom left
    self.nodes[3] = Quadtree.create(self.level + 1, {
        x = x,
        y = y + subHeight,
        width = subWidth,
        height = subHeight
    })
    
    -- Bottom right
    self.nodes[4] = Quadtree.create(self.level + 1, {
        x = x + subWidth,
        y = y + subHeight,
        width = subWidth,
        height = subHeight
    })
end

-- Determine which node the object belongs to
function Quadtree:getIndex(rect)
    local index = 0
    local verticalMidpoint = self.bounds.x + (self.bounds.width / 2)
    local horizontalMidpoint = self.bounds.y + (self.bounds.height / 2)
    
    -- Object can completely fit within the top quadrants
    local topQuadrant = (rect.y < horizontalMidpoint and 
                         rect.y + rect.height < horizontalMidpoint)
    
    -- Object can completely fit within the bottom quadrants
    local bottomQuadrant = (rect.y > horizontalMidpoint)
    
    -- Object can completely fit within the left quadrants
    if (rect.x < verticalMidpoint and 
        rect.x + rect.width < verticalMidpoint) then
        if topQuadrant then
            index = 2
        elseif bottomQuadrant then
            index = 3
        end
    -- Object can completely fit within the right quadrants
    elseif (rect.x > verticalMidpoint) then
        if topQuadrant then
            index = 1
        elseif bottomQuadrant then
            index = 4
        end
    end
    
    return index
end

-- Insert an object into the quadtree
function Quadtree:insert(object)
    -- If we have subnodes, insert the object into the appropriate subnode
    if #self.nodes > 0 then
        local index = self:getIndex(object.bounds)
        
        if index > 0 then
            self.nodes[index]:insert(object)
            return
        end
    end
    
    -- Otherwise, add the object to this node
    table.insert(self.objects, object)
    
    -- Split if needed and move objects to subnodes
    if #self.objects > MAX_OBJECTS and self.level < MAX_LEVELS then
        -- Split if we don't already have subnodes
        if #self.nodes == 0 then
            self:split()
        end
        
        -- Attempt to move objects down to subnodes
        local i = 1
        while i <= #self.objects do
            local index = self:getIndex(self.objects[i].bounds)
            
            if index > 0 then
                local object = table.remove(self.objects, i)
                self.nodes[index]:insert(object)
            else
                i = i + 1
            end
        end
    end
end

-- Return all objects that could collide with the given object
function Quadtree:retrieve(returnObjects, object)
    returnObjects = returnObjects or {}
    
    local index = self:getIndex(object.bounds)
    
    -- If we have subnodes and the object fits in a subnode, check that subnode
    if index > 0 and #self.nodes > 0 then
        self.nodes[index]:retrieve(returnObjects, object)
    else
        -- Otherwise, check all subnodes
        for i = 1, #self.nodes do
            if self.nodes[i] then
                self.nodes[i]:retrieve(returnObjects, object)
            end
        end
    end
    
    -- Add all objects in this node
    for i = 1, #self.objects do
        table.insert(returnObjects, self.objects[i])
    end
    
    return returnObjects
end

-- Draw the quadtree (for debugging)
function Quadtree:draw()
    -- Draw this node
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height)
    
    -- Draw child nodes
    for i = 1, #self.nodes do
        if self.nodes[i] then
            self.nodes[i]:draw()
        end
    end
end

return Quadtree 