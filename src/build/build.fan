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
    if (devHomeDir == Env.cur.homeDir)
      throw fatal("Must update etc/build/config.props devHome for bootstrap")

    podName    = "build"
    dependsDir = libFanDir.uri
    outDir     = devHomeDir.plus(`lib/fan/`).uri
  }

}