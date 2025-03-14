-- lib/spatial/spatialHash.lua
-- Spatial Hash Grid implementation for collision detection

local SpatialHash = {}
SpatialHash.__index = SpatialHash

function SpatialHash.create(cellSize)
    local self = setmetatable({}, SpatialHash)
    
    -- Cell size (objects larger than this will span multiple cells)
    self.cellSize = cellSize or 64
    
    -- Grid cells (sparse)
    self.cells = {}
    
    -- Object to cell mappings
    self.objectCells = {}
    
    return self
end

-- Clear the spatial hash
function SpatialHash:clear()
    self.cells = {}
    self.objectCells = {}
end

-- Get cell coordinates for a point
function SpatialHash:getCellCoords(x, y)
    local cellX = math.floor(x / self.cellSize)
    local cellY = math.floor(y / self.cellSize)
    return cellX, cellY
end

-- Get cell key from coordinates
function SpatialHash:getCellKey(cellX, cellY)
    return cellX .. "," .. cellY
end

-- Get all cells that an object overlaps
function SpatialHash:getOverlappingCells(bounds)
    local cells = {}
    
    -- Check if bounds is nil and return empty cells array
    if not bounds then
        print("Warning: Attempted to get overlapping cells with nil bounds")
        return cells
    end
    
    -- Get the cell coordinates for each corner of the bounds
    local x1, y1 = self:getCellCoords(bounds.x, bounds.y)
    local x2, y2 = self:getCellCoords(bounds.x + bounds.width, bounds.y + bounds.height)
    
    -- Iterate through all cells that the object overlaps
    for x = x1, x2 do
        for y = y1, y2 do
            local key = self:getCellKey(x, y)
            table.insert(cells, key)
        end
    end
    
    return cells
end

-- Insert an object into the spatial hash
function SpatialHash:insert(object)
    -- Check if object or object.bounds is nil
    if not object or not object.bounds then
        print("Warning: Attempted to insert object with nil bounds into spatial hash")
        return
    end
    
    -- Get all cells that the object overlaps
    local cells = self:getOverlappingCells(object.bounds)
    
    -- Store which cells this object is in
    self.objectCells[object] = cells
    
    -- Add the object to each cell
    for _, key in ipairs(cells) do
        if not self.cells[key] then
            self.cells[key] = {}
        end
        
        table.insert(self.cells[key], object)
    end
end

-- Remove an object from the spatial hash
function SpatialHash:remove(object)
    -- Check if object is nil
    if not object then
        print("Warning: Attempted to remove nil object from spatial hash")
        return
    end
    
    -- Get the cells this object is in
    local cells = self.objectCells[object]
    
    if not cells then
        return
    end
    
    -- Remove the object from each cell
    for _, key in ipairs(cells) do
        if self.cells[key] then
            for i = #self.cells[key], 1, -1 do
                if self.cells[key][i] == object then
                    table.remove(self.cells[key], i)
                    break
                end
            end
        end
    end
    
    -- Clear the object's cell mappings
    self.objectCells[object] = nil
end

-- Update an object's position in the spatial hash
function SpatialHash:update(object)
    -- Check if object is nil
    if not object then
        print("Warning: Attempted to update nil object in spatial hash")
        return
    end
    
    -- Remove the object from its current cells
    self:remove(object)
    
    -- Insert it at its new position
    self:insert(object)
end

-- Get all objects that could potentially collide with the given object
function SpatialHash:getPotentialCollisions(object)
    local result = {}
    local resultSet = {} -- For deduplication
    
    -- Check if object or object.bounds is nil
    if not object or not object.bounds then
        print("Warning: Attempted to get potential collisions with nil bounds")
        return result
    end
    
    -- Get all cells that the object overlaps
    local cells = self:getOverlappingCells(object.bounds)
    
    -- Collect all objects in those cells
    for _, key in ipairs(cells) do
        if self.cells[key] then
            for _, other in ipairs(self.cells[key]) do
                -- Skip self and already added objects
                if other ~= object and not resultSet[other] then
                    resultSet[other] = true
                    table.insert(result, other)
                end
            end
        end
    end
    
    return result
end

-- Draw the spatial hash (for debugging)
function SpatialHash:draw(viewportX, viewportY, viewportWidth, viewportHeight)
    -- Calculate visible cells
    local startX, startY = self:getCellCoords(viewportX, viewportY)
    local endX, endY = self:getCellCoords(viewportX + viewportWidth, viewportY + viewportHeight)
    
    -- Draw grid lines
    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    
    -- Vertical lines
    for x = startX, endX do
        local screenX = x * self.cellSize
        love.graphics.line(screenX, viewportY, screenX, viewportY + viewportHeight)
    end
    
    -- Horizontal lines
    for y = startY, endY do
        local screenY = y * self.cellSize
        love.graphics.line(viewportX, screenY, viewportX + viewportWidth, screenY)
    end
    
    -- Draw occupied cells
    love.graphics.setColor(1, 0, 0, 0.2)
    
    for x = startX, endX do
        for y = startY, endY do
            local key = self:getCellKey(x, y)
            
            if self.cells[key] and #self.cells[key] > 0 then
                love.graphics.rectangle("fill", 
                    x * self.cellSize, 
                    y * self.cellSize, 
                    self.cellSize, 
                    self.cellSize)
            end
        end
    end
end

return SpatialHash 