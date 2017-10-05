#! /usr/bin/env fan
//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using build

**
** Build: testDomkit
**
class Build : BuildPod
{
  new make()
  {
    podName = "testDomkit"
    summary = "Domkit Test Framework"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends = ["sys 1.0",
               "concurrent 1.0",
               "util 1.0",
               "compilerJs 1.0",
               "web 1.0",
               "wisp 1.0",
               "dom 1.0",
               "domkit 1.0"]
    srcDirs = [`fan/`]
    resDirs = [`res/`]
    docApi  = false
  }
}


