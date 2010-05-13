#! /usr/bin/env fan
//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Feb 10 Brian Frank  Creation
//

using build

**
** Build: concurrent
**
class Build : BuildPod
{
  new make()
  {
    podName  = "concurrent"
    summary  = "Utilities for concurrent programming"
    depends  = ["sys 1.0"]
    srcDirs  = [`fan/`, `test/`]
    javaDirs = [`java/`]
    jsDirs   = [`js/`]
    docSrc   = true
  }
}