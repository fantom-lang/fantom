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
  new make()
  {
    podName = "testJava"
    summary = "Test suite for Java FFI compiler plugin"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "compiler 1.0", "compilerJava 1.0", "testCompiler 1.0"]
    srcDirs = [`fan/`]
    docApi  = false
  }
}


