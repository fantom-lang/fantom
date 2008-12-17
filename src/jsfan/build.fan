#! /usr/bin/env fansubstitute
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Dec 08  Andy Frank  Creation
//

using build

**
** Build: jsfan
**
class Build : BuildScript
{

  override Target defaultTarget()
  {
    return target("zip")
  }

  @target="zip Javascript into sys.zip"
  Void zip()
  {
    libJsDir := devHomeDir + `lib/javascript/`
    js  := scriptDir + `js/`
    zip := Zip.write(libJsDir.createFile("sys.zip").out)
    js.listFiles.each |File f|
    {
      out := zip.writeNext(f.name.toUri)
      f.in.pipe(out)
    }
    zip.close
  }

}