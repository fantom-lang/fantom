#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using build

**
** Build: dom
**
class Build : BuildPod
{
  new make()
  {
    podName = "dom"
    summary = "Web Browser DOM API"
    depends = ["sys 1.0", "web 1.0", "gfx 1.0"]
    srcDirs = [`fan/`, `test/`]
    jsDirs  = [`js/`]
    docSrc  = true
  }
}

