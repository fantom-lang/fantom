#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using build

**
** Build: fwt
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "fwt"
    version     = globalVersion
    description = "Fan Widget Toolkit"
    depends     = ["sys 1.0"]
    srcDirs     = [`fan/`, `test/`]
    javaDirs    = [`java/`]
    //netDirs   = [`net/`]
    resDirs     = [`locale/`]
  }

}
