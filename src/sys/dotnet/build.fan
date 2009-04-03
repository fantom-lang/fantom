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
** Note: this script builds the .NET runtime for Fan's sys pod.
**
class Build : BuildCs
{

  override Void setup()
  {
    output = libDotnetDir + `sys.dll`
    targetType = "library"

    dirs = [scriptDir + `fan/sys/`,
            scriptDir + `fanx/emit/`,
            scriptDir + `fanx/fcode/`,
            scriptDir + `fanx/serial/`,
            scriptDir + `fanx/test/`,
            scriptDir + `fanx/tools/`,
            scriptDir + `fanx/typedb/`,
            scriptDir + `fanx/util/`,
            scriptDir + `perwapi/`]

    libs = [libDotnetDir + `ICSharpCode.SharpZipLib.dll`,
            libDotnetDir + `QUT.SymbolWriter.dll`]
  }

}