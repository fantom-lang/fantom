#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 May 11  Brian Frank  Creation
//

using build

**
** Build: fanr
**
class Build : BuildPod
{
  new make()
  {
    podName = "fanr"
    summary = "Fantom Repository Manager"
    depends = ["sys 1.0", "concurrent 1.0", "web 1.0"]
    srcDirs = [`fan/`,
               `fan/file/`,
               `fan/query/`,
               `fan/tool/`,
               `fan/web/`,
               `test/`]
    docSrc  = true
  }
}

