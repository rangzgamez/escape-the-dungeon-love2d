local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager:new()
    local self = setmetatable({}, SoundManager)
    
    -- Sound effects
    self.sounds = {
        jump = nil,
        dash = nil,
        land = nil,
        hit = nil,
        enemyDefeat = nil,
        powerup = nil
    }
    
    -- Music tracks
    self.music = {
        menu = nil,
        gameplay = nil,
        boss = nil
    }
    
    -- Settings
    self.soundVolume = 0.7
    self.musicVolume = 0.5
    self.musicPlaying = nil
    
    return self
end

-- Implement load, playSound, playMusic, stopMusic, setVolume methods

return SoundManager