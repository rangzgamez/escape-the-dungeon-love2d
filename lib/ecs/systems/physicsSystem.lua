-- lib/ecs/systems/physicsSystem.lua
-- Physics System for handling movement and gravity

local System = require("lib/ecs/system")

local PhysicsSystem = setmetatable({}, {__index = System})
PhysicsSystem.__index = PhysicsSystem

function PhysicsSystem.create()
    local self = setmetatable(System.create("PhysicsSystem"), PhysicsSystem)
    
    -- Set required components
    self:requires("transform", "physics")
    
    -- Set priority (run after collision detection)
    self:setPriority(20)
    
    -- Global physics settings
    self.gravity = 400
    self.terminalVelocity = 1000
    self.dampening = 0.98
    
    return self
end

-- Update the physics system
function PhysicsSystem:update(dt, entityManager)
    -- Get all entities with transform and physics components
    local entities = entityManager:getEntitiesWith("transform", "physics")
    
    -- Update each entity
    for _, entity in ipairs(entities) do
        if entity.active then
            self:updateEntity(entity, dt)
        end
    end
end

-- Update a single entity
function PhysicsSystem:updateEntity(entity, dt)
    local transform = entity:getComponent("transform")
    local physics = entity:getComponent("physics")
    
    -- Skip if missing required components or if transform doesn't have position
    if not transform or not transform.position or not physics then
        return
    end
    
    -- Skip if physics is disabled
    if physics.disabled then
        return
    end
    
    -- Apply gravity if affected by gravity
    if physics.affectedByGravity then
        physics.velocity.y = physics.velocity.y + physics.gravity * dt
        
        -- Limit to terminal velocity
        if physics.velocity.y > self.terminalVelocity then
            physics.velocity.y = self.terminalVelocity
        end
    end
    
    -- Apply friction
    if physics.isGrounded and physics.friction then
        physics.velocity.x = physics.velocity.x * (1 - physics.friction)
        
        -- Stop if velocity is very small
        if math.abs(physics.velocity.x) < 0.1 then
            physics.velocity.x = 0
        end
    end
    
    -- Apply air resistance
    if not physics.isGrounded and physics.airResistance then
        physics.velocity.x = physics.velocity.x * (1 - physics.airResistance)
    end
    
    -- Apply velocity to position
    transform.position.x = transform.position.x + physics.velocity.x * dt
    transform.position.y = transform.position.y + physics.velocity.y * dt
    
    -- Update collider position if entity has one
    if entity:hasComponent("collider") then
        local collider = entity:getComponent("collider")
        
        -- Update bounds if entity has them
        if entity.bounds then
            entity.bounds.x = transform.position.x + collider.offsetX
            entity.bounds.y = transform.position.y + collider.offsetY
        end
    end
    
    -- Reset onGround flag (will be set by collision system if needed)
    physics.isGrounded = false
    
    -- Apply dampening
    if physics.dampening then
        physics.velocity.x = physics.velocity.x * physics.dampening
        physics.velocity.y = physics.velocity.y * physics.dampening
    end
end

return PhysicsSystem 