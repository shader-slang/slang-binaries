# Lua Modules 

These are LUA modules that are used for the Slang project, typically within `premake5.lua` [premake build](https://premake.github.io/) scripts.

## slangpack.lua module

This module provides a very simple 'package manager'. 

Note this is a very preliminary version - it should have better integration with options handling for example. It would also be better if there was a shared way to describe compilation targets across scripts. 

To use first load the module in your script.

```
--
-- Add the package path for slang-pack
-- The question mark is there the name of the module is inserted.
---
package.path = package.path .. ";external/slang-binaries/lua-modules/?.lua"

-- Load the slack package manager module
slangpack = require("slangpack")
```

The slang pack system needs some extra command line options. Enable these options via

```
slangpack.addOptions()
```

If the `--deps=true` command line option is set initiate downloading/update the dependencies

```
if deps then
    slangpack.updateDeps(platformName, nil, noProgress)
end
```

A future version should integrate options handling, and dependency processing. 

As it currently stands the dependency file is held at the location `deps/target-deps.json`. 

A deps file looks something like

```
{
    "project": {
        "name" : "llvm-slang",
        "dependencies" : [
            {
                "name" : "llvm",
                "baseUrl" : "https://github.com/shader-slang/llvm-project/releases/download/slang-tot-14/",
                "packages" : 
                {
                    "windows-x86_64" : "llvm-tot-14-win64-Release.zip",
                    "linux-x86_64" : "llvm-tot-14-linux-x86_64-Release.zip"
                }
            }
        ]
    }
}
```

This format is likely to change in the future to provide more more nuanced information about packages.

### Future additions

* Ability to specify local locations for packages
* Specifying submodules in the deps file (doing so will allow for overriding)
* Splitting out target parsing
* Splitting out commonly used lua functions into a modules

Note that the default overriding location mechanism used currently doesn't use links/softlinks it replaces paths in build files. That may not work for some scenarios.