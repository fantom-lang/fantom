#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using build

**
** Build: graphicsJava
**
class Build : BuildPod
{
  new make()
  {
    podName = "graphicsJava"
    summary = "Server and desktop Java2D graphics"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "https://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "https://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Git",
                "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0",
               "concurrent 1.0",
               "graphics 1.0"]
    srcDirs = [`fan/server/`, `fan/java2D/`]
    docApi  = false
  }
}