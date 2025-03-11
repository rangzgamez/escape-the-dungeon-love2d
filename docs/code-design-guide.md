# Vertical Jumper - Code Style and Design Guide

This document outlines the coding standards and design principles for maintaining and extending the Vertical Jumper codebase.

## Lua Code Style

### Formatting
- Use 4 spaces for indentation (not tabs)
- Keep line length to a maximum of 100 characters
- Use one statement per line
- Add a space after commas in tables, function calls, and parameter lists
- Add spaces around operators (=, +, -, etc.)

### Naming Conventions
- **Local Variables**: `lowerCamelCase` (e.g., `playerPosition`, `enemyCount`)
- **Constants**: `ALL_CAPS_WITH_UNDERSCORES` (e.g., `MAX_SPEED`, `DEFAULT_HEALTH`)
- **Functions**: `lowerCamelCase` (e.g., `updatePosition()`, `calculateDamage()`)
- **Classes/Tables**: `PascalCase` (e.g., `Player`, `EnemyManager`)
- **Filenames**: `lowerCamelCase.lua` or single-word `lowercase.lua`
- **Private Members**: Prefix with underscore (e.g., `_privateVariable`)

### Comments
- Use `--` for single-line comments
- Use block comments for function headers and important code blocks:
```lua
--[[
    Calculates the trajectory for a player's dash
    @param startX The starting X position
    @param startY The starting Y position
    @param angle The angle of the dash in radians
    @param power The power of the dash (0-1)
    @return Table of trajectory points
]]
```
- Comment complex sections and non-obvious behavior
- Keep comments up-to-date when changing code

## Design Patterns & Principles

### Object-Oriented Approach
The codebase uses Lua's metatables for object-oriented programming:

```lua
-- Class definition pattern
local ClassName = {}
ClassName.__index = ClassName

function ClassName:new(param1, param2)
    local self = setmetatable({}, ClassName)
    self.param1 = param1
    self.param2 = param2
    return self
end

function ClassName:methodName()
    -- Method implementation
end

return ClassName
```

### Inheritance
For classes that inherit from others:

```lua
local ParentClass = require("parentClass")
local ChildClass = setmetatable({}, {__index = ParentClass})
ChildClass.__index = ChildClass

function ChildClass:new(param1, param2, childParam)
    local self = ParentClass.new(self, param1, param2)
    self.childParam = childParam
    return self
end

-- Override parent method
function ChildClass:parentMethod()
    -- New implementation
end

return ChildClass
```

### State Pattern
Follow the established state machine pattern for game entity states:

```lua
local NewState = setmetatable({}, BaseState)
NewState.__index = NewState

function NewState:new(entity)
    local self = BaseState.new(self, entity)
    -- State-specific initialization
    return self
end

-- Implement required state methods:
function NewState:enter(prevState) end
function NewState:exit() end
function NewState:update(dt) end
function NewState:draw() end
-- Add other necessary methods

function NewState:getName()
    return "NewState"
end

return NewState
```

### Event System Usage
Use the event system for loose coupling between components:

```lua
-- Publishing events
Events.fire("eventName", {
    data1 = value1,
    data2 = value2
})

-- Subscribing to events
Events.on("eventName", function(data)
    -- Handle event
end)
```

## Best Practices

### Performance
- Avoid creating objects in update loops
- Use object pooling for frequently created/destroyed objects
- Minimize table lookups in critical paths
- Cache results that are used multiple times

### Memory Management
- Clear references to unused objects to help garbage collection
- Use local variables over global ones
- Avoid closures in hot code paths
- Be careful with recursive functions

### Love2D Specific
- Use `love.graphics.push()` and `love.graphics.pop()` when making transformations
- Batch similar draw operations when possible
- Use `love.graphics.setCanvas()` for rendering to textures
- Reset colors after drawing with `love.graphics.setColor(1, 1, 1)`
- Use `love.math.random` instead of Lua's `math.random` for better randomness

### Error Handling
- Use `pcall` for operations that might fail
- Check return values from file operations
- Provide meaningful error messages
- Catch errors at appropriate levels

### Modularity
- Each file should have a single responsibility
- Keep interdependencies minimal and explicit
- Use require statements at the top of files
- Avoid circular dependencies

## Testing and Debugging

### Debug Features
```lua
-- Add debug flags
local DEBUG_MODE = false
local DEBUG_COLLISION = false
local DEBUG_PERFORMANCE = false

-- Add debug visualizations
if DEBUG_COLLISION then
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("line", entity.x, entity.y, entity.width, entity.height)
end

-- Performance monitoring
if DEBUG_PERFORMANCE then
    local currentFPS = love.timer.getFPS()
    love.graphics.print("FPS: " .. currentFPS, 10, 10)
end
```

### Troubleshooting
- Use `print` statements strategically
- Monitor memory usage with `collectgarbage("count")`
- Create debug renders for hitboxes and paths
- Implement debug keys to trigger specific game states

## Version Control Practices

### Commit Guidelines
- Use descriptive commit messages
- Group related changes in single commits
- Keep commits focused on single features or fixes
- Reference issue numbers when applicable

### Branching Strategy
- `main` branch should always be playable
- Use feature branches for new development
- Create release branches for stable versions
- Use hotfix branches for critical bug fixes

## Documentation Standards

### Code Documentation
Document each module with:
- Purpose and responsibilities
- Public API and usage examples
- Dependencies and requirements

Document functions with:
- Short description of purpose
- Parameter explanations
- Return value description
- Side effects, if any

### Inline Comments
- Explain "why" not "what" the code is doing
- Note assumptions and edge cases
- Mark temporary solutions with TODO comments
- Use consistent comment style

## File Structure Conventions

### File Headers
Each file should begin with:
```lua
-- filename.lua - Brief description of the file's purpose
-- Part of Vertical Jumper game
-- Created by: [Author]
-- Last updated: [Date]
```

### Required Structure
Every module should follow this pattern:
```lua
-- File header comment

-- Required modules
local Dependencies = require("dependencies")

-- Module definition
local ModuleName = {}
ModuleName.__index = ModuleName

-- Private variables and functions (optional)
local privateVariable = 123
local function privateFunction() end

-- Public constructor
function ModuleName:new(...)
    -- Implementation
end

-- Public methods
function ModuleName:publicMethod()
    -- Implementation
end

-- Return the module
return ModuleName
```