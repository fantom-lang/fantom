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

  override Void setup()
  {
    podName     = "testNative"
    version     = globalVersion
    description = "Sys natives test suite"
    depends     = ["sys 1.0"]
    srcDirs     = [`fan/`]
    javaDirs    = [`java/`]
    dotnetDirs  = [`dotnet/`]
    includeSrc  = false
    includeFandoc = false
    podFacets   =
    [
      "nodoc": true,
    ]
  }

}