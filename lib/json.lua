-- lib/json.lua
-- Simple JSON encoding/decoding module

local json = {}

-- Encode a Lua value to a JSON string
function json.encode(value)
    local t = type(value)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        -- Escape special characters
        local escaped = value:gsub('\\', '\\\\')
                             :gsub('"', '\\"')
                             :gsub('\n', '\\n')
                             :gsub('\r', '\\r')
                             :gsub('\t', '\\t')
        return '"' .. escaped .. '"'
    elseif t == "table" then
        -- Check if the table is an array (consecutive numeric keys starting at 1)
        local isArray = true
        local maxIndex = 0
        
        for k, _ in pairs(value) do
            if type(k) == "number" and k > 0 and math.floor(k) == k then
                maxIndex = math.max(maxIndex, k)
            else
                isArray = false
                break
            end
        end
        
        if isArray and maxIndex > 0 then
            -- Encode as JSON array
            local items = {}
            for i = 1, maxIndex do
                items[i] = json.encode(value[i] or json.null)
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            -- Encode as JSON object
            local items = {}
            for k, v in pairs(value) do
                if type(k) == "string" or type(k) == "number" then
                    table.insert(items, json.encode(tostring(k)) .. ":" .. json.encode(v))
                end
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    else
        error("Cannot encode value of type " .. t .. " to JSON")
    end
end

-- Special value to represent JSON null
json.null = setmetatable({}, {
    __tostring = function() return "null" end
})

-- Decode a JSON string to a Lua value
function json.decode(str)
    -- Remove whitespace
    str = str:gsub("^%s*", ""):gsub("%s*$", "")
    
    local pos = 1
    
    -- Forward declarations for recursive functions
    local decodeValue, decodeString, decodeNumber, decodeObject, decodeArray
    
    -- Decode a JSON value
    function decodeValue()
        local c = str:sub(pos, pos)
        
        if c == "{" then
            return decodeObject()
        elseif c == "[" then
            return decodeArray()
        elseif c == '"' then
            return decodeString()
        elseif c:match("[%d%-]") then
            return decodeNumber()
        elseif str:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif str:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif str:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            error("Invalid JSON at position " .. pos .. ": " .. str:sub(pos, pos + 10))
        end
    end
    
    -- Decode a JSON string
    function decodeString()
        pos = pos + 1 -- Skip opening quote
        local startPos = pos
        local escaped = false
        local result = ""
        
        while pos <= #str do
            local c = str:sub(pos, pos)
            
            if escaped then
                if c == '"' or c == '\\' or c == '/' then
                    result = result .. c
                elseif c == 'n' then
                    result = result .. '\n'
                elseif c == 'r' then
                    result = result .. '\r'
                elseif c == 't' then
                    result = result .. '\t'
                else
                    error("Invalid escape sequence at position " .. pos)
                end
                escaped = false
            elseif c == '\\' then
                escaped = true
            elseif c == '"' then
                pos = pos + 1 -- Skip closing quote
                return result
            else
                result = result .. c
            end
            
            pos = pos + 1
        end
        
        error("Unterminated string starting at position " .. startPos)
    end
    
    -- Decode a JSON number
    function decodeNumber()
        local startPos = pos
        
        -- Skip to the end of the number
        while pos <= #str and str:sub(pos, pos):match("[%d%.eE%+%-]") do
            pos = pos + 1
        end
        
        local numStr = str:sub(startPos, pos - 1)
        return tonumber(numStr)
    end
    
    -- Decode a JSON object
    function decodeObject()
        pos = pos + 1 -- Skip opening brace
        local result = {}
        
        -- Skip whitespace
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
        
        -- Check for empty object
        if str:sub(pos, pos) == "}" then
            pos = pos + 1
            return result
        end
        
        while pos <= #str do
            -- Expect a string key
            if str:sub(pos, pos) ~= '"' then
                error("Expected string key at position " .. pos)
            end
            
            local key = decodeString()
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            -- Expect a colon
            if str:sub(pos, pos) ~= ":" then
                error("Expected ':' at position " .. pos)
            end
            pos = pos + 1
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            -- Decode the value
            local value = decodeValue()
            result[key] = value
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            -- Check for end of object or comma
            if str:sub(pos, pos) == "}" then
                pos = pos + 1
                return result
            elseif str:sub(pos, pos) == "," then
                pos = pos + 1
                
                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end
            else
                error("Expected ',' or '}' at position " .. pos)
            end
        end
        
        error("Unterminated object starting at position " .. startPos)
    end
    
    -- Decode a JSON array
    function decodeArray()
        pos = pos + 1 -- Skip opening bracket
        local result = {}
        
        -- Skip whitespace
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
        
        -- Check for empty array
        if str:sub(pos, pos) == "]" then
            pos = pos + 1
            return result
        end
        
        local index = 1
        
        while pos <= #str do
            -- Decode the value
            result[index] = decodeValue()
            index = index + 1
            
            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            
            -- Check for end of array or comma
            if str:sub(pos, pos) == "]" then
                pos = pos + 1
                return result
            elseif str:sub(pos, pos) == "," then
                pos = pos + 1
                
                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end
            else
                error("Expected ',' or ']' at position " .. pos)
            end
        end
        
        error("Unterminated array")
    end
    
    -- Start decoding
    local result = decodeValue()
    
    -- Skip trailing whitespace
    while pos <= #str and str:sub(pos, pos):match("%s") do
        pos = pos + 1
    end
    
    -- Check for trailing garbage
    if pos <= #str then
        error("Trailing garbage at position " .. pos)
    end
    
    return result
end

return json 