#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Nov 08  Brian Frank  Creation
//

using build

**
** Build: compilerJava
**
class Build : BuildPod
{

  override Void setup()
  {
    podName    = "compilerJava"
    dependsDir = libFanDir.uri
  }

}