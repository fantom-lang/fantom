#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Nov 08  Brian Frank  Break out tests
//

using build

**
** Build: testJava
**
class Build : BuildPod
{
  override Void setup()
  {
    podName     = "testJava"
    version     = globalVersion
    depends     = ["sys 1.0", "compiler 1.0", "compilerJava 1.0", "testCompiler 1.0"]
    srcDirs     = [`fan/`]
    includeSrc  = false
    includeFandoc = false
    description = "TODO-SYM"
  }

}