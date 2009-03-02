#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using build

**
** Build: build
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "build"
    version     = globalVersion
    description = "Fan build utility"
    depends     = ["sys 1.0", "compiler 1.0"]
    dependsDir  = libFanDir.uri
    srcDirs     = [`fan/`, `fan/tasks/`]
    includeSrc  = true
  }

}