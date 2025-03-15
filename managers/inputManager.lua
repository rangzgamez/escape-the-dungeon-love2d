-- managers/inputManager.lua - Manages input and dragging for Love2D Vertical Jumper
local Events = require("lib/events")
local Physics = require("lib/physics")
local InputManager = {}
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
    
    -- Target information (captured at drag start)
    self.targetPlayer = nil
    self.playerX = nil
    self.playerY = nil
    self.playerWidth = nil
    self.playerHeight = nil
    self.playerDashSpeed = nil
    self.playerGravity = nil
    
    -- Trajectory preview
    self.trajectoryPoints = {}
    self.trajectoryPointCount = 20
    self.trajectoryTimeStep = 0.1
    
    -- Settings
    self.minDragDistance = 20 -- Minimum drag distance to trigger actions
    self.maxDragDistance = 150 -- Maximum drag for power calculation
    
    return self
end

function InputManager:update(dt, camera)
    -- Nothing to update if not dragging
    if not self.isDragging then
        return
    end
    
    -- Update drag vector
    if self.currentDragX and self.currentDragY and self.dragStartX and self.dragStartY then
        self.dragVector.x = self.currentDragX - self.dragStartX
        self.dragVector.y = self.currentDragY - self.dragStartY
        
        -- Calculate trajectory if we have a target player
        if self.targetPlayer then
            -- IMPORTANT: Update player position before recalculating trajectory
            self.playerX = self.targetPlayer.x
            self.playerY = self.targetPlayer.y
            
            -- Recalculate trajectory based on updated player position
            self:calculateTrajectory()
        end
    end
end

function InputManager:startDrag(x, y, camera)
    if self.isDragging then
        return false -- Already dragging
    end
    
    -- Store original screen coordinates for drawing
    self.screenStartX = x
    self.screenStartY = y
    
    -- Adjust for camera position if provided
    local adjustedY = y
    if camera then
        adjustedY = y + camera.y - love.graphics.getHeight() / 2
    end
    
    self.isDragging = true
    self.dragStartX = x  -- This should remain in screen coordinates
    self.dragStartY = y  -- This should remain in screen coordinates
    self.worldDragStartY = adjustedY  -- Store the world coordinate separately
    self.currentDragX = x
    self.currentDragY = y  -- Keep in screen coordinates
    self.worldCurrentDragY = adjustedY  -- Store world coordinate
    self.dragVector = {x = 0, y = 0}
    self.trajectoryPoints = {}
    
    -- Fire event for drag start
    Events.fire("dragStart", {
        x = x,
        y = adjustedY,  -- Use world coordinate for game logic
        screenY = y
    })
    
    return true
end

-- Capture player information at the start of a drag
function InputManager:setTargetPlayer(player)
    if player then
        self.targetPlayer = player
        self.playerX = player.x
        self.playerY = player.y
        self.playerWidth = player.width
        self.playerHeight = player.height
        self.playerDashSpeed = player.dashSpeed
        self.playerGravity = player.gravity
    else
        self.targetPlayer = nil
    end
end

function InputManager:updateDrag(x, y, camera)
    if not self.isDragging then
        return false -- Not dragging
    end
    
    -- Store screen coordinates for drawing
    self.currentDragX = x
    self.currentDragY = y
    
    -- Adjust for camera position if provided
    local adjustedY = y
    if camera then
        adjustedY = y + camera.y - love.graphics.getHeight() / 2
    end
    
    self.worldCurrentDragY = adjustedY
    
    -- Update drag vector using world coordinates for gameplay calculations
    self.dragVector.x = x - self.dragStartX
    self.dragVector.y = adjustedY - self.worldDragStartY
    
    -- Fire event for drag update
    Events.fire("dragUpdate", {
        x = x,
        y = adjustedY,
        screenY = y,
        dragVector = self.dragVector
    })
    
    return true
end

-- In the endDrag method, update the firing of the dragEnd event
function InputManager:endDrag(x, y, camera)
    if not self.isDragging then
        return false -- Not dragging
    end
    
    -- Store screen coordinates for drawing
    self.currentDragX = x
    self.currentDragY = y
    
    -- Update drag vector 
    self.dragVector.x = x - self.dragStartX
    self.dragVector.y = y - self.dragStartY
    -- Calculate drag distance
    local dragDistance = math.sqrt(self.dragVector.x^2 + self.dragVector.y^2)
    local isSignificantDrag = dragDistance > self.minDragDistance
    
    -- Calculate normalized direction and power
    local direction = {x = 0, y = 0}
    local power = 0
    
    if dragDistance > 0 then
        direction.x = -self.dragVector.x / dragDistance
        direction.y = -self.dragVector.y / dragDistance
        power = math.min(dragDistance, self.maxDragDistance) / self.maxDragDistance
    end
        
    -- Fire event for drag end with updated direction
    Events.fire("dragEnd", {
        x = x,
        y = adjustedY,
        screenY = y,
        dragVector = self.dragVector,
        distance = dragDistance,
        direction = direction,
        power = power,
        isSignificantDrag = isSignificantDrag,
        trajectoryPoints = self.trajectoryPoints
    })
    -- Reset drag state
    self.isDragging = false
    self.dragStartX = nil
    self.dragStartY = nil
    self.worldDragStartY = nil
    self.currentDragX = nil
    self.currentDragY = nil
    self.worldCurrentDragY = nil
    self.dragVector = {x = 0, y = 0}
    -- Keep trajectory points until next drag
    self.targetPlayer = nil
    
    return isSignificantDrag
end

function InputManager:cancelDrag()
    if not self.isDragging then
        return false -- Not dragging
    end
    
    -- Fire event for drag cancel
    Events.fire("dragCancel", {})
    
    -- Reset drag state
    self.isDragging = false
    self.dragStartX = nil
    self.dragStartY = nil
    self.currentDragX = nil
    self.currentDragY = nil
    self.dragVector = {x = 0, y = 0}
    self.trajectoryPoints = {}
    self.targetPlayer = nil
    
    return true
end

-- In the calculateTrajectory method, ensure we're using world coordinates
function InputManager:calculateTrajectory()
    -- Calculate dash params from drag vector
    local dashParams = Physics.calculateDashParams(
        self.dragVector,
        self.minDragDistance,
        self.maxDragDistance,
        self.targetPlayer.minDashDuration,
        self.targetPlayer.maxDashDuration
    )
    
    -- If drag not significant, clear trajectory
    if not dashParams then
        self.trajectoryPoints = {}
        return
    end
    
    -- Store the dash parameters for later use
    self.dashParams = dashParams
    self.dashParams.speed = self.playerDashSpeed
    
    -- Calculate player center position
    local centerX = self.playerX + self.playerWidth/2
    local centerY = self.playerY + self.playerHeight/2
    
    -- Calculate trajectory using the shared physics
    self.trajectoryPoints = Physics.calculateDashTrajectory(
        centerX,
        centerY,
        dashParams.direction,
        self.playerDashSpeed,
        dashParams.power,
        dashParams.duration,
        self.playerGravity,
        200  -- Number of trajectory points
    )
    
    -- IMPORTANT: Keep trajectory points as center coordinates
    -- We'll convert to screen coordinates only during drawing
end

function InputManager:getDragData()
    if not self.isDragging then
        return nil
    end
    
    -- Calculate drag distance
    local dragDistance = math.sqrt(self.dragVector.x^2 + self.dragVector.y^2)
    
    -- Calculate direction (normalized)
    local direction = {x = 0, y = 0}
    if dragDistance > 0 then
        direction.x = -self.dragVector.x / dragDistance
        direction.y = -self.dragVector.y / dragDistance
    end
    
    -- Calculate power (0 to 1 based on max distance)
    local power = math.min(dragDistance, self.maxDragDistance) / self.maxDragDistance
    
    return {
        isDragging = self.isDragging,
        startX = self.dragStartX,
        startY = self.dragStartY,
        currentX = self.currentDragX,
        currentY = self.currentDragY,
        dragVector = self.dragVector,
        distance = dragDistance,
        direction = direction,
        power = power,
        isSignificant = dragDistance > self.minDragDistance
    }
end

function InputManager:isDraggingActive()
    return self.isDragging
end

-- Mouse and touch event handlers
function InputManager:mousepressed(x, y, button, camera, player)
    if button == 1 then -- Left button
        local started = self:startDrag(x, y, camera)
        if started and player then
            self:setTargetPlayer(player)
        end
        return started
    end
    return false
end

function InputManager:mousemoved(x, y, camera)
    return self:updateDrag(x, y, camera)
end

function InputManager:mousereleased(x, y, button, camera)
    if button == 1 then -- Left button
        return self:endDrag(x, y, camera)
    end
    return false
end

function InputManager:touchpressed(id, x, y, camera, player)
    local started = self:startDrag(x, y, camera)
    if started and player then
        self:setTargetPlayer(player)
    end
    return started
end

function InputManager:touchmoved(id, x, y, camera)
    return self:updateDrag(x, y, camera)
end

function InputManager:touchreleased(id, x, y, camera)
    return self:endDrag(x, y, camera)
end

-- Draw drag visualization (trajectory, etc.)
function InputManager:draw(camera)
    if not self.isDragging then
        return
    end
    
    -- Draw drag line using screen coordinates
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
    
    -- Calculate drag data for visualization
    local dragData = self:getDragData()
    if dragData and dragData.isSignificant then
        -- Draw direction arrow
        local arrowLength = 20 * dragData.power
        local arrowX = self.currentDragX
        local arrowY = self.currentDragY
        
        -- Draw arrow in dash direction with color based on power
        love.graphics.setColor(1, dragData.power, 0, 0.7)
        
        -- Draw arrow line
        love.graphics.line(
            arrowX, 
            arrowY, 
            arrowX + dragData.direction.x * arrowLength, 
            arrowY + dragData.direction.y * arrowLength
        )
        
        -- Draw arrowhead
        local headSize = 8 * dragData.power
        local perpX = -dragData.direction.y
        local perpY = dragData.direction.x
        
        love.graphics.polygon(
            "fill", 
            arrowX + dragData.direction.x * arrowLength, 
            arrowY + dragData.direction.y * arrowLength,
            arrowX + dragData.direction.x * (arrowLength - headSize) + perpX * headSize/2,
            arrowY + dragData.direction.y * (arrowLength - headSize) + perpY * headSize/2,
            arrowX + dragData.direction.x * (arrowLength - headSize) - perpX * headSize/2,
            arrowY + dragData.direction.y * (arrowLength - headSize) - perpY * headSize/2
        )
    end
    
    -- Draw trajectory points if available, adjusting for camera position
    if #self.trajectoryPoints > 1 and camera then
        love.graphics.setColor(1, 1, 1, 0.4)  -- Semi-transparent white
        
        local cameraOffset = camera.y - love.graphics.getHeight() / 2
        local halfWidth = self.playerWidth/2
        local halfHeight = self.playerHeight/2
        
        -- Draw dots along trajectory
        for i, point in ipairs(self.trajectoryPoints) do
            local screenX = point.x - halfWidth  -- Convert from center to top-left for display
            local screenY = point.y - halfHeight - cameraOffset  -- Convert from world to screen coords
            
            local size = 5 * (1 - (i / #self.trajectoryPoints))  -- Start bigger, end smaller
            love.graphics.circle("fill", point.x, point.y - cameraOffset, size)  -- Draw at center
        end
        
        -- Draw connecting lines for trajectory (keep as center points)
        for i = 1, #self.trajectoryPoints - 1 do
            love.graphics.setColor(1, 1, 1, 0.3 * (1 - (i / #self.trajectoryPoints)))
            
            local screenX1 = self.trajectoryPoints[i].x
            local screenY1 = self.trajectoryPoints[i].y - cameraOffset
            local screenX2 = self.trajectoryPoints[i+1].x
            local screenY2 = self.trajectoryPoints[i+1].y - cameraOffset
            
            love.graphics.line(screenX1, screenY1, screenX2, screenY2)
        end
        
        -- Draw landing point indicator (at center point)
        if #self.trajectoryPoints > 0 then
            local landing = self.trajectoryPoints[#self.trajectoryPoints]
            local landingScreenX = landing.x
            local landingScreenY = landing.y - cameraOffset
            
            love.graphics.setColor(1, 0.5, 0, 0.7)  -- Orange, semi-transparent
            love.graphics.circle("line", landingScreenX, landingScreenY, 10)
            love.graphics.line(
                landingScreenX - 10, landingScreenY,
                landingScreenX + 10, landingScreenY
            )
            love.graphics.line(
                landingScreenX, landingScreenY - 10,
                landingScreenX, landingScreenY + 10
            )
        end
    end
end

return InputManager