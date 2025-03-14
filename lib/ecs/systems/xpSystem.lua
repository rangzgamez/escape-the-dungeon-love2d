-- lib/ecs/systems/xpSystem.lua
-- XP System for managing XP pellets and player progression

local System = require("lib/ecs/system")
local Events = require("lib/events")

local XpSystem = setmetatable({}, {__index = System})
XpSystem.__index = XpSystem

function XpSystem.create()
    local self = setmetatable(System.create("XpSystem"), XpSystem)
    
    -- Set required components
    self:requires("transform", "xp")
    
    -- Set priority
    self:setPriority(30)
    
    -- XP pellet pool
    self.pelletPool = {}
    
    -- Collection radius properties
    self.baseCollectionRadius = 50 -- Base collection radius
    self.collectionRadiusBonus = 0 -- Bonus from upgrades
    self.attractionStrength = 200  -- How fast pellets are pulled to player
    
    return self
end

-- Update the XP system
function XpSystem:update(dt, entityManager)
    -- Get all entities with XP component
    local entities = entityManager:getEntitiesWith("xp")
    
    -- Get player entity
    local playerEntities = entityManager:getEntitiesWith("player")
    local player = playerEntities[1] -- Assume only one player
    
    -- Update each XP entity
    for _, entity in ipairs(entities) do
        if entity.active then
            self:updateXpEntity(entity, dt, player)
        end
    end
    
    -- Clean up inactive entities
    self:cleanupInactiveEntities(entityManager)
end

-- Update a single XP entity
function XpSystem:updateXpEntity(entity, dt, player)
    local transform = entity:getComponent("transform")
    local xp = entity:getComponent("xp")
    local physics = entity:getComponent("physics")
    
    -- Skip if missing required components
    if not transform or not transform.position or not xp or not physics then
        return
    end
    
    -- Update lifetime
    if xp.lifetime then
        xp.lifetime = xp.lifetime - dt
        if xp.lifetime <= 0 then
            entity.active = false
            return
        end
    end
    
    -- Handle magnetism if player exists and XP is magnetizable
    if player and xp.magnetizable then
        local playerTransform = player:getComponent("transform")
        
        if playerTransform and playerTransform.position then
            -- Calculate distance to player
            local dx = playerTransform.position.x - transform.position.x
            local dy = playerTransform.position.y - transform.position.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Apply magnetism if within range
            local magnetRange = 150 -- Range at which XP starts being pulled
            
            if distance < magnetRange then
                -- Calculate pull strength (stronger as distance decreases)
                local pullStrength = math.max(0, 1 - distance / magnetRange) * 300
                
                -- Normalize direction
                local nx = dx / distance
                local ny = dy / distance
                
                -- Apply pull force
                physics.velocity.x = physics.velocity.x + nx * pullStrength * dt
                physics.velocity.y = physics.velocity.y + ny * pullStrength * dt
            end
        end
    end
end

-- Clean up inactive entities
function XpSystem:cleanupInactiveEntities(entityManager)
    local entities = entityManager:getEntitiesWith("transform", "xp")
    
    for _, entity in ipairs(entities) do
        if not entity.active then
            -- Return to pool if it's from a pool
            entityManager:returnToPool(entity)
        end
    end
end

-- Create XP pellets when an enemy is killed
function XpSystem:onEnemyKill(entityManager, enemy, comboCount)
    -- Determine XP amount based on enemy type and combo
    local enemyType = enemy:getComponent("type")
    local baseXp = 5
    
    -- Bonus XP for combo
    local comboBonus = math.floor(comboCount / 2)
    local totalXp = baseXp + comboBonus
    
    -- Distribute XP across multiple pellets
    local pelletCount = math.min(totalXp, 5) -- Max 5 pellets
    local xpPerPellet = math.ceil(totalXp / pelletCount)
    
    -- Get enemy position
    local enemyTransform = enemy:getComponent("transform")
    local enemyCenterX = enemyTransform.x + enemyTransform.width / 2
    local enemyCenterY = enemyTransform.y + enemyTransform.height / 2
    
    print("Enemy center position:", enemyCenterX, enemyCenterY)
    
    -- Create pellets around the enemy
    local pellets = {}
    
    for i = 1, pelletCount do
        -- Create pellets at the enemy's center with a small random offset
        local offsetX = love.math.random(-10, 10)
        local offsetY = love.math.random(-10, 10)
        
        -- Calculate pellet position
        local pelletX = enemyCenterX + offsetX
        local pelletY = enemyCenterY + offsetY
        
        -- Create pellet entity
        local pellet = entityManager:getPooledEntity("xpPellet")
        
        -- Add components
        pellet:addComponent("transform", {
            x = pelletX,
            y = pelletY,
            width = 20,
            height = 20
        })
        
        pellet:addComponent("physics", {
            velocityX = math.cos(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            velocityY = math.sin(love.math.random() * math.pi * 2) * love.math.random(100, 200),
            gravity = false,
            dampening = 0.95
        })
        
        pellet:addComponent("collider", {
            offsetX = 0,
            offsetY = 0,
            width = 20,
            height = 20,
            layer = "collectible",
            collidesWithLayers = {"player"}
        })
        
        pellet:addComponent("renderer", {
            type = "custom",
            layer = 20,
            color = {0.2, 0.8, 1},
            drawFunction = function(entity)
                self:drawXpPellet(entity)
            end
        })
        
        pellet:addComponent("xp", {
            value = xpPerPellet,
            collectible = false,
            collectionDelay = 0.5,
            lifetime = 15.0,
            magnetizable = false
        })
        
        pellet:addComponent("type", {
            name = "xpPellet"
        })
        
        -- Add to pellets list
        table.insert(pellets, pellet)
        
        print("Created XP pellet at:", pelletX, pelletY, "with velocity:", 
              pellet:getComponent("physics").velocityX, 
              pellet:getComponent("physics").velocityY)
    end
    
    -- Fire event
    Events.fire("xpPelletsCreated", {
        pellets = pellets,
        source = enemy
    })
    
    return pellets
end

-- Draw an XP pellet
function XpSystem:drawXpPellet(entity)
    local transform = entity:getComponent("transform")
    local renderer = entity:getComponent("renderer")
    local xp = entity:getComponent("xp")
    
    -- Draw outer glow
    love.graphics.setColor(renderer.color[1], renderer.color[2], renderer.color[3], 0.4)
    love.graphics.circle("fill", transform.width/2, transform.height/2, transform.width * 2.5)
    
    love.graphics.setColor(renderer.color[1], renderer.color[2], renderer.color[3], 0.6)
    love.graphics.circle("fill", transform.width/2, transform.height/2, transform.width * 1.8)
    
    -- Draw gem shape for XP pellet
    love.graphics.setColor(renderer.color[1], renderer.color[2], renderer.color[3])
    
    love.graphics.polygon("fill", 
        transform.width/2, 0,                      -- Top point
        transform.width, transform.height/2,       -- Right point
        transform.width/2, transform.height,       -- Bottom point
        0, transform.height/2                      -- Left point
    )
    
    -- Draw border
    if xp.collectible then
        love.graphics.setColor(1, 1, 1, 0.9)
    else
        love.graphics.setColor(1, 1, 1, 0.6)  -- Less visible when not collectible
    end
    
    love.graphics.setLineWidth(2) -- Thicker line
    love.graphics.polygon("line", 
        transform.width/2, 0,                      -- Top point
        transform.width, transform.height/2,       -- Right point
        transform.width/2, transform.height,       -- Bottom point
        0, transform.height/2                      -- Left point
    )
    love.graphics.setLineWidth(1) -- Reset line width
    
    -- Draw highlight
    love.graphics.setColor(1, 1, 1, xp.collectible and 1.0 or 0.7)
    love.graphics.line(
        transform.width/4, transform.height/4,
        transform.width/2, 0,
        3 * transform.width/4, transform.height/4
    )
    
    -- Add a small "XP" text in the center for clarity
    love.graphics.setColor(1, .5, .5, xp.collectible and 0.9 or 0.6)
    local font = love.graphics.getFont()
    local text = "XP"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, transform.width/2 - textWidth/2, transform.height/2 - textHeight/2, 0, 0.7, 0.7)
    
    -- Draw debug info if needed
    if entity:hasComponent("debug") and entity:getComponent("debug").enabled then
        -- Draw position info
        local posText = string.format("Pos: %.0f, %.0f", transform.x, transform.y)
        local posWidth = font:getWidth(posText)
        
        -- Draw background for position text
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 
            transform.width/2 - posWidth/2 - 4, 
            transform.height + 10,
            posWidth + 8,
            20)
            
        -- Draw position text
        love.graphics.setColor(1, 1, 0, 1)  -- Yellow for position
        love.graphics.print(
            posText, 
            transform.width/2 - posWidth/2, 
            transform.height + 12,
            0,
            1.0, 1.0
        )
    end
end

-- Set collection radius modifier (for upgrades)
function XpSystem:setCollectionRadiusBonus(bonus)
    self.collectionRadiusBonus = bonus
end

return XpSystem 