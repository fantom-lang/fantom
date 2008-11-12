#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Nov 08  Brian Frank  Creation
//

using build

**
** Build: xml
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "xml"
    version     = globalVersion
    description = "XML Parser and Document Modeling"
    depends     = ["sys 1.0"]
    srcDirs     = [`fan/`, `test/`]
  }

}