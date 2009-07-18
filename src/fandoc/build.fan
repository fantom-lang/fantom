#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Feb 07  Brian Frank  Creation
//

using build

**
** Build: fandoc
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "fandoc"
    version = globalVersion
  }
}