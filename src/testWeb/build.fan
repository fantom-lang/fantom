#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 08  Andy Frank  Creation
//

using build

**
** Build: testWeb
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "testWeb"
  }
}