#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 07  Brian Frank  Creation
//

using build

**
** Build: sql
**
class Build : BuildPod
{
  new make()
  {
    podName  = "sql"
    summary  = "Relational database access"
    depends  = ["sys 1.0", "concurrent 1.0"]
    srcDirs  = [`fan/`, `fan/dialects/`, `test/`]
    javaDirs = [`java/`]
    docSrc   = true
  }
}