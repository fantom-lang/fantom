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
    podName = "util"
    summary = "Utilities"
    depends = ["sys 1.0", "concurrent 1.0"]
    srcDirs = [`fan/`, `test/`]
    docSrc  = true
  }
}

