#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 07  Brian Frank  Creation
//

using build

**
** Build: fand
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "fand"
    version = globalVersion
  }
}