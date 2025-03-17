-- assets/animations/definitions/player.lua
-- Animation definitions for the player character

return {
    -- Default animation to play when no state is set
    default = "idle",
    
    -- Idle animation (subtle breathing or hovering)
    idle = {
        frames = {1, 2, 3, 4, 3, 2},
        frameTime = 0.15,
        loop = true
    },
    
    -- Running animation for horizontal movement
    running = {
        frames = {5, 6, 7, 8, 9, 10},
        frameTime = 0.1,
        loop = true
    },
    
    -- Jumping animation (upward movement)
    jumping = {
        frames = {11, 12, 13},
        frameTime = 0.1,
        loop = false
    },
    
    -- Falling animation (downward movement)
    falling = {
        frames = {14, 15, 16},
        frameTime = 0.1,
        loop = true
    },
    
    -- Dashing animation
    dashing = {
        frames = {17, 18, 19, 20},
        frameTime = 0.05, -- Faster for dashing
        loop = true
    },
    
    -- Landing animation
    landing = {
        frames = {21, 22, 23},
        frameTime = 0.07,
        loop = false
    },
    
    -- Hit/damaged animation
    damaged = {
        frames = {24, 25, 26, 25, 24},
        frameTime = 0.08,
        loop = false
    },
    
    -- Level up animation
    levelUp = {
        frames = {27, 28, 29, 30, 31, 32},
        frameTime = 0.1,
        loop = false
    }
}