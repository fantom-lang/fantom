#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jul 07  Brian Frank  Creation
//

using build

**
** Build: docCookbook
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "docCookbook"
    version = globalVersion
  }
}