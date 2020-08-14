#! /usr/bin/env fan
//
// Copyright (c) 2020, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Aug 20  Matthew Giannini Creation
//

using build

**
** Build: math
**
class Build : BuildPod
{
  new make()
  {
    podName  = "math"
    summary  = "Math utilities and functions"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "https://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "https://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Git",
                "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends  = ["sys 1.0",]
    srcDirs  = [`fan/`, `test/`]
    javaDirs = [`java/`]
    docSrc   = true
  }
}

