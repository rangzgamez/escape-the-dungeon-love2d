-- lib/ecs/componentTemplate.lua
-- Component Template system for the Entity Component System

local ComponentTemplate = {}

-- Store all registered templates
local templates = {}

-- Register a new component template
function ComponentTemplate.register(name, components)
    if templates[name] then
        error("Component template '" .. name .. "' already exists")
    end
    
    -- Create a deep copy of the components to avoid reference issues
    local templateComponents = {}
    for componentType, data in pairs(components) do
        templateComponents[componentType] = {}
        for k, v in pairs(data) do
            templateComponents[componentType][k] = v
        end
    end
    
    templates[name] = {
        name = name,
        components = templateComponents
    }
    
    return templates[name]
end

-- Get a registered template by name
function ComponentTemplate.get(name)
    return templates[name]
end

-- Check if a template exists
function ComponentTemplate.exists(name)
    return templates[name] ~= nil
end

-- Apply a template to an entity
function ComponentTemplate.applyToEntity(entity, templateName, overrides)
    local template = templates[templateName]
    if not template then
        error("Component template '" .. templateName .. "' does not exist")
    end
    
    -- Apply each component from the template
    for componentType, data in pairs(template.components) do
        -- Create a deep copy of the component data
        local componentData = {}
        for k, v in pairs(data) do
            componentData[k] = v
        end
        
        -- Apply overrides for this component type if provided
        if overrides and overrides[componentType] then
            for k, v in pairs(overrides[componentType]) do
                componentData[k] = v
            end
        end
        
        -- Add the component to the entity
        entity:addComponent(componentType, componentData)
    end
    
    -- Tag the entity with the template name for identification
    entity:addTag("template:" .. templateName)
    
    return entity
end

-- Create a new entity from a template
function ComponentTemplate.createEntity(world, templateName, overrides)
    local entity = world:createEntity()
    return ComponentTemplate.applyToEntity(entity, templateName, overrides)
end

-- Get all registered template names
function ComponentTemplate.getTemplateNames()
    local names = {}
    for name, _ in pairs(templates) do
        table.insert(names, name)
    end
    return names
end

-- Get all components for a template
function ComponentTemplate.getComponents(templateName)
    local template = templates[templateName]
    if not template then
        error("Component template '" .. templateName .. "' does not exist")
    end
    
    -- Return a deep copy of the components
    local components = {}
    for componentType, data in pairs(template.components) do
        components[componentType] = {}
        for k, v in pairs(data) do
            components[componentType][k] = v
        end
    end
    
    return components
end

-- Remove a template
function ComponentTemplate.remove(name)
    if templates[name] then
        templates[name] = nil
        return true
    end
    return false
end

-- Clear all templates
function ComponentTemplate.clear()
    templates = {}
end

-- Extend an existing template with additional components
function ComponentTemplate.extend(baseName, newName, additionalComponents, overrides)
    if not templates[baseName] then
        error("Base template '" .. baseName .. "' does not exist")
    end
    
    if templates[newName] then
        error("Template '" .. newName .. "' already exists")
    end
    
    -- Start with a copy of the base template's components
    local components = ComponentTemplate.getComponents(baseName)
    
    -- Apply overrides to existing components
    if overrides then
        for componentType, data in pairs(overrides) do
            if components[componentType] then
                for k, v in pairs(data) do
                    components[componentType][k] = v
                end
            end
        end
    end
    
    -- Add additional components
    if additionalComponents then
        for componentType, data in pairs(additionalComponents) do
            -- Only add if not already present or explicitly overriding
            if not components[componentType] or (overrides and overrides[componentType]) then
                components[componentType] = {}
                for k, v in pairs(data) do
                    components[componentType][k] = v
                end
            end
        end
    end
    
    -- Register the new template
    return ComponentTemplate.register(newName, components)
end

return ComponentTemplate 