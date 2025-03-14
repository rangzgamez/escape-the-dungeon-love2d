#!/usr/bin/env lua
-- migrate_entity.lua
-- A script to help with migrating traditional entities to ECS entities

local function printUsage()
    print("Usage: lua migrate_entity.lua <entity_name>")
    print("Example: lua migrate_entity.lua player")
    print("This will create a new file at entities/playerECS.lua based on entities/player.lua")
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

local function migrateEntity(entityName)
    local sourcePath = "entities/" .. entityName .. ".lua"
    local targetPath = "entities/" .. entityName .. "ECS.lua"
    
    -- Check if source file exists
    local sourceContent = readFile(sourcePath)
    if not sourceContent then
        print("Error: Source file not found: " .. sourcePath)
        return false
    end
    
    -- Check if target file already exists
    if readFile(targetPath) then
        print("Warning: Target file already exists: " .. targetPath)
        print("Do you want to overwrite it? (y/n)")
        local answer = io.read()
        if answer ~= "y" and answer ~= "Y" then
            print("Migration aborted.")
            return false
        end
    end
    
    -- Create template for ECS entity
    local entityNameCapitalized = entityName:sub(1, 1):upper() .. entityName:sub(2)
    local entityNameECS = entityNameCapitalized .. "ECS"
    
    local template = [[
-- ]] .. entityNameECS .. [[.lua
-- ECS version of ]] .. entityName .. [[

local ECSEntity = require("entities/ecsEntity")
local ]] .. entityNameECS .. [[ = ECSEntity:extend()

function ]] .. entityNameECS .. [[:new(x, y, ...)
    ]] .. entityNameECS .. [[.super.new(self, x, y)
    
    -- Set entity type
    self.type = "]] .. entityName .. [["
    
    -- TODO: Add components specific to this entity
    self:addComponent("type", {
        value = "]] .. entityName .. [["
    })
    
    -- TODO: Add renderer component
    self:addComponent("renderer", {
        type = "rectangle", -- or "sprite", "circle", etc.
        layer = 5,
        width = 32,
        height = 32,
        color = {1, 1, 1, 1},
        mode = "fill"
    })
    
    -- TODO: Add collision component if needed
    self:addComponent("collision", {
        layer = 1,
        width = 32,
        height = 32,
        solid = true
    })
    
    -- TODO: Add other components as needed
end

function ]] .. entityNameECS .. [[:update(dt)
    -- Call parent update method
    ]] .. entityNameECS .. [[.super.update(self, dt)
    
    -- TODO: Add entity-specific update logic
end

function ]] .. entityNameECS .. [[:draw()
    -- Entity will be drawn by the renderer system
    -- Add any custom drawing logic here
end

function ]] .. entityNameECS .. [[:onCollision(other, response)
    -- TODO: Add collision response logic
end

return ]] .. entityNameECS
    
    -- Write the template to the target file
    if writeFile(targetPath, template) then
        print("Migration template created successfully: " .. targetPath)
        print("Please edit the file to implement the entity-specific logic.")
        return true
    else
        print("Error: Failed to write target file: " .. targetPath)
        return false
    end
end

-- Main script
local entityName = arg[1]
if not entityName then
    printUsage()
    os.exit(1)
end

migrateEntity(entityName) 