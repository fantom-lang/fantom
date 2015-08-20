#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 08  Brian Frank  Break out tests
//

using build

**
** Build: testCompiler
**
class Build : BuildPod
{
  new make()
  {
    podName = "testCompiler"
    summary = "Test suite for compiler"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends = ["sys 1.0", "compiler 1.0", "concurrent 1.0"]
    srcDirs = [`fan/`]
    docApi  = false
  }
}