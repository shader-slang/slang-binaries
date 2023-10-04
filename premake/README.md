# premake

Slang and many of its surrounding libraries use [premake](https://premake.github.io/). 

For windows, macos and linux it is possible to use the premake binaries that 
are downloadable directly from the [premake download page](https://premake.github.io/download/).

This directory holds binaries for premake for use when the official binaries
are not portable enough.

Linux Portability Issues
========================

Where possible, just use the version of premake5 (beta2 or newer) provided by
your distribution.

The official binaries from premake rely on a hardcoded paths to both the
system's certificate bundle (whatever was available on the distributor's
machine) and the interpreter, both of which reduce their portability.

If your distribution doesn't package a new enough version of premake5, and you
can't build premake5 from source yourself, and the binary releases from
premake5 can't find their expected interpreter or ca bundle then you can use
one of the more portable premake5 binaries in this repository.

If you have libcurl installed you can use `curl-config --ca` to get the
location to a certificate bundle.

For example, if the certificate bundle is located in the file
`/etc/ssl/certs/ca-bundle.crt` premake5 can be invoked by first setting the
`CURL_CA_BUNDLE` as shown below

```bash
CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt premake5 gmake2 --deps=true 
```

Building a more portable premake
================================

[`flake.nix`](./flake.nix) contains an expression to build static,
ca-bundle-location-agnostic premake binaries for `i686-linux`, `x86_64-linux`
and `aarch64-linux`; run `nix build --system x86_64-linux` for example.

To perform these steps manually:

- Ensure you have gcc, libuuid and gnumake installed
- Download the [premake source](https://premake.github.io/download/) this
  package will have the projects in a state ready to build. 
- As described in [`env-ca-bundle.patch`](./env-ca-bundle.patch), replace the
  define of `CURL_CA_BUNDLE=ca` with `CURL_WANTS_CA_BUNDLE_ENV`
- Run `make -f Bootstrap.mak linux`

Use your favourite libmusl-static toolchain and `s/SharedLib/StaticLib` in
`binmodules/{examples,luasocket}/premake5.lua` the premake source tree to get
a static binary. 

You should now have binaries in the path from the root of `bin/release'. 

