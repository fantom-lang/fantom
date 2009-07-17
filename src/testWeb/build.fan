#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using build

**
** Build: testWeb
**
class Build : BuildPod
{

  override Void setup()
  {
    podName       = "testWeb"
    version       = globalVersion
    depends       = ["sys 1.0", "inet 1.0", "web 1.0", "webapp 1.0", "dom 1.0"]
    srcDirs       = [`fan/`]
    includeSrc    = false
    includeFandoc = false
    hasJavascript = true
    description = "TODO-SYM"
  }

}