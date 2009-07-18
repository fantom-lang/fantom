#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using build

**
** Build: docCompiler
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "docCompiler"
    version = globalVersion
  }
}