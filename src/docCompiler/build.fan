#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using build

**
** Build: docCompiler
**
class Build : BuildPod
{
  new make()
  {
    podName = "docCompiler"
    summary = "Fantom documentation compiler"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "http://hg.fantom.org/fan-1.0/"]
    depends = ["sys 1.0","compiler 1.0", "build 1.0", "util 1.0", "fandoc 1.0"]
    srcDirs = [`fan/`, `fan/steps/`, `fan/html/`, `test/`]
    resDirs = [`res/`]
    docSrc  = true
  }
}


