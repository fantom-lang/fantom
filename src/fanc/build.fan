#! /usr/bin/env fan
//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using build

**
** Build: fanc
**
class Build : BuildPod
{
  new make()
  {
    podName  = "fanc"
    summary  = "Fan command line compiler"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "https://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "https://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Git",
                "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends  = ["sys 1.0", "build 1.0", "compiler 1.0", "util 1.0"]
    srcDirs  = [`fan/`,
                `fan/java/`,
                `fan/util/`]
    docSrc   = true
  }
}

