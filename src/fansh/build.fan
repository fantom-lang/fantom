#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 08  Brian Frank  Creation
//

using build

**
** Build: fansh
**
class Build : BuildPod
{
  new make()
  {
    podName = "fansh"
    summary = "Interactive Fantom Shell"
    depends = ["sys 1.0", "compiler 1.0", "concurrent 1.0"]
    srcDirs = [`fan/`]
    docSrc  = true
  }
}