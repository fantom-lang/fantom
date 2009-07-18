#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 08  Brian Frank  Creation
//

using build

**
** Build: docTools
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "docTools"
    version = globalVersion
  }
}