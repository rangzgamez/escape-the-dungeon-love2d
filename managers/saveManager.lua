local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:new()
    local self = setmetatable({}, SaveManager)
    
    self.saveFile = "escapeTheDungeon.save"
    self.defaultData = {
        highScore = 0,
        totalDistance = 0,
        playCount = 0,
        settings = {
            sound = true,
            music = true,
            effects = true,
            slowMotion = true,
            pauseOnDrag = false
        },
        unlocked = {
            doubleJump = true,
            tripleJump = false,
            superDash = false,
            shield = false
        }
    }
    
    return self
end

function SaveManager:saveGame(data)
    local success, errorMsg = pcall(function()
        local serialized = love.data.encode("string", "json", data)
        love.filesystem.write(self.saveFile, serialized)
    end)
    
    return success, errorMsg
end

function SaveManager:loadGame()
    if not love.filesystem.getInfo(self.saveFile) then
        -- No save file, return default data
        return self:getDefaultData()
    end
    
    local success, result = pcall(function()
        local content = love.filesystem.read(self.saveFile)
        if not content then return self:getDefaultData() end
        
        local decoded = love.data.decode("string", "json", content)
        return decoded
    end)
    
    if success then
        return result
    else
        print("Error loading save file: " .. tostring(result))
        return self:getDefaultData()
    end
end

function SaveManager:updateStats(stats)
    local data = self:loadGame()
    
    -- Update high score
    if stats.score and stats.score > data.highScore then
        data.highScore = stats.score
    end
    
    -- Update total distance
    if stats.distance then
        data.totalDistance = data.totalDistance + stats.distance
    end
    
    -- Increment play count
    data.playCount = data.playCount + 1
    
    -- Save updated data
    self:saveGame(data)
    
    return data
end

function SaveManager:updateSettings(settings)
    local data = self:loadGame()
    
    -- Update settings
    for key, value in pairs(settings) do
        data.settings[key] = value
    end
    
    -- Save updated data
    self:saveGame(data)
    
    return data
end

function SaveManager:unlockFeature(feature)
    local data = self:loadGame()
    
    -- Unlock the feature
    if data.unlocked[feature] ~= nil then
        data.unlocked[feature] = true
    end
    
    -- Save updated data
    self:saveGame(data)
    
    return data
end

function SaveManager:getDefaultData()
    -- Return a copy of default data
    return {
        highScore = self.defaultData.highScore,
        totalDistance = self.defaultData.totalDistance,
        playCount = self.defaultData.playCount,
        settings = {
            sound = self.defaultData.settings.sound,
            music = self.defaultData.settings.music,
            effects = self.defaultData.settings.effects,
            slowMotion = self.defaultData.settings.slowMotion,
            pauseOnDrag = self.defaultData.settings.pauseOnDrag
        },
        unlocked = {
            doubleJump = self.defaultData.unlocked.doubleJump,
            tripleJump = self.defaultData.unlocked.tripleJump,
            superDash = self.defaultData.unlocked.superDash,
            shield = self.defaultData.unlocked.shield
        }
    }
end

function SaveManager:resetSave()
    love.filesystem.remove(self.saveFile)
    return self:getDefaultData()
end

return SaveManager