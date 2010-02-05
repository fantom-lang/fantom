#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 08  Brian Frank  Creation
//

using build

**
** Build: icons
**
class Build : BuildPod
{
  new make()
  {
    podName = "icons"
    summary = "Standard icons library"
    depends = ["sys 1.0"]
    resDirs = [`x16/`, `x32/`, `x48/`, `x256/`]
    docApi  = false
  }
}