#!/bin/bash
# migrate_entity.sh
# A script to help with migrating traditional entities to ECS entities

# Function to print usage
print_usage() {
    echo "Usage: ./migrate_entity.sh <entity_name>"
    echo "Example: ./migrate_entity.sh player"
    echo "This will create a new file at entities/playerECS.lua based on entities/player.lua"
}

# Check if entity name is provided
if [ -z "$1" ]; then
    print_usage
    exit 1
fi

ENTITY_NAME=$1
SOURCE_PATH="entities/${ENTITY_NAME}.lua"
TARGET_PATH="entities/${ENTITY_NAME}ECS.lua"

# Check if source file exists
if [ ! -f "$SOURCE_PATH" ]; then
    echo "Error: Source file not found: $SOURCE_PATH"
    exit 1
fi

# Check if target file already exists
if [ -f "$TARGET_PATH" ]; then
    echo "Warning: Target file already exists: $TARGET_PATH"
    read -p "Do you want to overwrite it? (y/n) " ANSWER
    if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
        echo "Migration aborted."
        exit 1
    fi
fi

# Capitalize first letter of entity name
ENTITY_NAME_CAPITALIZED="$(tr '[:lower:]' '[:upper:]' <<< ${ENTITY_NAME:0:1})${ENTITY_NAME:1}"
ENTITY_NAME_ECS="${ENTITY_NAME_CAPITALIZED}ECS"

# Create template for ECS entity
cat > "$TARGET_PATH" << EOF
-- ${ENTITY_NAME_ECS}.lua
-- ECS version of ${ENTITY_NAME}

local ECSEntity = require("entities/ecsEntity")
local ${ENTITY_NAME_ECS} = ECSEntity:extend()

function ${ENTITY_NAME_ECS}:new(x, y, ...)
    ${ENTITY_NAME_ECS}.super.new(self, x, y)
    
    -- Set entity type
    self.type = "${ENTITY_NAME}"
    
    -- TODO: Add components specific to this entity
    self:addComponent("type", {
        value = "${ENTITY_NAME}"
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

function ${ENTITY_NAME_ECS}:update(dt)
    -- Call parent update method
    ${ENTITY_NAME_ECS}.super.update(self, dt)
    
    -- TODO: Add entity-specific update logic
end

function ${ENTITY_NAME_ECS}:draw()
    -- Entity will be drawn by the renderer system
    -- Add any custom drawing logic here
end

function ${ENTITY_NAME_ECS}:onCollision(other, response)
    -- TODO: Add collision response logic
end

return ${ENTITY_NAME_ECS}
EOF

echo "Migration template created successfully: $TARGET_PATH"
echo "Please edit the file to implement the entity-specific logic." 