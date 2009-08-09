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
    if (@buildDevHome.val == null)
      throw fatal("Must update etc/build/pod.fansym buildDevHome for bootstrap")

    podName    = "build"
    dependsDir = libFanDir.uri
    outDir     = @buildDevHome.val + `lib/fan/`
  }

}