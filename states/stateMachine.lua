-- states/stateMachine.lua - State machine for managing player states

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine:new()
    local self = setmetatable({}, StateMachine)
    self.states = {}
    self.current = nil
    return self
end

function StateMachine:add(name, state)
    self.states[name] = state
end

function StateMachine:change(stateName, ...)
    assert(self.states[stateName], "State " .. stateName .. " does not exist!")
    
    local prevState = self.current
    
    -- Exit current state if it exists
    if self.current then
        self.current:exit()
    end
    
    -- Change to new state
    self.current = self.states[stateName]
    
    -- Enter new state - pass previous state as first parameter
    self.current:enter(prevState, ...)
    
    return self.current
end

function StateMachine:getCurrentState()
    return self.current
end

function StateMachine:getCurrentStateName()
    return self.current and self.current:getName() or "None"
end

return StateMachine