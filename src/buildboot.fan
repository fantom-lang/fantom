#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 07  Brian Frank  Creation
//

using build

**
** buildboot.fan
**
** This is the first sub-script of the two part buildall script.
** This build script is used to bootstrap the build by building the
** core files needed to build the rest of the pod library: the Java and .NET
** runtimes and the sys, compiler, and build pods themselves.  In order
** to solve the chicken and the egg problem we rely on the fan launcher's
** substitute runtime feature to use an alternate fan runtime (by convention
** located at /dev/rel) to run this build script.
**
class Build : BuildGroup
{

  new make()
  {
    childrenScripts =
    [
      `sys/build.fan`,
      `sys/java/build.fan`,
      `sys/dotnet/build.fan`,
      `sys/js/build.fan`,
      `compiler/build.fan`,
      `compilerJava/build.fan`,
      `build/build.fan`,
    ]
  }

}