#! /usr/bin/env fan
//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 May 2017  Brian Frank  Creation
//

using build

**
** Build: graphics
**
class Build : BuildPod
{
  new make()
  {
    podName  = "graphics"
    summary  = "Graphics support"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "http://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "http://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Mercurial",
                "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends  = ["sys 1.0", "concurrent 1.0"]
    srcDirs  = [`fan/`, `test/`]
    docSrc   = true
  }
}