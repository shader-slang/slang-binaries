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
* --no-progress=[true,false] - If true, will *not* display a progress bar when downloading (useful for CI)
* --target-detail=[cygwin,mingw] - Set to the name of target detail (for example if building for cygwin on windows)
* --ignore-deps= - A comma delimited list of dependencies to ignore. Ignoring will mean it doesn't download packages.

That `--target-detail` and `--arch` are actually required by the `slang-util.lua` module that `slang-pack.lua` depends on. 

If the `--deps=true` command line option is set it allows the package manager to download dependencies. 

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
                "optional" : true,
                "packages" : 
                {
                    "windows-x86_64" : "llvm-tot-14-win64-Release.zip",
                    "linux-x86_64" : "llvm-tot-14-linux-x86_64-Release.zip",
                    "windows-aarch64" : { "type" : "unavailable" }
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

Note as it stands json parsing 

* Does not allow trailing ,
* Does not allow comments /**/ or //
* Only reports a parsing error as a byte offset

This format may change in the future to provide more more nuanced information about packages. Putting the submodules into the json, allows for overridding a dependency to a specific path. 

The dependencies section holds an *array* of packages. Each package must contain a `name` which is how the dependency is identified. A dependency can contain a `type` valid dependency types are

* `submodule` - The dependency is a git submodule which is held at the path "externals/dependency-name", assumed up to date via `git submodule update`
* `directory` - The dependency (for the desired target) is in the specified directory (this is similar to `submodule`, but doesn't assume it's origin is via `git`) 
* `packages` - Use the specified packages (the default if a type isn't specified)

If a dependency type is *not* specified, it is assumed that there is a `packages` entry which describes a package per target describing the dependency.

The packages section of a dependency is a map from a `target` (platform and arch combination) to where that package is located. If a string is used it will assumed to be an url, if it's a table then a `type` can be specified 

* `url` - Package is stored at specified url/s held in packages.
* `path` - Path to the unziped package on the file system (this path will be returned from `:getPath()`)
* `submodule` - Means the module is a git submodule that will be held in the `externals/name` directory
* `unavailable` - The package isn't available for this target

In use

```
-- Get the slang-pack module
slangPack = require("slang-pack")
-- Get the slangUtil module - it is useful for determining the target
slangUtil = require("slang-util")

-- Load the dependencies from the json
deps = slangPack.loadDependencies("deps/target-deps.json")

-- Get the target info
targetInfo = slangUtil.getTargetInfo()

-- Update thet dependencies (may download packages etc)
-- If there is a problem will panic with an error
deps:update(targetInfo.name)

-- Get the path where a dependency is located.
local llvmPath = deps:getPath("llvm")
```

The `llvmPath` value can then be used to specify the path to the dependency in the build script. A project can just rely on a dependency being located in 'external' and this will work as expected, but by using the 'getPath' mechanism it's possible to change the dependency path on the command line. 

For `optional` dependencies if they are not available :getPath() will return nil. If will report an error if a dependency is requested that isn't defined. 

Note that an inappropriate dependency does *not* delete the dependency directory. So it is possible to have a directory containing a different targets dependency.

Every dependency will add a command line option with the same name and '-path' suffix. So for example if we have a dependency `llvm` we can just set the path that we want to use via `--llvm-path` option

```
premake5 vs2019 --arch=x64 --deps=true --llvm-path=path-to-llvm
```

# slang-util module

A collection of useful functionality for making premake scripts. 

In particular it provides functionality to identify and name a target via 

```lua
slangUtil = require("slang-util")
slangUtil.getTargetInfo()
```
