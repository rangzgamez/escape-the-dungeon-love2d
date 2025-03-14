#!/usr/bin/env lua
-- migrate_entity.lua
-- A tool to help migrate entities from the old system to the ECS architecture

local function printUsage()
    print("Usage: lua migrate_entity.lua <entity_name>")
    print("Example: lua migrate_entity.lua Enemy")
    print("This will create a new file at entities/enemyECS.lua based on entities/enemy.lua")
end

local function readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    return content
end

local function writeFile(path, content)
    local file = io.open(path, "w")
    if not file then
        return false
    end
    
    file:write(content)
    file:close()
    
    return true
end

local function convertEntityToECS(entityName)
    -- Convert entity name to proper case
    local entityNameProper = entityName:sub(1, 1):upper() .. entityName:sub(2)
    local entityNameLower = entityName:lower()
    
    -- Define file paths
    local sourcePath = "entities/" .. entityNameLower .. ".lua"
    local targetPath = "entities/" .. entityNameLower .. "ECS.lua"
    
    -- Read source file
    local sourceContent = readFile(sourcePath)
    if not sourceContent then
        print("Error: Could not read source file: " .. sourcePath)
        return false
    end
    
    -- Create ECS template
    local ecsTemplate = [[
-- ]] .. entityNameLower .. [[ECS.lua - ECS version of ]] .. entityNameProper .. [[

local Events = require("lib/events")
local ECSEntity = require("entities/ecsEntity")

local ]] .. entityNameProper .. [[ECS = {}
]] .. entityNameProper .. [[ECS.__index = ]] .. entityNameProper .. [[ECS

function ]] .. entityNameProper .. [[ECS.new(x, y, ...)
    -- Create options for the ]] .. entityNameLower .. [[
    local options = {
        type = "]] .. entityNameLower .. [[",
        collisionLayer = "default", -- Update this based on the entity type
        collidesWithLayers = {"default"}, -- Update this based on the entity type
        isSolid = true, -- Update this based on the entity type
        color = {1, 1, 1, 1} -- Update this based on the entity type
    }
    
    -- Create the entity using ECSEntity constructor
    local ]] .. entityNameLower .. [[ = ECSEntity.new(x, y, 32, 32, options)
    
    -- Set up ]] .. entityNameProper .. [[ECS metatable
    setmetatable(]] .. entityNameLower .. [[, {__index = ]] .. entityNameProper .. [[ECS})
    
    -- Set entity type
    ]] .. entityNameLower .. [[.type = "]] .. entityNameLower .. [["
    
    -- Add components to ECS entity
    if ]] .. entityNameLower .. [[.ecsEntity then
        -- Add entity-specific components here
        ]] .. entityNameLower .. [[.ecsEntity:addComponent("]] .. entityNameLower .. [[", {
            -- Add properties based on the original entity
        })
    end
    
    return ]] .. entityNameLower .. [[
end

-- Handle collision with another entity
function ]] .. entityNameProper .. [[ECS:onCollision(other, collisionData)
    -- Call parent onCollision method
    ECSEntity.onCollision(self, other, collisionData)
    
    -- Handle entity-specific collision logic here
end

-- Update method
function ]] .. entityNameProper .. [[ECS:update(dt)
    -- Call parent update method
    ECSEntity.update(self, dt)
    
    -- Add entity-specific update logic here
end

-- Draw method (optional, if custom drawing is needed)
function ]] .. entityNameProper .. [[ECS:draw()
    -- Call parent draw method
    ECSEntity.draw(self)
    
    -- Add entity-specific drawing logic here
end

return ]] .. entityNameProper .. [[ECS
]]
    
    -- Write ECS file
    if not writeFile(targetPath, ecsTemplate) then
        print("Error: Could not write target file: " .. targetPath)
        return false
    end
    
    print("Successfully created " .. targetPath)
    print("Next steps:")
    print("1. Review the generated file and update it based on the original entity")
    print("2. Add the entity to the EntityFactoryECS")
    print("3. Test the entity in isolation")
    
    return true
end

-- Main function
local function main(...)
    local args = {...}
    
    if #args < 1 then
        printUsage()
        return
    end
    
    local entityName = args[1]
    convertEntityToECS(entityName)
end

-- Run the script
main(...) 