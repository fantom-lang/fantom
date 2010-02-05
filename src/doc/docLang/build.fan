#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 May 07  Brian Frank  Creation
//

using build

**
** Build: docLang
**
class Build : BuildPod
{
  new make()
  {
    podName = "docLang"
    summary = "Language documentation"
    resDirs = [`doc/`]
  }
}