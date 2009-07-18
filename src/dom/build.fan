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
  override Void setup()
  {
    podName = "dom"
    version = globalVersion
  }
}