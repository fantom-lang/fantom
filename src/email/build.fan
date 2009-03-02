#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Apr 08  Brian Frank  Creation
//

using build

**
** Build: email
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "email"
    version     = globalVersion
    description = "Email support"
    depends     = ["sys 1.0", "inet 1.0"]
    srcDirs     = [`fan/`, `test/`]
    includeSrc  = true
  }

}