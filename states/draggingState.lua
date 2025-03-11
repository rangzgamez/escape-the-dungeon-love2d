-- states/draggingState.lua - Dragging (aiming) state for the player

local BaseState = require("states/baseState")

local DraggingState = setmetatable({}, BaseState)
DraggingState.__index = DraggingState

function DraggingState:new(player)
    local self = BaseState.new(self, player)
    -- Record the onGround status at the start of drag
    self.wasOnGround = false
    return self
end

function DraggingState:enter(prevState)
    -- Call parent method to fire state change event
    BaseState.enter(self, prevState)
    
    -- Initialize drag vector when entering state
    self.player.dragVector = {x = 0, y = 0}
    self.player.trajectoryPoints = {}
    
    -- Store whether player was on ground when drag started
    self.wasOnGround = self.player.onGround
    
    -- Notify game that dragging has started (for time effects)
    self.events.fire("playerDragStart", {
        onGround = self.player.onGround
    })
end

function DraggingState:exit()
    -- Notify game that dragging has ended
    self.events.fire("playerDragEnd", {})
end

function DraggingState:update(dt)
    -- Update trajectory -
    self:calculateTrajectory()
end

function DraggingState:onDragUpdate(x, y)
    -- Update drag vector
    self.player.dragVector.x = x - self.player.dragStartX
    self.player.dragVector.y = y - self.player.dragStartY
    
    -- Update trajectory preview
    self:calculateTrajectory()
end

function DraggingState:onDragEnd()
    -- Calculate drag distance
    local dragDistance = math.sqrt(self.player.dragVector.x^2 + self.player.dragVector.y^2)
    
    -- Only dash if drag distance is greater than minimum threshold
    if dragDistance > self.player.minDragDistance then
        -- Calculate dash power based on drag distance
        local dashPower = math.min(dragDistance, self.player.maxDragDistance) / self.player.maxDragDistance
        
        -- Calculate normalized dash direction
        local dashDirX = -self.player.dragVector.x / dragDistance
        local dashDirY = -self.player.dragVector.y / dragDistance
        
        -- Set up dash parameters
        self.player.dashTimeLeft = self.player.minDashDuration + dashPower * (self.player.maxDashDuration - self.player.minDashDuration)
        self.player.dashDirection = {
            x = dashDirX,
            y = dashDirY
        }
        
        -- Consume a midair jump if not on ground
        if not self.player.onGround then
            self.player.midairJumps = self.player.midairJumps - 1
        end
        
        -- Not on ground during dash
        self.player.onGround = false
        
        -- Change to dashing state
        self.player.stateMachine:change("Dashing")
        
        -- Fire dash started event
        self.events.fire("playerDashStarted", {
            power = dashPower,
            direction = self.player.dashDirection,
            fromGround = self.wasOnGround
        })
    else
        -- If drag was too short, return to appropriate state
        if self.player.onGround then
            self.player.stateMachine:change("Idle")
        else
            self.player.stateMachine:change("Falling")
        end
    end
    
    -- Clear trajectory
    self.player.trajectoryPoints = {}
end

function DraggingState:onLeftGround()
    -- Just update the onGround flag, but stay in dragging state
    self.player.onGround = false
end

function DraggingState:onLandOnGround()
    -- Just update the onGround flag, but stay in dragging state
    self.player.onGround = true
end

function DraggingState:calculateTrajectory()
    -- Clear previous trajectory
    self.player.trajectoryPoints = {}

    -- Only calculate if we're dragging enough for a dash
    local dragDistance = math.sqrt(self.player.dragVector.x^2 + self.player.dragVector.y^2)
    if dragDistance < self.player.minDragDistance then
        return
    end

    -- Calculate dash power and duration
    local dashPower = math.min(dragDistance, self.player.maxDragDistance) / self.player.maxDragDistance
    local dashDuration = self.player.minDashDuration + dashPower * (self.player.maxDashDuration - self.player.minDashDuration)

    -- Calculate normalized dash direction
    local dashDirX = -self.player.dragVector.x / dragDistance
    local dashDirY = -self.player.dragVector.y / dragDistance

    -- Starting position (center of player)
    local startX = self.player.x + self.player.width/2
    local startY = self.player.y + self.player.height/2

    -- First half of points show the dash path
    local dashPoints = 10
    for i = 0, dashPoints do
        -- Use even spacing along the dash path
        local t = (i / dashPoints) * dashDuration
        local pointX = startX + dashDirX * self.player.dashSpeed * dashPower * t
        local pointY = startY + dashDirY * self.player.dashSpeed * dashPower * t
        
        table.insert(self.player.trajectoryPoints, {x = pointX, y = pointY})
    end

    -- Calculate dash end position
    local dashEndX = startX + dashDirX * self.player.dashSpeed * dashPower * dashDuration
    local dashEndY = startY + dashDirY * self.player.dashSpeed * dashPower * dashDuration

    -- Second half of points show the falling path
    local fallPoints = 10
    local maxFallTime = 0.5 -- How far ahead to predict the fall
    for i = 1, fallPoints do
        local t = (i / fallPoints) * maxFallTime
        
        -- Very small horizontal movement after dash
        local pointX = dashEndX + (dashDirX * self.player.dashSpeed * 0.05) * t
        
        -- Apply gravity formula for vertical movement
        local pointY = dashEndY + 0.5 * self.player.gravity * t * t
        
        table.insert(self.player.trajectoryPoints, {x = pointX, y = pointY})
    end
end

function DraggingState:checkHorizontalBounds(screenWidth)
    -- Left boundary
    if self.player.x < 0 then
        self.player.x = 0
    end
    
    -- Right boundary
    if self.player.x + self.player.width > screenWidth then
        self.player.x = screenWidth - self.player.width
    end
end

function DraggingState:handleCollision(enemy)
    local result = {
        enemyHit = false,
        playerHit = false
    }
    
    -- Default collision behavior if state didn't handle it
    if enemy.state ~= "stunned" then
        -- Enemy hits player - player takes damage
        self.player:takeDamage()
        
        -- Reset combo when hit
        self.player:resetCombo()
        
        result.playerHit = true
    end
    
    return result
end

function DraggingState:draw()
    -- Draw base player in the current state color (either green or orange)
    if self.player.onGround then
        love.graphics.setColor(0, 1, 0)
    else
        love.graphics.setColor(1, 0.5, 0)
    end
    love.graphics.rectangle("fill", self.player.x, self.player.y, self.player.width, self.player.height)
    
    -- Draw trajectory preview
    if #self.player.trajectoryPoints > 1 then
        love.graphics.setColor(1, 1, 1, 0.4)  -- Semi-transparent white
        
        -- Draw dots along trajectory
        for i, point in ipairs(self.player.trajectoryPoints) do
            local size = 5 * (1 - (i / #self.player.trajectoryPoints))  -- Start bigger, end smaller
            love.graphics.circle("fill", point.x, point.y, size)
        end
        
        -- Draw connecting lines for trajectory
        for i = 1, #self.player.trajectoryPoints - 1 do
            love.graphics.setColor(1, 1, 1, 0.3 * (1 - (i / #self.player.trajectoryPoints)))  -- Fade out opacity
            love.graphics.line(
                self.player.trajectoryPoints[i].x, 
                self.player.trajectoryPoints[i].y,
                self.player.trajectoryPoints[i+1].x,
                self.player.trajectoryPoints[i+1].y
            )
        end
        
        -- Draw landing point indicator
        if #self.player.trajectoryPoints > 0 then
            local landing = self.player.trajectoryPoints[#self.player.trajectoryPoints]
            love.graphics.setColor(1, 0.5, 0, 0.7)  -- Orange, semi-transparent
            love.graphics.circle("line", landing.x, landing.y, 10)
            love.graphics.line(
                landing.x - 10, landing.y,
                landing.x + 10, landing.y
            )
            love.graphics.line(
                landing.x, landing.y - 10,
                landing.x, landing.y + 10
            )
        end
    end
    
    -- Draw drag vector indicator
    if self.player.dragStartX and self.player.dragStartY then
        -- Draw line from start point to current drag point
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.line(
            self.player.dragStartX, 
            self.player.dragStartY, 
            self.player.dragStartX + self.player.dragVector.x, 
            self.player.dragStartY + self.player.dragVector.y
        )
        
        -- Draw circle at start point
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", self.player.dragStartX, self.player.dragStartY, 8)
        
        -- Draw arrow at end point (opposite of drag direction to show dash direction)
        local dashDirX, dashDirY
        local dragDistance = math.sqrt(self.player.dragVector.x^2 + self.player.dragVector.y^2)
        
        if dragDistance > 0 then
            dashDirX = -self.player.dragVector.x / dragDistance
            dashDirY = -self.player.dragVector.y / dragDistance
            
            -- Calculate dash power based on drag distance
            local dashPower = math.min(dragDistance, self.player.maxDragDistance) / self.player.maxDragDistance
            
            -- Draw arrow in dash direction with color based on power
            love.graphics.setColor(1, dashPower, 0, 0.7)
            
            -- Arrow position
            local arrowX = self.player.dragStartX + self.player.dragVector.x
            local arrowY = self.player.dragStartY + self.player.dragVector.y
            local arrowLength = 20 * dashPower
            
            -- Draw arrow line
            love.graphics.line(
                arrowX, 
                arrowY, 
                arrowX + dashDirX * arrowLength, 
                arrowY + dashDirY * arrowLength
            )
            
            -- Draw arrowhead
            local headSize = 8 * dashPower
            local perpX = -dashDirY
            local perpY = dashDirX
            
            love.graphics.polygon(
                "fill", 
                arrowX + dashDirX * arrowLength, 
                arrowY + dashDirY * arrowLength,
                arrowX + dashDirX * (arrowLength - headSize) + perpX * headSize/2,
                arrowY + dashDirY * (arrowLength - headSize) + perpY * headSize/2,
                arrowX + dashDirX * (arrowLength - headSize) - perpX * headSize/2,
                arrowY + dashDirY * (arrowLength - headSize) - perpY * headSize/2
            )
        end
    end
end

function DraggingState:getName()
    return "Dragging"
end

return DraggingState