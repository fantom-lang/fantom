#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

using build

**
** Build: web
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "web"
    version     = globalVersion
    description = "Standard weblet APIs for processing HTTP requests"
    depends     = ["sys 1.0", "inet 1.0"]
    srcDirs     = [`fan/`, `test/`]
  }

}
