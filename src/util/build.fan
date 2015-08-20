#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 07  Brian Frank  Creation
//    1 Dec 09  Brian Frank  Rename fand to util
//

using build

**
** Build: util
**
class Build : BuildPod
{
  new make()
  {
    podName  = "util"
    summary  = "Utilities"
    meta     = ["org.name":     "Fantom",
                "org.uri":      "http://fantom.org/",
                "proj.name":    "Fantom Core",
                "proj.uri":     "http://fantom.org/",
                "license.name": "Academic Free License 3.0",
                "vcs.name":     "Mercurial",
                "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends  = ["sys 1.0", "concurrent 1.0"]
    srcDirs  = [`fan/`, `test/`]
    javaDirs = [`java/`]
    docSrc   = true
  }
}

