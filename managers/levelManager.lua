local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager:new()
    local self = setmetatable({}, LevelManager)
    self.currentLevel = 1
    self.levelConfigs = {
        -- Level 1
        {
            enemyTypes = {"bat"},
            enemyChance = 0.6,
            platformDensity = 1.0,
            springboardChance = 0.2,
            backgroundColor = {0.1, 0.1, 0.2},
            targetHeight = 2000
        },
        -- Level 2
        {
            enemyTypes = {"bat", "slime"},
            enemyChance = 0.7,
            platformDensity = 0.8,
            springboardChance = 0.3,
            backgroundColor = {0.15, 0.1, 0.25},
            targetHeight = 3000
        },
        -- More levels...
    }
    return self
end

-- Implement getConfig, checkLevelProgress methods

return LevelManager