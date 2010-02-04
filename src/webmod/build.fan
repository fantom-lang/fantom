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
    depends = ["sys 1.0", "inet 1.0", "web 1.0", "util 1.0"]
    srcDirs = [`fan/`]
    docSrc  = true
  }
}


