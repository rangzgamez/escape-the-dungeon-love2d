# Vertical Jumper - Extension Guide

This guide explains how to extend the game with new features, demonstrating the flexible architecture of the codebase.

## Adding New Enemies

### Creating a New Enemy Type
1. Create a new Lua file (e.g., `slime.lua`) in the entities folder:

```lua
-- slime.lua - Slime enemy for Love2D Vertical Jumper

local Slime = {}
Slime.__index = Slime

function Slime:new(x, y)
    local self = setmetatable({}, Slime)
    
    -- Position and dimensions
    self.x = x
    self.y = y
    self.width = 32
    self.height = 20
    
    -- Movement properties
    self.speed = 40
    self.jumpStrength = 300
    self.velocity.x = 0
    self.velocity.y = 0
    
    -- Behavior
    self.state = "idle"  -- idle, jumping, stunned
    self.stunnedTime = 0
    self.jumpTimer = love.math.random(1, 3)
    
    return self
end

-- Implement required methods: update, draw, stun, getBounds

return Slime
```

2. Add to EnemyManager:

```lua
local Slime = require("slime")

-- In EnemyManager:new()
self.slimes = {}

-- In generateEnemy()
if love.math.random() < 0.3 then  -- 30% chance for slime
    local slime = Slime:new(enemyX, enemyY)
    table.insert(self.slimes, slime)
    table.insert(self.enemies, slime)
end
```

## Adding Power-Ups

### Creating a Power-Up System
1. Create a `powerUp.lua` file:

```lua
-- powerUp.lua - Power-up items for Love2D Vertical Jumper

local PowerUp = {}
PowerUp.__index = PowerUp

function PowerUp:new(x, y, type)
    local self = setmetatable({}, PowerUp)
    
    self.x = x
    self.y = y
    self.width = 30
    self.height = 30
    self.type = type  -- "health", "dash", "jump"
    self.active = true
    self.animationTimer = 0
    
    return self
end

function PowerUp:update(dt)
    self.animationTimer = (self.animationTimer + dt) % 2
end

function PowerUp:draw()
    -- Different colors for different power-ups
    if self.type == "health" then
        love.graphics.setColor(1, 0.2, 0.2)
    elseif self.type == "dash" then
        love.graphics.setColor(0.2, 0.2, 1)
    elseif self.type == "jump" then
        love.graphics.setColor(0.2, 1, 0.2)
    end
    
    -- Floating animation
    local yOffset = math.sin(self.animationTimer * math.pi) * 5
    
    love.graphics.circle("fill", self.x + 15, self.y + 15 + yOffset, 15)
end

function PowerUp:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }
end

return PowerUp
```

2. Create a `powerUpManager.lua` file:

```lua
local PowerUp = require("powerUp")
local PowerUpManager = {}
PowerUpManager.__index = PowerUpManager

function PowerUpManager:new()
    local self = setmetatable({}, PowerUpManager)
    self.powerUps = {}
    self.spawnChance = 0.15  -- 15% chance per platform
    return self
end

-- Implement spawnPowerUp, update, draw, handleCollisions methods

return PowerUpManager
```

3. Update `main.lua` to include and use PowerUpManager

## Adding New Platform Types

### Creating a Moving Platform
1. Create a new `movingPlatform.lua` file:

```lua
local Platform = require("platform")
local MovingPlatform = setmetatable({}, {__index = Platform})
MovingPlatform.__index = MovingPlatform

function MovingPlatform:new(x, y, width, height, speed, distance)
    local self = Platform.new(self, x, y, width, height)
    
    self.startX = x
    self.speed = speed or 50
    self.distance = distance or 100
    self.direction = 1
    
    return self
end

function MovingPlatform:update(dt)
    -- Move platform back and forth
    self.x = self.x + self.speed * self.direction * dt
    
    -- Change direction when reaching limits
    if self.x > self.startX + self.distance then
        self.x = self.startX + self.distance
        self.direction = -1
    elseif self.x < self.startX then
        self.x = self.startX
        self.direction = 1
    end
end

function MovingPlatform:draw()
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return MovingPlatform
```

2. Update World to generate moving platforms occasionally

## Adding Visual Polish

### Screen Transitions
1. Create a `transitionManager.lua` file:

```lua
local TransitionManager = {}
TransitionManager.__index = TransitionManager

function TransitionManager:new()
    local self = setmetatable({}, TransitionManager)
    self.active = false
    self.type = nil       -- "fade", "slide", etc.
    self.progress = 0     -- 0 to 1
    self.duration = 1     -- seconds
    self.callback = nil   -- function to call when complete
    return self
end

-- Implement startTransition, update, draw methods

return TransitionManager
```

2. Add transitions between game states (menu, gameplay, game over)

### Parallax Background
1. Create a `background.lua` file:

```lua
local Background = {}
Background.__index = Background

function Background:new()
    local self = setmetatable({}, Background)
    self.layers = {
        {image = nil, speed = 0.1, y = 0},    -- Far clouds
        {image = nil, speed = 0.3, y = 0},    -- Medium clouds
        {image = nil, speed = 0.5, y = 0}     -- Close clouds
    }
    return self
end

-- Implement load, update, draw methods

return Background
```

2. Use this background system in main.lua

## Adding Game Modes and Progression

### Level System
1. Create a `levelManager.lua` file:

```lua
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
```

2. Use this in main.lua to adjust difficulty and visuals based on progress

## Adding Sound and Music

### Sound Manager
1. Create a `soundManager.lua` file:

```lua
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
```

2. Connect to event system
```lua
Events.on("playerDashStarted", function(data)
    soundManager:playSound("dash")
end)
```

## Implementing Saving and Loading

### Save System
1. Create a `saveManager.lua` file:

```lua
local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:new()
    local self = setmetatable({}, SaveManager)
    self.saveFile = "verticalJumper.save"
    return self
end

function SaveManager:saveGame(data)
    local success, message = love.filesystem.write(self.saveFile, love.data.encode("string", "json", data))
    return success, message
end

function SaveManager:loadGame()
    if not love.filesystem.getInfo(self.saveFile) then
        return nil
    end
    
    local content = love.filesystem.read(self.saveFile)
    if content then
        return love.data.decode("string", "json", content)
    end
    return nil
end

-- Implement deleteGame, saveExists methods

return SaveManager
```

2. Use to save high scores, unlocked features, and settings