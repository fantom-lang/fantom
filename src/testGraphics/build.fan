#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Feb 2022  Brian Frank  Creation
//

using build

**
** Build: testGraphics
**
class Build : BuildPod
{
  new make()
  {
    podName = "testGraphics"
    summary = "Graphics test suite"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "https://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "https://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Git",
                "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0",
               "concurrent 1.0",
               "graphics 1.0",
               "graphicsJava 1.0",
               "dom 1.0",
               "domkit 1.0",
               "web 1.0",
               "wisp 1.0"]
    srcDirs = [`fan/`]
    resDirs = [`res/`]
    docApi  = false
  }
}