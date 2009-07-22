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
** Build: compiler
**
class Build : BuildPod
{

  override Void setup()
  {
    podName    = "compiler"
    dependsDir = libFanDir.uri
    outDir     = @buildDevHome.val + `lib/fan/`
  }

}