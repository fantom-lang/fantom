#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using build

**
** Build: build
**
class Build : BuildPod
{
  new make()
  {
    podName    = "build"
    summary    = "Fantom build utility"
    meta       = ["org.name":     "Fantom",
                  "org.uri":      "http://fantom.org/",
                  "proj.name":    "Fantom Core",
                  "proj.uri":     "http://fantom.org/",
                  "license.name": "Academic Free License 3.0",
                  "vcs.name":     "Mercurial",
                  "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends    = ["sys 1.0", "compiler 1.0"]
    srcDirs    = [`fan/`, `fan/tasks/`]
    docSrc     = true
    dependsDir = devHomeDir.uri + `lib/fan/`
    outPodDir  = devHomeDir.plus(`lib/fan/`).uri
  }
}