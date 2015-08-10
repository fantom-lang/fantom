#! /usr/bin/env fan
//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jul 15  Matthew Giannini  Creation
//

using build

**
** Build: fansc.exe
**
class Build : BuildCs
{

  new make()
  {
    output = devHomeDir.uri + `bin/fansc.exe`
    targetType = "exe"

    srcDirs = [`FanSc/`]
  }
}
