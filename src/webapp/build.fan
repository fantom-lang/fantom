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
    podName     = "webapp"
    version     = globalVersion
    description = "Framework for building web applications"
    depends     = ["sys 1.0", "inet 1.0", "web 1.0", "fand 1.0"]
    srcDirs     = [`fan/`, `test/`]
    includeSrc  = true
    podFacets =
    [
      "indexFacets": ["webView"]
    ]
  }

}