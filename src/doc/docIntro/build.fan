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
** Build: docIntro
**
class Build : BuildPod
{
  new make()
  {
    podName = "docIntro"
    summary = "Overview and getting started with Fantom"
    resDirs = [`doc/`]
  }
}