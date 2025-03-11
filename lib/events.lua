-- events.lua - Simple Event System for Love2D Vertical Jumper

local Events = {}

-- Table to store event listeners
local listeners = {}

-- Register a listener for an event
function Events.on(eventName, callback)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    table.insert(listeners[eventName], callback)
end

-- Fire an event with optional data
function Events.fire(eventName, data)
    if listeners[eventName] then
        for _, callback in ipairs(listeners[eventName]) do
            callback(data)
        end
    end
end

-- Remove a specific listener
function Events.off(eventName, callback)
    if listeners[eventName] then
        for i, registeredCallback in ipairs(listeners[eventName]) do
            if registeredCallback == callback then
                table.remove(listeners[eventName], i)
                break
            end
        end
    end
end

-- Clear all listeners for an event
function Events.clear(eventName)
    listeners[eventName] = nil
end

-- Clear all events
function Events.clearAll()
    listeners = {}
end

return Events