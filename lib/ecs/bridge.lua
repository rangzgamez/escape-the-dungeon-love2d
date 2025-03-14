-- lib/ecs/bridge.lua
-- Bridge between the old system and the new ECS system

local ECS = require("lib/ecs/ecs")
local CollisionSystem = require("lib/ecs/systems/collisionSystem")
local RenderSystem = require("lib/ecs/systems/renderSystem")
local PhysicsSystem = require("lib/ecs/systems/physicsSystem")
local XpSystem = require("lib/ecs/systems/xpSystem")
local Events = require("lib/events")

local Bridge = {}

-- Create a new ECS world
function Bridge.createWorld()
    local world = ECS.createWorld()
    
    -- Add systems
    world:addSystem(CollisionSystem.create())
    world:addSystem(PhysicsSystem.create())
    world:addSystem(RenderSystem.create())
    world:addSystem(XpSystem.create())
    
    return world
end

-- Convert a BaseEntity to an ECS entity
function Bridge.convertBaseEntityToECS(baseEntity, world)
    local entity = world:createEntity()
    
    -- Add transform component
    entity:addComponent("transform", {
        x = baseEntity.x,
        y = baseEntity.y,
        width = baseEntity.width,
        height = baseEntity.height,
        rotation = 0,
        scaleX = 1,
        scaleY = 1
    })
    
    -- Add collider component
    entity:addComponent("collider", {
        offsetX = baseEntity.boundingBoxOffset.x,
        offsetY = baseEntity.boundingBoxOffset.y,
        width = baseEntity.width + baseEntity.boundingBoxOffset.width,
        height = baseEntity.height + baseEntity.boundingBoxOffset.height,
        layer = baseEntity.collisionLayer,
        collidesWithLayers = baseEntity.collidesWithLayers
    })
    
    -- Add physics component
    entity:addComponent("physics", {
        velocityX = baseEntity.velocity.x,
        velocityY = baseEntity.velocity.y,
        gravity = baseEntity.gravity ~= nil,
        gravityScale = baseEntity.gravity / 400, -- Normalize to the system's gravity
        onGround = baseEntity.onGround,
        friction = 0.1,
        airResistance = 0.01,
        dampening = 0.98
    })
    
    -- Add type component
    entity:addComponent("type", {
        name = baseEntity.type
    })
    
    -- Add tag based on type
    entity:addTag(baseEntity.type)
    
    -- Add debug component if needed
    if baseEntity.debug then
        entity:addComponent("debug", {
            enabled = true
        })
    end
    
    -- Add specific components based on entity type
    if baseEntity.type == "xpPellet" then
        -- Add XP component
        entity:addComponent("xp", {
            value = baseEntity.value,
            collectible = baseEntity.collectible,
            collectionDelay = baseEntity.collectionDelay,
            lifetime = baseEntity.lifetime,
            magnetizable = baseEntity.magnetizable
        })
        
        -- Add renderer component
        entity:addComponent("renderer", {
            type = "custom",
            layer = 20,
            color = baseEntity.color,
            drawFunction = function(entity)
                world.systemManager:getSystem("XpSystem"):drawXpPellet(entity)
            end
        })
    else
        -- Add a basic renderer component
        entity:addComponent("renderer", {
            type = "rectangle",
            layer = 10,
            width = baseEntity.width,
            height = baseEntity.height,
            color = {1, 1, 1, 1},
            mode = "fill"
        })
    end
    
    -- Store reference to original entity
    entity.originalEntity = baseEntity
    
    return entity
end

-- Update an ECS entity from a BaseEntity
function Bridge.updateEntityFromBase(entity, baseEntity)
    -- Update transform
    local transform = entity:getComponent("transform")
    transform.x = baseEntity.x
    transform.y = baseEntity.y
    transform.width = baseEntity.width
    transform.height = baseEntity.height
    
    -- Update physics
    local physics = entity:getComponent("physics")
    physics.velocityX = baseEntity.velocity.x
    physics.velocityY = baseEntity.velocity.y
    physics.onGround = baseEntity.onGround
    
    -- Update collider
    local collider = entity:getComponent("collider")
    collider.offsetX = baseEntity.boundingBoxOffset.x
    collider.offsetY = baseEntity.boundingBoxOffset.y
    collider.width = baseEntity.width + baseEntity.boundingBoxOffset.width
    collider.height = baseEntity.height + baseEntity.boundingBoxOffset.height
    
    -- Update XP component if it exists
    if entity:hasComponent("xp") and baseEntity.type == "xpPellet" then
        local xp = entity:getComponent("xp")
        xp.collectible = baseEntity.collectible
        xp.magnetizable = baseEntity.magnetizable
        xp.lifetime = baseEntity.lifetime
    end
    
    -- Update active state
    if baseEntity.active ~= entity.active then
        if baseEntity.active then
            entity:activate()
        else
            entity:deactivate()
        end
    end
    
    -- Update bounds if they exist
    if entity.bounds then
        entity.bounds.x = transform.x + collider.offsetX
        entity.bounds.y = transform.y + collider.offsetY
        entity.bounds.width = collider.width
        entity.bounds.height = collider.height
    end
end

-- Update a BaseEntity from an ECS entity
function Bridge.updateBaseFromEntity(baseEntity, entity)
    -- Update position
    local transform = entity:getComponent("transform")
    baseEntity.x = transform.x
    baseEntity.y = transform.y
    
    -- Update velocity
    local physics = entity:getComponent("physics")
    baseEntity.velocity.x = physics.velocityX
    baseEntity.velocity.y = physics.velocityY
    baseEntity.onGround = physics.onGround
    
    -- Update XP properties if it's an XP pellet
    if baseEntity.type == "xpPellet" and entity:hasComponent("xp") then
        local xp = entity:getComponent("xp")
        baseEntity.collectible = xp.collectible
        baseEntity.magnetizable = xp.magnetizable
        baseEntity.lifetime = xp.lifetime
    end
    
    -- Update active state
    baseEntity.active = entity.active
end

-- Create XP pellets using the ECS system
function Bridge.createXpPellets(world, x, y, count, value)
    local xpSystem = world.systemManager:getSystem("XpSystem")
    local pellets = {}
    
    for i = 1, count do
        local pellet = world:getPooledEntity("xpPellet")
        
        -- Add components
        pellet:addComponent("transform", {
            x = x + love.math.random(-10, 10),
            y = y + love.math.random(-10, 10),
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
                xpSystem:drawXpPellet(entity)
            end
        })
        
        pellet:addComponent("xp", {
            value = value or 1,
            collectible = false,
            collectionDelay = 0.5,
            lifetime = 15.0,
            magnetizable = false
        })
        
        pellet:addComponent("type", {
            name = "xpPellet"
        })
        
        -- Add debug component
        pellet:addComponent("debug", {
            enabled = true
        })
        
        table.insert(pellets, pellet)
    end
    
    return pellets
end

-- Handle collision between ECS entities
function Bridge.handleCollision(entityA, entityB, collisionData)
    -- Get entity types
    local typeA = entityA:getComponent("type") and entityA:getComponent("type").name or "entity"
    local typeB = entityB:getComponent("type") and entityB:getComponent("type").name or "entity"
    
    -- Handle specific collision types
    
    -- Handle XP pellet collection
    if (typeA == "xpPellet" and typeB == "player") or
       (typeA == "player" and typeB == "xpPellet") then
        local pellet = typeA == "xpPellet" and entityA or entityB
        local player = typeA == "player" and entityA or entityB
        
        local xp = pellet:getComponent("xp")
        
        if xp and xp.collectible then
            -- Collect the XP
            Events.fire("xpCollected", {
                value = xp.value,
                player = player
            })
            
            -- Deactivate the pellet
            pellet:deactivate()
            
            -- Return to pool if world is available
            if _G.ecsWorld then
                _G.ecsWorld:returnToPool(pellet)
            end
        end
    end
    
    -- Handle player-platform collision
    if (typeA == "player" and (typeB == "platform" or typeB == "movingPlatform")) or
       ((typeA == "platform" or typeA == "movingPlatform") and typeB == "player") then
        local player = typeA == "player" and entityA or entityB
        local platform = typeA == "player" and entityB or entityA
        
        -- Check if player is above platform
        if collisionData.fromAbove then
            -- Get player movement component
            local movement = player:getComponent("movement")
            if movement then
                movement.isGrounded = true
                movement.velocityY = 0
                
                -- Reset midair jumps
                movement.midairJumps = movement.maxMidairJumps
            end
        end
    end
    
    -- Handle player-enemy collision
    if (typeA == "player" and (typeB == "enemy" or typeB == "slime")) or
       ((typeA == "enemy" or typeA == "slime") and typeB == "player") then
        local player = typeA == "player" and entityA or entityB
        local enemy = typeA == "player" and entityB or entityA
        
        -- Get player components
        local playerComponent = player:getComponent("player")
        local movement = player:getComponent("movement")
        
        if playerComponent and movement then
            -- Check if player is invulnerable
            if playerComponent.isInvulnerable then
                return
            end
            
            -- Check if player is dashing (can damage enemies while dashing)
            if movement.isDashing then
                -- Damage the enemy
                -- This would need to be implemented in the enemy entity
                return
            end
            
            -- Player takes damage
            playerComponent.health = playerComponent.health - 1
            playerComponent.isInvulnerable = true
            playerComponent.invulnerableTime = playerComponent.invulnerableDuration
            playerComponent.damageFlashTimer = playerComponent.invulnerableDuration
            
            -- Fire damage event
            Events.fire("playerDamage", {
                x = player:getComponent("transform").x,
                y = player:getComponent("transform").y,
                health = playerComponent.health
            })
        end
    end
    
    -- Handle player-springboard collision
    if (typeA == "player" and typeB == "springboard") or
       (typeA == "springboard" and typeB == "player") then
        local player = typeA == "player" and entityA or entityB
        local springboard = typeA == "player" and entityB or entityA
        
        -- Check if player is above springboard
        if collisionData.fromAbove then
            -- Get player movement component
            local movement = player:getComponent("movement")
            if movement then
                -- Apply springboard boost
                movement.velocityY = -1200 -- Strong upward boost
                
                -- Fire jump event
                Events.fire("playerJump", {
                    x = player:getComponent("transform").x,
                    y = player:getComponent("transform").y,
                    isSpringboardJump = true
                })
            end
        end
    end
end

-- Toggle debug drawing for collision system
function Bridge.toggleCollisionDebug(world)
    local collisionSystem = world.systemManager:getSystem("CollisionSystem")
    collisionSystem:toggleDebugDraw()
end

return Bridge 