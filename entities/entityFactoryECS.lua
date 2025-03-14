local EntityFactoryECS = {}
local ECSEntity = require("entities/ecsEntity")
local XpPelletECS = require("entities/xpPelletECS")
local BatECS = require("entities/batECS")
local PowerUpECS = require("entities/powerUpECS")

function EntityFactoryECS.new(ecsWorld)
    local factory = {}
    factory.ecsWorld = ecsWorld
    
    -- Create a platform entity
    function factory:createPlatform(x, y, width, height)
        local platform = ECSEntity.new(x, y, width, height, {
            type = "platform",
            collisionLayer = "platform",
            collidesWithLayers = {"player", "enemy"},
            isSolid = true,
            color = {0.5, 0.5, 0.5, 1}
        })
        
        return platform
    end
    
    -- Create a moving platform entity
    function factory:createMovingPlatform(x, y, width, height, minY, maxY, speed)
        local platform = ECSEntity.new(x, y, width, height, {
            type = "movingPlatform",
            collisionLayer = "platform",
            collidesWithLayers = {"player", "enemy"},
            isSolid = true,
            color = {0.3, 0.7, 0.3, 1}
        })
        
        -- Add movement component
        local movementComponent = {
            minY = minY or y - 100,
            maxY = maxY or y + 100,
            speed = speed or 50,
            direction = 1
        }
        
        platform.ecsEntity:addComponent("platformMovement", movementComponent)
        
        return platform
    end
    
    -- Create a springboard entity
    function factory:createSpringboard(x, y, width, height)
        local springboard = ECSEntity.new(x, y, width, height, {
            type = "springboard",
            collisionLayer = "platform",
            collidesWithLayers = {"player", "enemy"},
            isSolid = true,
            color = {0.8, 0.3, 0.8, 1},
            boostForce = 800
        })
        
        return springboard
    end
    
    -- Create an enemy entity
    function factory:createEnemy(x, y, enemyType)
        local enemyTypes = {
            basic = {
                width = 32,
                height = 32,
                health = 3,
                damage = 1,
                moveSpeed = 50,
                color = {0.8, 0.2, 0.2, 1}
            },
            flying = {
                width = 24,
                height = 24,
                health = 2,
                damage = 1,
                moveSpeed = 80,
                color = {0.2, 0.2, 0.8, 1},
                flying = true
            },
            boss = {
                width = 64,
                height = 64,
                health = 10,
                damage = 2,
                moveSpeed = 30,
                color = {0.8, 0.1, 0.1, 1}
            }
        }
        
        local enemyConfig = enemyTypes[enemyType] or enemyTypes.basic
        
        local enemy = ECSEntity.new(x, y, enemyConfig.width, enemyConfig.height, {
            type = "enemy",
            collisionLayer = "enemy",
            collidesWithLayers = {"player", "platform"},
            isSolid = true,
            color = enemyConfig.color
        })
        
        -- Add enemy component
        enemy.ecsEntity:addComponent("enemy", {
            health = enemyConfig.health,
            damage = enemyConfig.damage,
            moveSpeed = enemyConfig.moveSpeed,
            flying = enemyConfig.flying or false,
            patrolDistance = 100,
            patrolDirection = 1,
            aggroRange = 200,
            attackRange = 50,
            attackCooldown = 1,
            attackTimer = 0
        })
        
        return enemy
    end
    
    -- Create an XP pellet entity
    function factory:createXpPellet(x, y, value)
        local pellet = XpPelletECS.new(x, y, value)
        return pellet
    end
    
    -- Create a collectible entity
    function factory:createCollectible(x, y, collectibleType)
        local collectibleTypes = {
            health = {
                width = 16,
                height = 16,
                color = {0.2, 0.8, 0.2, 1},
                healAmount = 1
            },
            key = {
                width = 16,
                height = 16,
                color = {0.8, 0.8, 0.2, 1}
            },
            powerup = {
                width = 16,
                height = 16,
                color = {0.2, 0.2, 0.8, 1},
                duration = 10
            }
        }
        
        local collectibleConfig = collectibleTypes[collectibleType] or collectibleTypes.health
        
        local collectible = ECSEntity.new(x, y, collectibleConfig.width, collectibleConfig.height, {
            type = "collectible",
            collectibleType = collectibleType,
            collisionLayer = "collectible",
            collidesWithLayers = {"player"},
            isSolid = false,
            color = collectibleConfig.color
        })
        
        -- Add collectible component
        collectible.ecsEntity:addComponent("collectible", {
            collectibleType = collectibleType,
            healAmount = collectibleConfig.healAmount,
            duration = collectibleConfig.duration
        })
        
        return collectible
    end
    
    -- Create a power-up entity
    function factory:createPowerUp(x, y, powerupType)
        local powerup = PowerUpECS:new(x, y, powerupType)
        return powerup
    end
    
    -- Create a bat enemy entity
    function factory:createBat(x, y)
        local bat = BatECS:new(x, y)
        return bat
    end
    
    -- Create a player entity
    function factory:createPlayer(x, y)
        local PlayerECS = require("entities/playerECS")
        local player = PlayerECS.new(x, y)
        
        -- Add any additional player setup here
        
        return player
    end
    
    return factory
end

return EntityFactoryECS 