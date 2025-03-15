-- physics.lua - Common physics calculations for consistent behavior

local Physics = {}

-- Log function for debugging
function Physics.logDashParams(label, x, y, direction, speed, power, duration)
    print(string.format("[%s] Pos: (%.2f, %.2f), Dir: (%.2f, %.2f), Speed: %.2f, Power: %.2f, Duration: %.2f",
        label, x, y, direction.x, direction.y, speed, power, duration))
end

-- Calculate dash trajectory (visualization)
function Physics.calculateDashTrajectory(startX, startY, direction, speed, power, dashDuration, gravity, pointCount)
    local trajectory = {}
    
    -- First half: Dash trajectory
    local dashPoints = math.floor(pointCount / 2)
    
    -- Velocity magnitude
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
    local maxFallTime = 0.5  -- How far to predict falling
    
    for i = 1, fallPoints do
        local timeRatio = i / fallPoints
        local fallTime = timeRatio * maxFallTime
        
        -- Horizontal movement: small momentum from dash
        local x = dashEndX + (direction.x * velocity * 0.05) * fallTime
        
        -- Vertical movement: apply gravity
        local y = dashEndY + 0.5 * gravity * fallTime * fallTime
        
        table.insert(trajectory, {x = x, y = y})
    end
    
    return trajectory
end

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
    
    return centerX, centerY  -- Return center position for afterimages
end

-- Calculate dash parameters from a drag vector
function Physics.calculateDashParams(dragVector, minDragDistance, maxDragDistance, minDashDuration, maxDashDuration)
    -- Calculate drag distance
    local dragDistance = math.sqrt(dragVector.x^2 + dragVector.y^2)
    
    -- Check if drag is significant
    if dragDistance < minDragDistance then
        return nil
    end
    
    -- Calculate normalized direction (opposite of drag)
    local direction = {
        x = -dragVector.x / dragDistance,
        y = -dragVector.y / dragDistance
    }
    
    -- Calculate power based on drag distance (clamped to max)
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

return Physics