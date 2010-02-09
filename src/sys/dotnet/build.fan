#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 06  Andy Frank  Creation
//

using build

**
** Build: sys.dll
**
** Note: this script builds the .NET runtime for Fantom's sys pod.
**
class Build : BuildCs
{

  new make()
  {
    output = devHomeDir.uri + `lib/dotnet/sys.dll`
    targetType = "library"

    srcDirs = [`fan/sys/`,
               `fanx/emit/`,
               `fanx/fcode/`,
               `fanx/serial/`,
               `fanx/test/`,
               `fanx/tools/`,
               `fanx/util/`,
               `perwapi/`]

    libs = [devHomeDir.uri + `lib/dotnet/ICSharpCode.SharpZipLib.dll`,
            devHomeDir.uri + `lib/dotnet/QUT.SymbolWriter.dll`]
  }

}