#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 08  Brian Frank  Creation
//

using build

**
** Build: fluxText
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "fluxText"
    version     = globalVersion
    description = "Flux: Text Editor"
    depends     = ["sys 1.0", "fwt 1.0", "flux 1.0"]
    srcDirs     = [`fan/`, `test/`]
  }

}
