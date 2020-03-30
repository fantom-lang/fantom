#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 09  Brian Frank  Creation
//

using build

**
** Build: webmod
**
class Build : BuildPod
{
  new make()
  {
    podName = "webmod"
    summary = "Standard library of WebMods"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "inet 1.0", "web 1.0", "util 1.0"]
    srcDirs = [`fan/`]
    docSrc  = true
  }
}


