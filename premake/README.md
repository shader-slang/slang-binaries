# premake

Slang and many of it's surrounding libraries use [premake](https://premake.github.io/). 

This directory holds binaries for premake. For windows, macos and linux it is possible to use the premake binaries that 
are downloadable directly from the [premake download page](https://premake.github.io/download/).

Linux Certificates Issue
========================

`slang-pack` uses the http module in premake to download packages. It is common for packages to be located at https based urls. For https to work premake needs
to verify certificates, by using a 'certificate bundle'. By default premake is built using `/etc/ssl/cert.pem` as the package bundle location. 

Unfortunately this doesn't appear to work some linux versions. For example CentOS 7, has it's certificates located at `/etc/ssl/certs/ca-bundle.crt`.

Normal `premake` is builds do not allow for specifying where certificates are located. To work around this problem we build a special version of 
premake which requires the certificate bundle to be specified in the `CURL_CA_BUNDLE` environment parameter. This binary is in the centos-7-x64 directory.

Note that the CURL_CA_BUNDLE *must* be specified for CentOS 7 binary else downloads from https based urls will cause an error.

```
Error: .../external/slang-binaries/lua-modules/slang-pack.lua:190: Unable to download 'https://github.com/shader-slang/slang-llvm/releases/download/v13.x-19/slang-llvm-v13.x-19-linux-x86_64-release.zip' 
SSL peer certificate or SSH remote key was not OK
Cert verify failed: BADCERT_NOT_TRUSTED
code:0.0
```

For example 

```
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
premake5 gmake --deps=true 
```

Building CentOS 7 premake
=========================

To fix we need to build premake5 on CentOS 7 and change the location of the certificates. We need to edit a couple of files first.
In `build/gmake2.unix` directory, first we want to add `-std=c99` in the file `mbedtls-lib.make`

```
ALL_CPPFLAGS += $(CPPFLAGS) -MMD -MP $(DEFINES) $(INCLUDES) -std=c99
```

Without this change building mbedtls fails. 

Now we want to make the certificate change in file `curl-lib.make`. Replace 

```
-DCURL_CA_BUNDLE=\"/etc/ssl/cert.pem\"
```

with

```
-DCURL_WANTS_CA_BUNDLE_ENV
```

Now we can build [build premake](https://github.com/premake/premake-core/blob/master/BUILD.txt).

```
make config=release
```

You should now have binaries in the path from the root of `bin/release'. 