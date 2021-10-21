# premake

Slang and many of it's surrounding libraries use [premake](https://premake.github.io/). 

This directory holds binaries for premake. For windows, macos and linux it is possible to use the premake binaries that 
are downloadable from the [premake download page](https://premake.github.io/download/).

CentOS 7
========

Unfortunately CentOS is unable to use the linux binaries. The problem there being is the the http module is unable to 
find certificates. When doing 

```
premake5 gmake --deps=true
```

If this is a problem you'll get an eror like 

```
Error: ...vidia/external/slang-binaries/lua-modules/slang-pack.lua:191: Unable to fully download 'https://github.com/shader-slang/slang-llvm/releases/download/v13.x-19/slang-llvm-v13.x-19-linux-x86_64-release.zip' Problem with the SSL CA cert (path? access rights?)
Error reading ca cert file /etc/ssl/cert.pem - mbedTLS: (-0x3E00) PK - Read/write of file failed
```

To fix we need to build premake5 on CentOS 7 and change the location of the certificates. We need to edit a couple of files first

In `build/gmake2.unix` directory, first we want to add `-std=c99` in the file `mbedtls-lib.make`

```
ALL_CPPFLAGS += $(CPPFLAGS) -MMD -MP $(DEFINES) $(INCLUDES) -std=c99
```

Without this change building mbedtls fails. Now we want to make the certificate change in file `curl-lib.make`. Change the line from 

```
-DCURL_CA_BUNDLE=\"/etc/ssl/cert.pem\"
```

To

```
-DCURL_CA_BUNDLE=\"/etc/ssl/certs/ca-bundle.crt\"
```

It might be a good idea to check that `/etc/ssl/certs/ca-bundle.crt` exists on your centos system.

Now we can build [build premake](https://github.com/premake/premake-core/blob/master/BUILD.txt).

```
make config=release
```

You should now have binaries in the path from the root of `bin/release'. 