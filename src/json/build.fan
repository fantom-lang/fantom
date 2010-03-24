#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 08  Kevin McIntire  Creation
//

using build

// TODO: json has been replaced by util API

**
** Build: json
**
class Build : BuildPod
{
  new make()
  {
    podName = "json"
    summary = "JSON (Javascript Object Notation) serialization"
    depends = ["sys 1.0"]
//    srcDirs = [`fan/`, `test/`]
srcDirs = [`fan/`]
    docSrc  = true
  }
}

