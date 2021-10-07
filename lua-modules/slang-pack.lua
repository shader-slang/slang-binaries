
-- Define the module in the style for Lua 5.1+

-- 
-- http://lua-users.org/wiki/LuaStyleGuide
-- http://lua-users.org/wiki/ModulesTutorial
--

local slangUtil = require("slang-util")

local slangPack =  {}

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

--
-- Maybe update dependencies (if --deps=true)
-- 

function slangPack.maybeUpdateDependencies(platformName, jsonName)
    local updateDeps = slangUtil.getBoolOption("deps")
    
    if updateDeps then
        return slangPack.updateDependencies(platformName, jsonName)
    end
end

--
-- Update dependencies
-- 

function slangPack.updateDependencies(platformName, jsonName)   
    local noProgress = slangUtil.getBoolOption("no-progress")

    if jsonName == nil then
        jsonName = "deps/target-deps.json"
    end
    
    -- Load the json
    local result, err = readJSONFromFile(jsonName)
    if err then
        return error(err)
    end
    
    -- Okay we have the json. We now need to work through the dependencies
    local projectInfo = result["project"]
    if projectInfo == nil then
        return error("Expecting 'project' in json")
    end
    
    local projectName = projectInfo["name"]
    
    -- If no dependencies we are done
    local dependencies = projectInfo["dependencies"]
    if dependencies == nil then
        return
    end
    
    for i, dependency in ipairs(dependencies) 
    do
        local dependencyName = dependency["name"]
        if dependencyName == nil then
            return error("Dependency doesn't have a name")
        end
       
        local baseUrl = dependency["baseUrl"]
        local packages = dependency["packages"]
      
        local platformPackage = packages[platformName]
        if platformPackage == nil then
            return error("No package for dependency '" .. dependencyName .. "' for target '" .. platformName .. "'")
        end
       
        local url = platformPackage
        
        -- If it starts with file: we can just use the file
        -- If it starts with dir: (say) then we just use the directory 
        
        if string.startswith(url, "https://") or 
           string.startswith(url, "http://") or
           string.startswith(url, "file://") or 
           string.startswith(url, "dir://") then
        else
            if type(baseUrl) == "string" then
                url = baseUrl .. url
            end
        end
       
        -- We need to work out the filename.
        -- Arguably this is a bit of a hack - we are using path to get a URL name after all.
        -- but it works fine on platforms required.
        local packageFileName = path.getname(platformPackage)
        
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
        local dependencyPath = path.join("external", dependencyName)
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