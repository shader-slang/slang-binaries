
-- Define the module in the style for Lua 5.1+

-- 
-- http://lua-users.org/wiki/LuaStyleGuide
-- http://lua-users.org/wiki/ModulesTutorial
--

local slangUtil = require("slang-util")

-- Initialize the module table

local slangPack =  {}

--
-- Dependencies class
--

-- Lets create a class to hold the dependencies

local Dependencies = {}
Dependencies.__index = Dependencies

setmetatable(Dependencies, {
    __call = function (cls, ...) 
        return cls.new(...)
    end,
})

function Dependencies.new(jsonProj)
    local self = setmetatable({}, Dependencies)
    -- Map of a dependency name to it's path on filesystem
    self.paths = {}
    -- Set the root of the json
    self.jsonProj = jsonProj
    -- The 'project' info (close to what's read from JSON) file
    self.project = jsonProj.project
    
    return self
end

function Dependencies:getPath(name)
    local path = self.paths[name]
    if path == nil then
        return error("Unknown dependency '" .. name .. "'")
    end    
    return path
end

function Dependencies:setPath(name, path)
    self.paths[name] = path
end

local function displayProgress(total, current)  
    local ratio = current / total;  
    ratio = math.min(math.max(ratio, 0), 1);  
    --local percent = math.floor(ratio * 100);  
    
    local numBars = 32
    local downloadedBars = math.floor(ratio * numBars)
    
    local bar = string.rep("#", downloadedBars) .. string.rep(".", numBars - downloadedBars)
    
    local spinIndex = math.floor(ratio * 4096) % 4
    local spin = string.sub("|\\-/", spinIndex + 1, spinIndex + 1)
    
    io.write("\rDownload progress (" .. spin .. ") " .. bar )
end

local function readJSONFromFile(path)
    local fileContents = io.readfile(path)
    if fileContents == nil then
        return nil, "Unable to read file '" .. path .. "'"
    end
    
    return json.decode(fileContents)
end

function Dependencies:updateDependencyFromURL(dependencyName, url)

    local noProgress = slangUtil.getBoolOption("no-progress")
    local downloadDep = slangUtil.getBoolOption("deps")

    -- We need to work out the filename.
    -- Arguably this is a bit of a hack - we are using path to get a URL name after all.
    -- but it works fine on platforms required.
    local packageFileName = path.getname(url)
    
    -- We are going to store all of our packages in this path
    local downloadsPath = "downloads"
    -- Make sure the path exists
    if not os.isdir(downloadsPath) then
        os.mkdir(downloadsPath)
    end
    
    -- The path the package will be downloaded to
    local packagePath = path.join(downloadsPath, packageFileName)
    
    -- We create a 'part' filename, to identify a non fully downloaded path
    local packagePartPath = packagePath .. ".part"
    
    -- The final dependency location
    local dependencyPath = self:getPath(dependencyName)

    -- Get the name of the file that marks what's in the directory
    local packageInfoPath = path.join(dependencyPath, "package-info.json")
    
    -- Check if there is an expansion of the dependency
    if os.isdir(dependencyPath) then
    
        -- Check if the package info is suitable
        local result, err = readJSONFromFile(packageInfoPath)
    
        -- If it contains a matching package name, we are done 
        if err == nil and result["name"] == packageFileName then
            return
        end
    end
    
    -- If there is a part only it must be for a non completed download
    if os.isfile(packagePartPath) then
        -- So delete it
        os.remove(packagePartPath)
    end    
    
    -- 
    -- Check if we have the download - if we do, we can just unzip that
    --
    if not os.isfile(packagePath) then    
    
        -- Check if we can download -- we need --deps=true
        if not downloadDep then
            return error("Need --deps=true to download dependency '" .. dependencyName .. "' " .. url)
        end
           
        -- Okay download it then
        do
            print("Downloading '" .. url .. "'")
        
            local result_str, response_code
        
            if noProgress then
                result_str, response_code = http.download(url, packagePartPath, {})
            else
                result_str, response_code = http.download(url, packagePartPath, {progress = displayProgress})
                -- Move down a line as progress repeatedly writes to same line
                print("")
            end
             
            if result_str == "OK" then
            else
                -- Delete what we have
                return error("Unable to fully download '".. url .. "'")
            end

            -- Okay we can rename the .part to the package name as it completed ok
            -- It's not documented on the website, but by examining os there is 'rename'
            os.rename(packagePartPath, packagePath)
        end 
    end    
    
    -- Check we have the package
  
    if not os.isfile(packagePath) then
        return error("Can't locate package download '" .. packagePath .. "'")
    end
  
    -- If the dependency path exists, delete it so we can extract into a new copy
   
    if os.isdir(dependencyPath) then
        os.rmdir(dependencyPath)
    end
   
    print("Extracting '" .. packagePath .. "' to '" .. dependencyPath .. "' (please be patient) ...")
   
    -- We can now unzip the package
    zip.extract(packagePath, dependencyPath)

    print("Extracted.")

    -- Lets make the 'package info' it in the dependency path
    local packageInfo = { name = packageFileName }

    -- This JSON holds the name of the source file that was unziped here, so we can check for a match 
    io.writefile(path.join(dependencyPath, "package-info.json"), json.encode(packageInfo))
end

local function isAbsoluteUrl(url)
    return string.startswith(url, "https://") or 
               string.startswith(url, "http://") or
               string.startswith(url, "file://") 
end


function Dependencies:initDependency(dependency)
    local dependencyName = dependency["name"]
    if dependencyName == nil then
        return error("Dependency doesn't have a name")
    end

    -- Set the default dependency path
    self:setPath(dependencyName, "external/" .. dependencyName)

    -- Add an option
    newoption 
    { 
        trigger     = dependencyName .. "-path",
        description = "(Optional) Path for dependency " .. dependencyName,
        value       = "string",
    }

    -- If it's a submodule we are done
    if dependency.type == "submodule" then
        return
    end

    -- Check out the packages
    local packages = dependency["packages"]
    
    local validPackageTypes = 
    {
        url = true,
        path = true,
        submodule = true,
    }
    
    for platform, pack in pairs(packages)
    do
        if type(pack) == "string" then
            -- We assume it is a url
            local packPath = pack
            pack = {
                packageType = "url",
                path = packPath
            }
            
            packages[platform] = pack
        end 

        if type(pack) ~= "table" then
            return error("For dependency " .. dependencyName .. "/" .. platform .. " expecting table.")
        end
 
        -- Check the type
        if not validPackageTypes[pack.packageType] then
            return error("Invalid package type '" .. pack.packageType .. "' for dependency " .. dependencyName .. "/" .. platform .. ".")
        end
        
        -- Check it has a path
        if type(pack.path) ~= "string" then
            return error("No 'path' for '" .. dependencyName .. "/" .. platform .. "'")
        end    
    end    
end

function Dependencies:init()    
    -- We want to now go through and determine if this seems valid
     
    -- Okay we have the json. We now need to work through the dependencies
    local projectInfo = self.project
    if projectInfo == nil then
        return error("Expecting 'project' in json")
    end
    
    local dependencies = projectInfo.dependencies
    
    if dependencies ~= nil then
    
        -- Initialize each dependency
        for i, dependency in ipairs(dependencies) 
        do
            self:initDependency(dependency)
        end
    end    
end

--
-- Update dependencies
-- 

function Dependencies:update(platformName)

    -- Okay we have the json. We now need to work through the dependencies
    local projectInfo = self.project 
    local projectName = projectInfo.name
    
    -- If no dependencies we are done
    local dependencies = projectInfo.dependencies
    if dependencies == nil then
        return
    end
    
    for i, dependency in ipairs(dependencies) 
    do
        local dependencyName = dependency.name
            
        -- Check if the command line option has been set
        local cmdLineDependencyPath = _OPTIONS[dependencyName .. "-path"]
      
        if type(cmdLineDependencyPath) == "string" then
            if not os.isdir(cmdLineDependencyPath) then
                return error("Path '" .. cmdLineDependencyPath .. "' for '" .. dependencyName .. "' not found")
            end
        
            self:setPath(dependencyName, cmdLineDependencyPath)
        elseif dependency["type"] == "submodule" then
            -- We don't have to do something
            
            local dependencyPath = self:getPath(dependencyName)
                
            if not os.isdir(dependencyPath) then
                return error("Path '" .. cmdLineDependencyPath .. "' for '" .. dependencyName .. "' not found. Try `git submodule update --init`")
            end
            
        else
            -- Handle the different package types
            
            local baseUrl = dependency["baseUrl"]
            local packages = dependency["packages"]
          
            if type(baseUrl) ~= "string" then
                baseUrl = ""
            end
            
            local packageInfo = packages[platformName]
            if type(packageInfo) ~= "table" then
                return error("No package for dependency '" .. dependencyName .. "' for target '" .. platformName .. "'")
            end
            
            local packageType = packageInfo.packageType
            local packagePath = packageInfo.path
            
            if packageType == "path" then
                -- Just set the path and we are done
                self.setPath(dependencyName, packagePath)
            elseif packageType == "url" then
                local url = packagePath
                
                -- If it starts with file: we can just use the file
                -- If it starts with dir: (say) then we just use the directory 
                if not isAbsoluteUrl(url) then
                    url = baseUrl .. url
                end
                
                -- Download and extract from url
                self:updateDependencyFromURL(dependencyName, url)
                
            else
                return error("Unknown packageType '" .. packageType .. " for '" .. dependencyName .. "/" .. platformName .. "'")
            end
        end
    end
end

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! slangPack functions !!!!!!!!!!!!!!!!!!!!!!!!!!

--
-- Load dependencies from specified file
--

function slangPack.loadDependencies(jsonName)
    if jsonName == nil then
        jsonName = "deps/target-deps.json"
    end
    
    -- Load the json
    local proj, err = readJSONFromFile(jsonName)
    if err then
        return error(err)
    end
    
    local deps = Dependencies.new(proj)
    
    -- Initialize it
    deps:init()
    
    return deps
end
    
-- Importing the module should make these automatically available
  
newoption { 
    trigger     = "deps",
    description = "(Optional) If true downloads binaries defined in the deps/target-deps.json",
    value       = "bool",
    default     = "false",
    allowed     = { { "true", "True"}, { "false", "False" } }
}

newoption { 
    trigger     = "no-progress",
    description = "(Optional) If true doesn't display progress bars when downloading",
    value       = "boolean",
    default     = "false",
    allowed     = { { "true", "True"}, { "false", "False" } }
}

return slangPack