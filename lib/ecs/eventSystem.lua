-- lib/ecs/eventSystem.lua
-- Event system for the Entity Component System

local EventSystem = {}

-- Table to store event listeners
local listeners = {}

-- Queue of events to be processed
local eventQueue = {}

-- Register a listener for an event type
function EventSystem.on(eventType, callback)
    if not listeners[eventType] then
        listeners[eventType] = {}
    end
    
    table.insert(listeners[eventType], callback)
    
    -- Return a handle that can be used to remove this listener
    return {
        eventType = eventType,
        callback = callback
    }
end

-- Remove a listener using its handle
function EventSystem.off(handle)
    if not handle or not handle.eventType or not handle.callback then
        return false
    end
    
    local eventListeners = listeners[handle.eventType]
    if not eventListeners then
        return false
    end
    
    for i, callback in ipairs(eventListeners) do
        if callback == handle.callback then
            table.remove(eventListeners, i)
            return true
        end
    end
    
    return false
end

-- Emit an event (add it to the queue)
function EventSystem.emit(eventType, data)
    table.insert(eventQueue, {
        type = eventType,
        data = data,
        time = love.timer.getTime()
    })
end

-- Process all events in the queue
function EventSystem.processEvents()
    local currentQueue = eventQueue
    eventQueue = {} -- Reset the queue
    
    for _, event in ipairs(currentQueue) do
        local eventListeners = listeners[event.type]
        if eventListeners then
            for _, callback in ipairs(eventListeners) do
                callback(event.data, event.time)
            end
        end
    end
end

-- Clear all listeners for a specific event type
function EventSystem.clearListeners(eventType)
    if eventType then
        listeners[eventType] = nil
    else
        listeners = {}
    end
end

-- Get the number of pending events
function EventSystem.getPendingEventCount()
    return #eventQueue
end

-- Get the number of listeners for a specific event type
function EventSystem.getListenerCount(eventType)
    if not eventType then
        local count = 0
        for _, listenerList in pairs(listeners) do
            count = count + #listenerList
        end
        return count
    end
    
    return listeners[eventType] and #listeners[eventType] or 0
end

-- Create a new event bus (for isolated event systems)
function EventSystem.createEventBus()
    local bus = {}
    local busListeners = {}
    local busEventQueue = {}
    
    -- Register a listener for an event type
    function bus.on(eventType, callback)
        if not busListeners[eventType] then
            busListeners[eventType] = {}
        end
        
        table.insert(busListeners[eventType], callback)
        
        -- Return a handle that can be used to remove this listener
        return {
            eventType = eventType,
            callback = callback
        }
    end
    
    -- Remove a listener using its handle
    function bus.off(handle)
        if not handle or not handle.eventType or not handle.callback then
            return false
        end
        
        local eventListeners = busListeners[handle.eventType]
        if not eventListeners then
            return false
        end
        
        for i, callback in ipairs(eventListeners) do
            if callback == handle.callback then
                table.remove(eventListeners, i)
                return true
            end
        end
        
        return false
    end
    
    -- Emit an event (add it to the queue)
    function bus.emit(eventType, data)
        table.insert(busEventQueue, {
            type = eventType,
            data = data,
            time = love.timer.getTime()
        })
    end
    
    -- Process all events in the queue
    function bus.processEvents()
        local currentQueue = busEventQueue
        busEventQueue = {} -- Reset the queue
        
        for _, event in ipairs(currentQueue) do
            local eventListeners = busListeners[event.type]
            if eventListeners then
                for _, callback in ipairs(eventListeners) do
                    callback(event.data, event.time)
                end
            end
        end
    end
    
    -- Clear all listeners for a specific event type
    function bus.clearListeners(eventType)
        if eventType then
            busListeners[eventType] = nil
        else
            busListeners = {}
        end
    end
    
    -- Get the number of pending events
    function bus.getPendingEventCount()
        return #busEventQueue
    end
    
    -- Get the number of listeners for a specific event type
    function bus.getListenerCount(eventType)
        if not eventType then
            local count = 0
            for _, listenerList in pairs(busListeners) do
                count = count + #listenerList
            end
            return count
        end
        
        return busListeners[eventType] and #busListeners[eventType] or 0
    end
    
    return bus
end

return EventSystem 