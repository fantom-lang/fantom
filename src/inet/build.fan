#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

using build

**
** Build: inet
**
class Build : BuildPod
{
  new make()
  {
    podName    = "inet"
    summary    = "IP networking"
    depends    = ["sys 1.0", "concurrent 1.0"]
    srcDirs    = [`fan/`, `test/`]
    javaDirs   = [`java/`]
    dotnetDirs = [`dotnet/`]
    docSrc     = true
  }
}


