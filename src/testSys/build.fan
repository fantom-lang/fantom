#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 06  Brian Frank  Creation
//

using build

**
** Build: testSys
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "testSys"
    version     = globalVersion
    description = "Sys test suite"
    depends     = ["sys 1.0"]
    srcDirs     = [`fan/`]
    resDirs     = [`res/`, `locale/`]
    podFacets =
    [
      "doc": false,
      "indexFacets": ["testSysByStr", "testSysByType"]
    ]
  }

}
