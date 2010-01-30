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
** Build: sys
**
** Note: this script just builds the Fan sys.pod; scripts in
** the java/ and dotnet/ subdirectories are used to build
** sys.jar and sys.dll
**
class Build : BuildPod
{

  override Void setup()
  {
    if (devHomeDir == Env.cur.homeDir)
      throw fatal("Must update etc/build/config.props devHome for bootstrap")

    podName = "sys"
    outDir  = devHomeDir.plus(`lib/fan/`).uri
  }

}