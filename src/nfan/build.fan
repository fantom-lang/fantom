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
** Build: nfan
**
class Build : BuildCs
{

  override Void setup()
  {
    output = libNetDir + `sys.dll`
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

    libs = [libNetDir + `ICSharpCode.SharpZipLib.dll`,
            libNetDir + `QUT.SymbolWriter.dll`]
  }

}