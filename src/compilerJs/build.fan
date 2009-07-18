#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Dec 08  Andy Frank  Creation
//

using build

**
** Build: compilerJs
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "compilerJs"
    version = globalVersion
  }
}