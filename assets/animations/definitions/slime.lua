-- assets/animations/definitions/slime.lua
-- Animation definitions for the slime enemy

return {
    -- Default animation to play when no state is set
    default = "idle",
    
    -- Idle animation (subtle breathing or hovering)
    idle = {
        frames = {1, 2, 3, 4, 3, 2},
        frameTime = 0.2,
        loop = true
    },
    
    -- Moving animation
    moving = {
        frames = {1, 2, 3, 4, 5, 6},
        frameTime = 0.15,
        loop = true
    },
    
    -- Damaged animation
    damaged = {
        frames = {1, 2, 1},
        frameTime = 0.1,
        loop = false
    },
    
    -- Death animation
    death = {
        frames = {1, 2, 3, 4, 5, 6},
        frameTime = 0.1,
        loop = false
    }
} 