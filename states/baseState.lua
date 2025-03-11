-- states/baseState.lua - Base state class for the FSM

local BaseState = {}
BaseState.__index = BaseState

function BaseState:new(player)
    local self = setmetatable({}, self)
    self.player = player
    self.events = require("lib/events") -- Add events reference
    return self
end

-- Default implementations that can be overridden by specific states
function BaseState:enter(prevState, data) end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:draw() end
function BaseState:keypressed(key, particleManager) end
function BaseState:mousepressed(x, y, button) end
function BaseState:mousemoved(x, y) end
function BaseState:mousereleased(x, y, button, particleManager) end
function BaseState:touchpressed(id, x, y) end
function BaseState:touchmoved(id, x, y) end
function BaseState:touchreleased(id, x, y, particleManager) end
function BaseState:checkHorizontalBounds(screenWidth) end
function BaseState:handleCollision(other) end
function BaseState:getName() return "BaseState" end
function BaseState:onDragEnd() end

return BaseState