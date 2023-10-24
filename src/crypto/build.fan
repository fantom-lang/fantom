#! /usr/bin/env fan
//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Aug 2021 Matthew Giannini   Creation
//

using build

**
** Build: crypto
**
class Build : BuildPod
{
  new make()
  {
    podName  = "crypto"
    summary  = "Cryptography API"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "https://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "https://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Git",
                "vcs.uri":      "https://github.com/fantom-lang/fantom",
               ]
    depends  = ["sys 1.0",
               ]
    srcDirs  = [`fan/`,
                `test/`,
               ]
    javaDirs = Uri[,] // force .class files to be written
    docSrc   = true
  }
}