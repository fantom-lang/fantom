#! /usr/bin/env fan
//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using build

**
** Build: domkit
**
class Build : BuildPod
{
  new make()
  {
    podName = "domkit"
    summary = "DOM Based UI Framework"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "http://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "http://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Mercurial",
                "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends = ["sys 1.0",
               "concurrent 1.0",
               "graphics 1.0",
               "dom 1.0"]
    srcDirs = [`fan/`, `fan/build/`]
//    resDirs = [`res/css/`]
    resDirs = [`fanCss/`]
  }
}