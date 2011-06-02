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
    meta       = ["org.name":     "Fantom",
                  "org.uri":      "http://fantom.org/",
                  "proj.name":    "Fantom Core",
                  "proj.uri":     "http://fantom.org/",
                  "license.name": "Academic Free License 3.0",
                  "vcs.name":     "Mercurial",
                  "vcs.uri":      "http://hg.fantom.org/fan-1.0/"]
    depends    = ["sys 1.0"]
    srcDirs    = [`fan/`]
    javaDirs   = [`java/`]
    dotnetDirs = [`dotnet/`]
    docApi     = false
    index      = ["testSys.mult": "testNative"]  // for testSys::EnvTest
  }
}