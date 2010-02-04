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
    depends    = ["sys 1.0", "compiler 1.0"]
    srcDirs    = [`fan/`, `fan/tasks/`]
    docSrc     = true
    dependsDir = devHomeDir.uri + `lib/fan/`
    outDir     = devHomeDir.plus(`lib/fan/`).uri
  }
}