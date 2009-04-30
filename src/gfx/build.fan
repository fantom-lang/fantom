#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Apr 09  Brian Frank  Creation
//

using build

**
** Build: gfx
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "gfx"
    version     = globalVersion
    description = "Graphics API"
    depends     = ["sys 1.0"]
    srcDirs     = [`fan/`, `test/`]
    javaDirs    = [,]
    includeSrc  = true
  }

}