#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

using build

**
** Build: webapp
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "webapp"
  }
}