#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 08  Kevin McIntire  Creation
//

using build

**
** Build: json
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "json"
  }
}