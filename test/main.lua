-- main.lua - Dash Test Environment
-- A simplified environment to test dash mechanics

-- Forward declarations
local Player, BaseState, GroundedState, FallingState, DashingState
local Physics, InputManager
local Events

-- Constants
local SCREEN_WIDTH = 800
local SCREEN_HEIGHT = 600
local GRAVITY = 1200
local SHOW_DEBUG = true  -- Set to true to see debug info

----- ⭐ Simple Event System -----
Events = {}
local listeners = {}

function Events.on(eventName, callback)
    listeners[eventName] = listeners[eventName] or {}
    table.insert(listeners[eventName], callback)
end

function Events.fire(eventName, data)
    if listeners[eventName] then
        for _, callback in ipairs(listeners[eventName]) do
            callback(data)
        end
    end
end

function Events.clear(eventName)
    listeners[eventName] = nil
end

function Events.clearAll()
    listeners = {}
end

----- ⭐ Core Physics Utils -----
Physics = {}

-- Calculate dash trajectory
function Physics.calculateDashTrajectory(startX, startY, direction, speed, power, dashDuration, gravity, pointCount)
    local trajectory = {}
    
    -- First half: Dash trajectory
    local dashPoints = math.floor(pointCount / 2)
    local velocity = speed * power
    
    for i = 0, dashPoints do
        local timeRatio = i / dashPoints
        local timeElapsed = timeRatio * dashDuration
        local distanceMoved = velocity * timeElapsed
        
        local x = startX + direction.x * distanceMoved
        local y = startY + direction.y * distanceMoved
        
        table.insert(trajectory, {x = x, y = y})
    end
    
    -- Calculate dash end position
    local dashEndX = startX + direction.x * velocity * dashDuration
    local dashEndY = startY + direction.y * velocity * dashDuration
    
    -- Second half: Falling trajectory
    local fallPoints = pointCount - dashPoints
    local maxFallTime = 0.5
    
    for i = 1, fallPoints do
        local timeRatio = i / fallPoints
        local fallTime = timeRatio * maxFallTime
        
        local x = dashEndX + (direction.x * velocity * 0.05) * fallTime
        local y = dashEndY + 0.5 * gravity * fallTime * fallTime
        
        table.insert(trajectory, {x = x, y = y})
    end
    
    return trajectory
end

-- Apply dash movement in a frame
function Physics.applyDashMovement(player, direction, speed, power, dt)
    -- Calculate velocity
    local velocity = speed * power
    
    -- Calculate movement delta
    local deltaX = direction.x * velocity * dt
    local deltaY = direction.y * velocity * dt
    
    -- Calculate player center coordinates
    local centerX = player.x + player.width/2
    local centerY = player.y + player.height/2
    
    -- Update player center position
    centerX = centerX + deltaX
    centerY = centerY + deltaY
    
    -- Return center coordinates
    return centerX, centerY
end

-- Calculate dash parameters from drag
function Physics.calculateDashParams(dragVector, minDragDistance, maxDragDistance, minDashDuration, maxDashDuration)
    -- Calculate drag distance
    local dragDistance = math.sqrt(dragVector.x^2 + dragVector.y^2)
    
    -- Check if drag is significant
    if dragDistance < minDragDistance then
        return nil
    end
    
    -- Calculate normalized direction (opposite of drag)
    -- NOTE: We're only negating the X direction, but not the Y direction
    -- This is because in Love2D, Y increases downward, so dragging down should dash up
    local direction = {
        x = -dragVector.x / dragDistance,
        y = -dragVector.y / dragDistance  -- This negation might be causing the issue
    }
    
    -- Calculate power based on drag distance
    local power = math.min(dragDistance, maxDragDistance) / maxDragDistance
    
    -- Calculate dash duration based on power
    local duration = minDashDuration + power * (maxDashDuration - minDashDuration)
    
    return {
        direction = direction,
        power = power,
        duration = duration,
        isSignificant = true
    }
end

----- ⭐ Input Manager -----
InputManager = {}
InputManager.__index = InputManager

function InputManager:new()
    local self = setmetatable({}, InputManager)
    
    -- Drag state
    self.isDragging = false
    self.dragStartX = nil
    self.dragStartY = nil
    self.currentDragX = nil
    self.currentDragY = nil
    self.dragVector = {x = 0, y = 0}
    
    -- Target information
    self.targetPlayer = nil
    self.playerX = nil
    self.playerY = nil
    self.playerWidth = nil
    self.playerHeight = nil
    self.playerDashSpeed = nil
    self.playerGravity = nil
    
    -- Trajectory preview
    self.trajectoryPoints = {}
    
    -- Settings
    self.minDragDistance = 20
    self.maxDragDistance = 150
    
    return self
end

function InputManager:update(dt)
    if not self.isDragging then
        return
    end
    
    if self.currentDragX and self.currentDragY and self.dragStartX and self.dragStartY then
        self.dragVector.x = self.currentDragX - self.dragStartX
        self.dragVector.y = self.currentDragY - self.dragStartY
        
        if self.targetPlayer then
            self.playerX = self.targetPlayer.x
            self.playerY = self.targetPlayer.y
            self:calculateTrajectory()
        end
    end
end

function InputManager:startDrag(x, y)
    if self.isDragging then
        return false
    end
    
    self.isDragging = true
    self.dragStartX = x
    self.dragStartY = y
    self.currentDragX = x
    self.currentDragY = y
    self.dragVector = {x = 0, y = 0}
    self.trajectoryPoints = {}
    
    Events.fire("dragStart", {
        x = x,
        y = y
    })
    
    return true
end

function InputManager:setTargetPlayer(player)
    if player then
        self.targetPlayer = player
        self.playerX = player.x
        self.playerY = player.y
        self.playerWidth = player.width
        self.playerHeight = player.height
        self.playerDashSpeed = player.dashSpeed
        self.playerGravity = GRAVITY
    else
        self.targetPlayer = nil
    end
end

function InputManager:updateDrag(x, y)
    if not self.isDragging then
        return false
    end
    
    self.currentDragX = x
    self.currentDragY = y
    self.dragVector.x = x - self.dragStartX
    self.dragVector.y = y - self.dragStartY
    
    Events.fire("dragUpdate", {
        x = x,
        y = y,
        dragVector = self.dragVector
    })
    
    return true
end

function InputManager:endDrag(x, y)
    if not self.isDragging then
        return false
    end
    
    self.currentDragX = x
    self.currentDragY = y
    self.dragVector.x = x - self.dragStartX
    self.dragVector.y = y - self.dragStartY
    
    local dashParams = Physics.calculateDashParams(
        self.dragVector,
        self.minDragDistance,
        self.maxDragDistance,
        self.targetPlayer and self.targetPlayer.minDashDuration or 0.001,
        self.targetPlayer and self.targetPlayer.maxDashDuration or 0.2
    )
    
    Events.fire("dragEnd", dashParams or {
        isSignificant = false
    })
    
    self.isDragging = false
    
    return dashParams and dashParams.isSignificant or false
end

function InputManager:calculateTrajectory()
    local dashParams = Physics.calculateDashParams(
        self.dragVector,
        self.minDragDistance,
        self.maxDragDistance,
        self.targetPlayer.minDashDuration,
        self.targetPlayer.maxDashDuration
    )
    
    if not dashParams then
        self.trajectoryPoints = {}
        return
    end
    
    local centerX = self.playerX + self.playerWidth/2
    local centerY = self.playerY + self.playerHeight/2
    
    self.trajectoryPoints = Physics.calculateDashTrajectory(
        centerX,
        centerY,
        dashParams.direction,
        self.playerDashSpeed,
        dashParams.power,
        dashParams.duration,
        GRAVITY,
        20
    )
end

function InputManager:draw()
    if not self.isDragging then
        return
    end
    
    -- Draw drag line
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.line(
        self.dragStartX, 
        self.dragStartY, 
        self.currentDragX, 
        self.currentDragY
    )
    
    -- Draw start point
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", self.dragStartX, self.dragStartY, 8)
    
    -- Draw trajectory
    if #self.trajectoryPoints > 1 then
        love.graphics.setColor(1, 1, 1, 0.4)
        
        -- Draw dots
        for i, point in ipairs(self.trajectoryPoints) do
            local size = 5 * (1 - (i / #self.trajectoryPoints))
            love.graphics.circle("fill", point.x, point.y, size)
        end
        
        -- Draw lines
        for i = 1, #self.trajectoryPoints - 1 do
            love.graphics.setColor(1, 1, 1, 0.3 * (1 - (i / #self.trajectoryPoints)))
            love.graphics.line(
                self.trajectoryPoints[i].x, 
                self.trajectoryPoints[i].y,
                self.trajectoryPoints[i+1].x,
                self.trajectoryPoints[i+1].y
            )
        end
    end
    
    -- Draw direction arrow if drag is significant
    local dragDistance = math.sqrt(self.dragVector.x^2 + self.dragVector.y^2)
    if dragDistance > self.minDragDistance then
        local direction = {
            x = -self.dragVector.x / dragDistance,
            y = -self.dragVector.y / dragDistance
        }
        
        local power = math.min(dragDistance, self.maxDragDistance) / self.maxDragDistance
        
        love.graphics.setColor(1, power, 0, 0.7)
        
        -- Draw arrow
        local arrowX = self.currentDragX
        local arrowY = self.currentDragY
        local arrowLength = 20 * power
        
        love.graphics.line(
            arrowX, 
            arrowY, 
            arrowX + direction.x * arrowLength, 
            arrowY + direction.y * arrowLength
        )
        
        -- Draw arrowhead
        local headSize = 8 * power
        local perpX = -direction.y
        local perpY = direction.x
        
        love.graphics.polygon(
            "fill", 
            arrowX + direction.x * arrowLength, 
            arrowY + direction.y * arrowLength,
            arrowX + direction.x * (arrowLength - headSize) + perpX * headSize/2,
            arrowY + direction.y * (arrowLength - headSize) + perpY * headSize/2,
            arrowX + direction.x * (arrowLength - headSize) - perpX * headSize/2,
            arrowY + direction.y * (arrowLength - headSize) - perpY * headSize/2
        )
    end
end

----- ⭐ State Machine -----
BaseState = {}
BaseState.__index = BaseState

function BaseState:new(player)
    local self = setmetatable({}, self)
    self.player = player
    return self
end

function BaseState:enter(prevState) end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:draw() end
function BaseState:getName() return "BaseState" end
function BaseState:onDragEnd(data) end
function BaseState:onCollision(other) end
function BaseState:enemyCollision(enemy) end

GroundedState = setmetatable({}, BaseState)
GroundedState.__index = GroundedState

function GroundedState:new(player)
    local self = BaseState.new(self, player)
    return self
end

function GroundedState:enter(prevState)
    self.player.onGround = true
    self.player.velocity.x = 0
    self.player.velocity.y = 0
    self.player:refreshJumps()
end

function GroundedState:update(dt)
    -- Handle keyboard movement
    self.player.velocity.x = 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.player.velocity.x = -300
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.player.velocity.x = 300
    end
    
    -- Apply velocity
    self.player.x = self.player.x + self.player.velocity.x * dt
    
    -- Check if player fell off the platform
    self.player.onGround = self.player.y + self.player.height >= SCREEN_HEIGHT - 50
    
    if not self.player.onGround then
        self.player.stateMachine:change("Falling")
    end
end

function GroundedState:keypressed(key)
    if key == "space" or key == "up" or key == "w" then
        -- Jump up on key press
        self.player.stateMachine:change("Dashing", {
            direction = {x = 0, y = -1},
            power = 0.8,
            duration = 0.2
        })
    end
end

function GroundedState:onDragEnd(data)
    if data.isSignificant then
        self.player.stateMachine:change("Dashing", data)
    end
end

function GroundedState:draw()
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function GroundedState:getName()
    return "Grounded"
end

FallingState = setmetatable({}, BaseState)
FallingState.__index = FallingState

function FallingState:new(player)
    local self = BaseState.new(self, player)
    return self
end

function FallingState:enter(prevState)
    self.player.onGround = false
end

function FallingState:update(dt)
    -- Handle horizontal movement
    self.player.velocity.x = 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        self.player.velocity.x = -300
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        self.player.velocity.x = 300
    end
    
    -- Apply gravity
    self.player.velocity.y = self.player.velocity.y + GRAVITY * dt
    
    -- Cap falling speed
    self.player.velocity.y = math.min(self.player.velocity.y, 800)
    
    -- Apply velocity
    self.player.x = self.player.x + self.player.velocity.x * dt
    self.player.y = self.player.y + self.player.velocity.y * dt
    
    -- Check for landing
    if self.player.y + self.player.height >= SCREEN_HEIGHT - 50 then
        self.player.y = SCREEN_HEIGHT - 50 - self.player.height
        self.player.stateMachine:change("Grounded")
    end
    
    -- Wrap around screen edges (for testing convenience)
    if self.player.x < 0 then
        self.player.x = SCREEN_WIDTH - self.player.width
    elseif self.player.x + self.player.width > SCREEN_WIDTH then
        self.player.x = 0
    end
end

function FallingState:keypressed(key)
    if (key == "space" or key == "up" or key == "w") and self.player:canJump() then
        self.player:deductJump()
        self.player.stateMachine:change("Dashing", {
            direction = {x = 0, y = -1},
            power = 0.8,
            duration = 0.2
        })
    end
end

function FallingState:onDragEnd(data)
    if data.isSignificant and self.player:canJump() then
        self.player:deductJump()
        self.player.stateMachine:change("Dashing", data)
    end
end

function FallingState:draw()
    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
end

function FallingState:getName()
    return "Falling"
end

DashingState = setmetatable({}, BaseState)
DashingState.__index = DashingState

function DashingState:new(player)
    local self = BaseState.new(self, player)
    self.afterImageTimer = nil
    self.dashTimeLeft = nil
    self.dashDirection = nil
    self.dashPower = nil
    self.originalDirection = nil
    return self
end

function DashingState:enter(prevState, data)
    self.player.onGround = false
    self.player.velocity.x = 0
    self.player.velocity.y = 0
    
    -- Initialize afterImage timer
    self.afterImageTimer = 0.02
    self.player.afterImagePositions = {}
    
    -- Set dash parameters - make a copy to avoid reference issues
    self.dashDirection = {
        x = data.direction.x,
        y = data.direction.y
    }
    
    -- Store original direction for debugging
    self.originalDirection = {
        x = data.direction.x,
        y = data.direction.y
    }
    
    self.dashPower = data.power
    self.dashTimeLeft = self.player.minDashDuration + 
                        data.power * (self.player.maxDashDuration - self.player.minDashDuration)
    
    -- Debug output
    if SHOW_DEBUG then
        print("=== DASH START ===")
        print("Direction:", self.dashDirection.x, self.dashDirection.y)
        print("Power:", self.dashPower)
        print("Duration:", self.dashTimeLeft)
        print("Position:", self.player.x, self.player.y)
    end
    
    Events.fire("playerDashStarted", {
        power = self.dashPower,
        direction = self.dashDirection
    })
end

function DashingState:update(dt)
    -- Store initial direction values for this frame
    local startDirX = self.dashDirection.x
    local startDirY = self.dashDirection.y
    
    -- Update afterImage timer
    if not self.afterImageTimer or self.afterImageTimer <= 0 then
        if #self.player.afterImagePositions >= 5 then
            table.remove(self.player.afterImagePositions, 1)
        end
        
        table.insert(self.player.afterImagePositions, {
            x = self.player.x,
            y = self.player.y
        })
        
        self.afterImageTimer = 0.02
    else
        self.afterImageTimer = self.afterImageTimer - dt
    end
    
    -- Apply dash movement
    local centerX, centerY = Physics.applyDashMovement(
        self.player,
        self.dashDirection,
        self.player.dashSpeed,
        self.dashPower,
        dt
    )
    
    -- Update player position
    self.player.x = centerX - self.player.width/2
    self.player.y = centerY - self.player.height/2
    
    -- Update dash timer
    self.dashTimeLeft = self.dashTimeLeft - dt
    
    -- Check for direction changes
    if self.dashDirection.x ~= startDirX or self.dashDirection.y ~= startDirY then
        if SHOW_DEBUG then
            print("!!! DIRECTION CHANGED DURING UPDATE !!!")
            print("Start:", startDirX, startDirY)
            print("End:", self.dashDirection.x, self.dashDirection.y)
        end
        
        -- Restore original direction
        self.dashDirection.x = startDirX
        self.dashDirection.y = startDirY
    end
    
    -- Check if original direction was modified
    if self.dashDirection.x ~= self.originalDirection.x or 
       self.dashDirection.y ~= self.originalDirection.y then
        if SHOW_DEBUG then
            print("!!! ORIGINAL DIRECTION CORRUPTED !!!")
            print("Original:", self.originalDirection.x, self.originalDirection.y)
            print("Current:", self.dashDirection.x, self.dashDirection.y)
        end
    end
    
    -- End dash when timer runs out
    if self.dashTimeLeft <= 0 then
        if SHOW_DEBUG then
            print("=== DASH END ===")
            print("Final position:", self.player.x, self.player.y)
            print("Direction used:", self.dashDirection.x, self.dashDirection.y)
        end
        
        -- Set velocities for transition
        self.player.velocity.x = self.dashDirection.x * self.player.dashSpeed * 0.2 * self.dashPower
        self.player.velocity.y = 0
        
        -- Change to falling state
        self.player.stateMachine:change("Falling")
    end
    
    -- Wrap around screen edges (for testing convenience)
    if self.player.x < 0 then
        self.player.x = SCREEN_WIDTH - self.player.width
    elseif self.player.x + self.player.width > SCREEN_WIDTH then
        self.player.x = 0
    end
    
    -- Bounce off ceiling for testing
    if self.player.y < 0 then
        self.player.y = 0
        if self.dashDirection.y < 0 then
            self.dashDirection.y = -self.dashDirection.y
        end
    end
end

function DashingState:onDragEnd(data)
    if data.isSignificant and self.player:canJump() then
        if SHOW_DEBUG then
            print("Initiating new dash while already dashing")
        end
        
        self.player:deductJump()
        self.player.stateMachine:change("Dashing", data)
    end
end

function DashingState:draw()
    -- Draw afterImages
    if self.player.afterImagePositions then
        for i, pos in ipairs(self.player.afterImagePositions) do
            love.graphics.setColor(1, 0.3, 0.3, i / #self.player.afterImagePositions * 0.7)
            love.graphics.rectangle("fill", pos.x, pos.y, self.player.width, self.player.height)
        end
    end
    
    -- Draw player
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
    
    -- Draw dash direction line
    love.graphics.setColor(1, 1, 0)
    love.graphics.line(
        self.player.x + self.player.width/2,
        self.player.y + self.player.height/2,
        self.player.x + self.player.width/2 + self.dashDirection.x * 50,
        self.player.y + self.player.height/2 + self.dashDirection.y * 50
    )
    
    -- Draw original direction line for comparison
    if self.originalDirection then
        love.graphics.setColor(0, 1, 1)
        love.graphics.line(
            self.player.x + self.player.width/2,
            self.player.y + self.player.height/2,
            self.player.x + self.player.width/2 + self.originalDirection.x * 40,
            self.player.y + self.player.height/2 + self.originalDirection.y * 40
        )
    end
end

function DashingState:getName()
    return "Dashing"
end

----- ⭐ State Machine -----
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
    
    if self.current then
        self.current:exit()
    end
    
    self.current = self.states[stateName]
    self.current:enter(prevState, ...)
    
    return self.current
end

function StateMachine:getCurrentState()
    return self.current
end

function StateMachine:getCurrentStateName()
    return self.current and self.current:getName() or "None"
end

----- ⭐ Player -----
Player = {}
Player.__index = Player

function Player:new(x, y)
    local self = setmetatable({}, Player)
    
    -- Position and dimensions
    self.x = x or SCREEN_WIDTH / 2 - 15
    self.y = y or SCREEN_HEIGHT - 100
    self.width = 30
    self.height = 50
    
    -- Velocity
    self.velocity = {x = 0, y = 0}
    
    -- Dash properties
    self.dashSpeed = 1500
    self.minDashDuration = 0.001
    self.maxDashDuration = 0.2
    
    -- Jump properties
    self.onGround = false
    self.maxMidairJumps = 20  -- More jumps for testing
    self.midairJumps = self.maxMidairJumps
    
    -- Visual effects
    self.afterImagePositions = {}
    
    -- State machine
    self.stateMachine = StateMachine:new()
    self.stateMachine:add("Grounded", GroundedState:new(self))
    self.stateMachine:add("Falling", FallingState:new(self))
    self.stateMachine:add("Dashing", DashingState:new(self))
    
    -- Initialize in falling state
    self.stateMachine:change("Falling")
    
    return self
end

function Player:update(dt)
    self.stateMachine:getCurrentState():update(dt)
end

function Player:draw()
    self.stateMachine:getCurrentState():draw()
    
    -- Draw debug info
    if SHOW_DEBUG then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("State: " .. self.stateMachine:getCurrentStateName(), 10, 10)
        love.graphics.print("Position: " .. math.floor(self.x) .. ", " .. math.floor(self.y), 10, 30)
        love.graphics.print("Velocity: " .. math.floor(self.velocity.x) .. ", " .. math.floor(self.velocity.y), 10, 50)
        love.graphics.print("Jumps: " .. self.midairJumps .. "/" .. self.maxMidairJumps, 10, 70)
        love.graphics.print("Controls: WASD/Arrows to move, Space to jump", 10, SCREEN_HEIGHT - 50)
        love.graphics.print("Click and drag to aim dash", 10, SCREEN_HEIGHT - 30)
    end
end

function Player:keypressed(key)
    self.stateMachine:getCurrentState():keypressed(key)
    
    -- Reset position with R
    if key == "r" then
        self.x = SCREEN_WIDTH / 2 - 15
        self.y = SCREEN_HEIGHT - 100
        self.velocity.x = 0
        self.velocity.y = 0
        self.midairJumps = self.maxMidairJumps
        self.stateMachine:change("Falling")
    end
    
    -- Toggle midair jumps with J
    if key == "j" then
        self.maxMidairJumps = self.maxMidairJumps == 2 and 10 or 2
        self.midairJumps = self.maxMidairJumps
        print("Midair jumps set to: " .. self.maxMidairJumps)
    end
end

function Player:canJump()
    return self.midairJumps > 0
end

function Player:deductJump()
    self.midairJumps = self.midairJumps - 1
    return self.midairJumps
end

function Player:refreshJumps()
    self.midairJumps = self.maxMidairJumps
end

----- ⭐ Main Love2D Callbacks -----
function love.load()
    love.window.setTitle("Dash Test Environment")
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
    
    -- Initialize player and input manager
    player = Player:new()
    inputManager = InputManager:new()
    
    -- Set font
    love.graphics.setNewFont(14)
    
    -- Set up event listeners
    Events.on("dragEnd", function(data)
        if data.isSignificant then
            player.stateMachine:getCurrentState():onDragEnd(data)
        end
    end)
    
    -- Print instructions
    print("=== Dash Test Environment ===")
    print("Controls:")
    print("- WASD/Arrow Keys: Move horizontally")
    print("- Space: Jump upward")
    print("- Click and drag: Aim and dash")
    print("- R: Reset position")
    print("- J: Toggle between 2 and 10 midair jumps")
    print("- D: Toggle debug info")
end

-- Mouse event handlers
function love.mousepressed(x, y, button)
    if button == 1 then
        inputManager:startDrag(x, y)
        inputManager:setTargetPlayer(player)
    end
end

function love.mousemoved(x, y)
    inputManager:updateDrag(x, y)
end

function love.mousereleased(x, y, button)
    if button == 1 then
        inputManager:endDrag(x, y)
    end
end

-- Keyboard handlers
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "d" then
        SHOW_DEBUG = not SHOW_DEBUG
        print("Debug display:", SHOW_DEBUG)
    end
    
    player:keypressed(key)
end

function love.update(dt)
    -- Cap delta time
    local cappedDt = math.min(dt, 1/30)
    
    -- Update input manager
    inputManager:update(cappedDt)
    
    -- Update player
    player:update(cappedDt)
    
    -- Add helpful debug info when dash direction might be changing
    if player.stateMachine:getCurrentStateName() == "Dashing" then
        local state = player.stateMachine:getCurrentState()
        
        -- Check for small movements in Y direction
        if math.abs(state.dashDirection.y) < 0.1 and state.dashDirection.y ~= 0 then
            if SHOW_DEBUG then
                print("Small Y component detected:", state.dashDirection.y)
            end
        end
        
        -- Check for direction corruption
        if state.originalDirection and (
           math.abs(state.dashDirection.x - state.originalDirection.x) > 0.001 or
           math.abs(state.dashDirection.y - state.originalDirection.y) > 0.001) then
            if SHOW_DEBUG then
                print("Direction drift detected!")
                print("Original:", state.originalDirection.x, state.originalDirection.y)
                print("Current:", state.dashDirection.x, state.dashDirection.y)
                print("Difference:", 
                    state.dashDirection.x - state.originalDirection.x,
                    state.dashDirection.y - state.originalDirection.y)
            end
        end
    end
end

function love.draw()
    -- Draw ground
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, SCREEN_HEIGHT - 50, SCREEN_WIDTH, 50)
    
    -- Draw player
    player:draw()
    
    -- Draw input manager (trajectory preview, etc.)
    inputManager:draw()
    
    -- Draw dash debug overlay if in dashing state
    if player.stateMachine:getCurrentStateName() == "Dashing" then
        local state = player.stateMachine:getCurrentState()
        
        -- Draw debug info
        love.graphics.setColor(1, 1, 1)
        
        local info = {
            "Dash Info:",
            string.format("Direction: %.2f, %.2f", state.dashDirection.x, state.dashDirection.y),
            string.format("Original: %.2f, %.2f", state.originalDirection.x, state.originalDirection.y),
            string.format("Power: %.2f", state.dashPower),
            string.format("Time Left: %.2f", state.dashTimeLeft)
        }
        
        for i, text in ipairs(info) do
            love.graphics.print(text, SCREEN_WIDTH - 250, 10 + (i-1) * 20)
        end
    end
end