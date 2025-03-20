-- lib/objectPool.lua
-- Generic object pooling system to reduce garbage collection

local ObjectPool = {}
ObjectPool.__index = ObjectPool

--[[
    Creates a new object pool
    
    @param objectType - Table with a :new() function to create objects
    @param initialSize - Number of objects to pre-allocate (default: 10)
    @param resetFunc - Optional custom reset function name (default: "reset")
    @param initFunc - Optional custom initialization function name (default: "initialize")
    @return The object pool instance
]]
function ObjectPool:new(objectType, initialSize, resetFunc, initFunc)
    local pool = {
        objectType = objectType,
        available = {},
        active = {},
        size = 0,
        maxSize = 0,
        resetFunc = resetFunc or "reset",
        initFunc = initFunc or "initialize",
        debugMode = false
    }
    
    setmetatable(pool, ObjectPool)
    
    -- Pre-populate pool
    pool:grow(initialSize or 10)
    
    return pool
end

--[[
    Add more objects to the pool
    
    @param count - Number of objects to add
]]
function ObjectPool:grow(count)
    for i = 1, count do
        local obj = self.objectType:new()
        obj.active = false
        obj.poolId = self.size + 1
        self.size = self.size + 1
        table.insert(self.available, obj)
    end
    
    -- Update stats
    self.maxSize = math.max(self.maxSize, self.size)
    
    if self.debugMode then
        print(string.format("Pool '%s' grew by %d objects (total: %d)",
            self:getTypeName(), count, self.size))
    end
end

--[[
    Get an object from the pool, creating new ones if needed
    
    @param ... - Parameters to pass to the initialization function
    @return The activated object
]]
function ObjectPool:get(...)
    local obj
    
    -- Get available object or create new one
    if #self.available > 0 then
        obj = table.remove(self.available)
    else
        -- Auto-grow the pool
        self:grow(math.max(5, math.floor(self.size * 0.2))) -- Grow by 20% with minimum of 5
        obj = table.remove(self.available)
    end
    
    -- Mark as active
    obj.active = true
    table.insert(self.active, obj)
    
    -- Initialize with passed parameters
    if obj[self.initFunc] then
        obj[self.initFunc](obj, ...)
    end
    
    if self.debugMode then
        print(string.format("Pool '%s' activated object %d (active: %d, available: %d)",
            self:getTypeName(), obj.poolId, #self.active, #self.available))
    end
    
    return obj
end

--[[
    Release an object back to the pool
    
    @param obj - The object to release
    @return true if released, false if not found
]]
function ObjectPool:release(obj)
    -- Find in active list
    for i, activeObj in ipairs(self.active) do
        if activeObj == obj then
            -- Remove from active list
            table.remove(self.active, i)
            
            -- Reset object state
            obj.active = false
            if obj[self.resetFunc] then
                obj[self.resetFunc](obj)
            end
            
            -- Return to available pool
            table.insert(self.available, obj)
            
            if self.debugMode then
                print(string.format("Pool '%s' released object %d (active: %d, available: %d)",
                    self:getTypeName(), obj.poolId, #self.active, #self.available))
            end
            
            return true
        end
    end
    
    return false
end

--[[
    Release all active objects back to the pool
]]
function ObjectPool:releaseAll()
    -- Release all active objects
    while #self.active > 0 do
        self:release(self.active[1])
    end
    
    if self.debugMode then
        print(string.format("Pool '%s' released all objects (active: %d, available: %d)",
            self:getTypeName(), #self.active, #self.available))
    end
end

--[[
    Update all active objects
    
    @param dt - Delta time
    @param autoRelease - If true, automatically release objects that set active=false during update
]]
function ObjectPool:update(dt, autoRelease)
    if autoRelease == nil then
        autoRelease = true -- Default to auto-release
    end
    
    -- Update in reverse order to handle removals
    for i = #self.active, 1, -1 do
        local obj = self.active[i]
        
        -- Check if object needs to be released
        if not obj.active and autoRelease then
            self:release(obj)
        elseif obj.update then
            -- Update the object
            obj:update(dt)
            
            -- Check again after update
            if not obj.active and autoRelease then
                self:release(obj)
            end
        end
    end
end

--[[
    Draw all active objects
    
    @param ... - Additional parameters to pass to the draw function
]]
function ObjectPool:draw(...)
    for _, obj in ipairs(self.active) do
        if obj.draw then
            obj:draw(...)
        end
    end
end

--[[
    Get count of active objects
    
    @return Number of active objects
]]
function ObjectPool:getActiveCount()
    return #self.active
end

--[[
    Get count of available objects
    
    @return Number of available objects
]]
function ObjectPool:getAvailableCount()
    return #self.available
end

--[[
    Get total pool size
    
    @return Total number of objects in the pool
]]
function ObjectPool:getTotalSize()
    return self.size
end

--[[
    Destroy the pool and all objects
]]
function ObjectPool:destroy()
    -- Clear references to help garbage collector
    self.active = {}
    self.available = {}
    self.size = 0
    
    if self.debugMode then
        print(string.format("Pool '%s' destroyed", self:getTypeName()))
    end
end

--[[
    Enable or disable debug output
    
    @param enabled - Whether debug output should be enabled
]]
function ObjectPool:setDebugMode(enabled)
    self.debugMode = enabled
end

--[[
    Get a string name of the object type for debugging
    
    @return Name of the object type
]]
function ObjectPool:getTypeName()
    if self.objectType.name then
        return self.objectType.name
    elseif self.objectType.__name then
        return self.objectType.__name
    else
        return tostring(self.objectType):gsub("table: ", "")
    end
end

--[[
    Get an iterator for active objects
    
    @return Iterator function
]]
function ObjectPool:each()
    local i = 0
    return function()
        i = i + 1
        return self.active[i]
    end
end

return ObjectPool