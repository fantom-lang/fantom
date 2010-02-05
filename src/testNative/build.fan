#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Feb 08  Brian Frank  Split from sysTest
//

using build

**
** Build: testNative
**
class Build : BuildPod
{
  new make()
  {
    podName    = "testNative"
    summary    = "Sys natives test suite"
    depends    = ["sys 1.0"]
    srcDirs    = [`fan/`]
    javaDirs   = [`java/`]
    dotnetDirs = [`dotnet/`]
    docApi     = false
    index      = ["testSys.mult": "testNative"]  // for testSys::EnvTest
  }
}