-- lib/ecs/spatialPartition.lua
-- Spatial Partitioning system for the Entity Component System

local SpatialPartition = {}

-- Create a new spatial partition grid
function SpatialPartition.createGrid(cellSize, worldBounds)
    local grid = {
        cellSize = cellSize or 100, -- Default cell size
        cells = {}, -- Grid cells containing entities
        entityMap = {}, -- Maps entity IDs to their cell positions
        worldBounds = worldBounds or { -- Default world bounds
            minX = -10000,
            minY = -10000,
            maxX = 10000,
            maxY = 10000
        }
    }
    
    -- Calculate grid dimensions based on world bounds
    grid.width = math.ceil((grid.worldBounds.maxX - grid.worldBounds.minX) / grid.cellSize)
    grid.height = math.ceil((grid.worldBounds.maxY - grid.worldBounds.minY) / grid.cellSize)
    
    -- Convert world coordinates to cell coordinates
    function grid:worldToCell(x, y)
        local cellX = math.floor((x - self.worldBounds.minX) / self.cellSize) + 1
        local cellY = math.floor((y - self.worldBounds.minY) / self.cellSize) + 1
        
        -- Clamp to grid bounds
        cellX = math.max(1, math.min(cellX, self.width))
        cellY = math.max(1, math.min(cellY, self.height))
        
        return cellX, cellY
    end
    
    -- Get cell key from cell coordinates
    function grid:getCellKey(cellX, cellY)
        return cellX .. "," .. cellY
    end
    
    -- Get cell key from world coordinates
    function grid:getCellKeyFromWorld(x, y)
        local cellX, cellY = self:worldToCell(x, y)
        return self:getCellKey(cellX, cellY)
    end
    
    -- Insert an entity into the grid
    function grid:insertEntity(entity)
        -- Entity must have a position component
        if not entity:hasComponent("position") then
            return false
        end
        
        local position = entity:getComponent("position")
        local cellX, cellY = self:worldToCell(position.x, position.y)
        local cellKey = self:getCellKey(cellX, cellY)
        
        -- Create cell if it doesn't exist
        if not self.cells[cellKey] then
            self.cells[cellKey] = {}
        end
        
        -- Add entity to cell
        self.cells[cellKey][entity.id] = entity
        
        -- Map entity to its cell
        self.entityMap[entity.id] = {
            cellKey = cellKey,
            cellX = cellX,
            cellY = cellY
        }
        
        return true
    end
    
    -- Remove an entity from the grid
    function grid:removeEntity(entity)
        local entityData = self.entityMap[entity.id]
        if not entityData then
            return false
        end
        
        -- Remove from cell
        if self.cells[entityData.cellKey] then
            self.cells[entityData.cellKey][entity.id] = nil
            
            -- Clean up empty cells
            if next(self.cells[entityData.cellKey]) == nil then
                self.cells[entityData.cellKey] = nil
            end
        end
        
        -- Remove from entity map
        self.entityMap[entity.id] = nil
        
        return true
    end
    
    -- Update an entity's position in the grid
    function grid:updateEntity(entity)
        -- Remove from current cell
        self:removeEntity(entity)
        
        -- Insert into new cell
        return self:insertEntity(entity)
    end
    
    -- Get all entities in a specific cell
    function grid:getEntitiesInCell(cellX, cellY)
        local cellKey = self:getCellKey(cellX, cellY)
        local result = {}
        
        if self.cells[cellKey] then
            for _, entity in pairs(self.cells[cellKey]) do
                table.insert(result, entity)
            end
        end
        
        return result
    end
    
    -- Get all entities in a radius around a point
    function grid:getEntitiesInRadius(x, y, radius)
        local result = {}
        local radiusSq = radius * radius
        
        -- Calculate cell range to check
        local cellRadius = math.ceil(radius / self.cellSize)
        local centerCellX, centerCellY = self:worldToCell(x, y)
        
        -- Check all cells in the radius
        for cellY = centerCellY - cellRadius, centerCellY + cellRadius do
            for cellX = centerCellX - cellRadius, centerCellX + cellRadius do
                -- Skip cells outside the grid
                if cellX >= 1 and cellX <= self.width and cellY >= 1 and cellY <= self.height then
                    local cellKey = self:getCellKey(cellX, cellY)
                    
                    if self.cells[cellKey] then
                        for _, entity in pairs(self.cells[cellKey]) do
                            -- Check actual distance
                            local position = entity:getComponent("position")
                            local dx = position.x - x
                            local dy = position.y - y
                            local distSq = dx * dx + dy * dy
                            
                            if distSq <= radiusSq then
                                table.insert(result, entity)
                            end
                        end
                    end
                end
            end
        end
        
        return result
    end
    
    -- Get all entities in a rectangle
    function grid:getEntitiesInRect(x, y, width, height)
        local result = {}
        
        -- Calculate cell range to check
        local minCellX, minCellY = self:worldToCell(x, y)
        local maxCellX, maxCellY = self:worldToCell(x + width, y + height)
        
        -- Check all cells in the rectangle
        for cellY = minCellY, maxCellY do
            for cellX = minCellX, maxCellX do
                -- Skip cells outside the grid
                if cellX >= 1 and cellX <= self.width and cellY >= 1 and cellY <= self.height then
                    local cellKey = self:getCellKey(cellX, cellY)
                    
                    if self.cells[cellKey] then
                        for _, entity in pairs(self.cells[cellKey]) do
                            -- Check if entity is actually in the rectangle
                            local position = entity:getComponent("position")
                            if position.x >= x and position.x <= x + width and
                               position.y >= y and position.y <= y + height then
                                table.insert(result, entity)
                            end
                        end
                    end
                end
            end
        end
        
        return result
    end
    
    -- Get potential collision pairs
    function grid:getPotentialCollisionPairs()
        local collisionPairs = {}
        
        -- Check each cell
        for _, cell in pairs(self.cells) do
            local entities = {}
            
            -- Collect entities in this cell
            for _, entity in pairs(cell) do
                table.insert(entities, entity)
            end
            
            -- Generate pairs within this cell
            for i = 1, #entities do
                for j = i + 1, #entities do
                    table.insert(collisionPairs, {entities[i], entities[j]})
                end
            end
        end
        
        return collisionPairs
    end
    
    -- Clear all entities from the grid
    function grid:clear()
        self.cells = {}
        self.entityMap = {}
    end
    
    -- Debug draw the grid
    function grid:debugDraw()
        if not love then return end
        
        -- Save current color
        local r, g, b, a = love.graphics.getColor()
        
        -- Draw grid cells
        love.graphics.setColor(0.2, 0.2, 0.8, 0.3)
        
        for cellKey, cell in pairs(self.cells) do
            -- Parse cell coordinates from key
            local cellX, cellY = cellKey:match("(%d+),(%d+)")
            cellX, cellY = tonumber(cellX), tonumber(cellY)
            
            -- Calculate world coordinates
            local worldX = self.worldBounds.minX + (cellX - 1) * self.cellSize
            local worldY = self.worldBounds.minY + (cellY - 1) * self.cellSize
            
            -- Draw cell
            love.graphics.rectangle("fill", worldX, worldY, self.cellSize, self.cellSize)
            
            -- Draw entity count
            love.graphics.setColor(1, 1, 1, 1)
            local count = 0
            for _ in pairs(cell) do count = count + 1 end
            love.graphics.print(count, worldX + self.cellSize / 2, worldY + self.cellSize / 2)
        end
        
        -- Restore color
        love.graphics.setColor(r, g, b, a)
    end
    
    return grid
end

return SpatialPartition 