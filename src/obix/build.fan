#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 09  Brian Frank  Creation
//

using build

**
** Build: obix
**
class Build : BuildPod
{
  new make()
  {
    podName = "obix"
    summary = "oBIX XML modeling and client and server REST"
    depends = ["sys 1.0", "inet 1.0", "web 1.0", "xml 1.0"]
    srcDirs = [`fan/`, `test/`]
    resDirs = [`res/`]
    docSrc  = true
  }
}