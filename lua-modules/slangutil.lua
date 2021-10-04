-- Define the module in the style for Lua 5.1+

local slangUtil =  {}

function slangUtil.valueToString(o)
    if type(o) == 'table' then
        return slangUtil.tableToString(o)
    else
        return tostring(o)
     end
end
    
function slangUtil.tableToString(o)
    local s = '{ '
    for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. tostring(v) .. ',\n'
    end
    return s .. '} '
end

function slangUtil.dump(o)
    print(slangUtil.valueToString(o))
end

function slangUtil.trimPrefix(s, p)
    local t = (s:sub(0, #p) == p) and s:sub(#p + 1) or s
    return t
end


-- 
-- Append (assuming 'array' table b onto a)
--
function slangUtil.appendTable(a, b)  
    for _,v in ipairs(b) do 
        table.insert(a, v)
    end
end

function slangUtil.shallowCopyTable(t)
  local u = { }
  for k, v in pairs(t) 
  do 
    u[k] = v 
  end
  return setmetatable(u, getmetatable(t))
end

--
-- Given two (array) tables returns the concatination 
--
function slangUtil.concatTables(a, b)
    a = slangUtil.shallowCopyTable(a)
    slangUtil.appendTable(a, b)
    return a
end

function slangUtil.findLibraries(basePath, inMatchName, matchFunc)
    local matchName = inMatchName
    if isTargetWindows() then
        matchName = inMatchName .. ".lib"
    else
        matchName = "lib" .. inMatchName .. ".a"
    end
 
    local matchPath = path.join(basePath, matchName)
 
    local libs = os.matchfiles(matchPath)
       
    local dstLibs = {}   
       
    for k, v in ipairs(libs) do
        -- Strip off path and extension
        local libBaseName = path.getbasename(v)
        local libName = libBaseName
        
        if not isTargetWindows() then
            -- If the name starts with "lib" strip it
            libName = trimPrefix(libName, "lib")
        end
    
        if matchFunc == nil or matchFunc(libName) then
            table.insert(dstLibs, libName)
        end
    end
        
    return dstLibs
end

function slangUtil.toBool(v)
    if type(v) == "boolean" then 
        return v
    end
    if  v == "True" or v == "true" then
        return true
    end
    if v == "False" or v == "false" then
        return false
    end
    -- Returns nil as an error
    return nil
end

function slangUtil.getBoolOption(name)
    local v = _OPTIONS[name]
    local b = slangUtil.toBool(v)
    if b == nil then
        return error("Option '" .. name .. "' is '" .. v .. "' - not a valid boolean value")
    end
    return b
end

return slangUtil