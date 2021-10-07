# Lua Modules 

These are LUA modules that are used for the Slang project, typically within `premake5.lua` [premake build](https://premake.github.io/) scripts.

## slang-pack.lua module

This module provides a very simple 'package manager'. 

To use first load the module in your script.

```lua
--
-- Add the package path for slang-pack
-- The question mark is there the name of the module is inserted.
---
package.path = package.path .. ";external/slang-binaries/lua-modules/?.lua"

-- Load the slack package manager module
slangPack = require("slang-pack")
```

Just by loading the module it will add the following command line options

* --arch= - Select the architecture/platform to build for. Necessary as will download packages and put in 'external' for *just* that arch/platform
* --deps=[true,false] - If set will check if the current deps are correct and download and install 
* --no-progress=[true,falgs] - If true, will *not* display a progress bar when downloading
* --target-detail=[cygwin,mingw] - Set to the name of target detail (for example if building for cygwin on windows)

That `--target-detail` and `--arch` are actually required by the `slang-util.lua` module that `slang-pack.lua` depends on. 

If the `--deps=true` command line option is set initiate downloading/update the dependencies

As it currently stands the dependency file is held at the location `deps/target-deps.json`. Packages are download into the 'downloads' directory. This directory can be deleted if needs be and packages will be redownloaded on demand.

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
            },
            {
                "name" : "slang-binaries",
                "type" : "submodule"
            },
            {
                "name" : "slang",
                "type" : "submodule"
            }
        ]
    }
}
```

This format is likely to change in the future to provide more more nuanced information about packages.

Note that the default overriding location mechanism used currently doesn't use links/softlinks it replaces paths in build files. That may not work for some scenarios.

Putting the submodules into the json, allows for overridding a dependency to a specific path. Dependencies can be returned via 

```
local llvmPath = packProj.getDependencyPath("llvm")
```

To set a different path (than the usual external/llvm) use `-dep-path` option

```
premake5 vs2019 --arch=x64 --deps=true --llvm-dep-path=path-to-llvm
```

# slang-util module

Useful functionality used for premake. 

In particular it provides functionality to identify and name a target via the 

```lua
slangUtil = require("slang-util")
slangUtil.getTargetInfo()
```
