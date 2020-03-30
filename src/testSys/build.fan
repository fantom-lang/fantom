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
  new make()
  {
    podName = "testSys"
    summary = "System and runtime test suite"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom",
               "testSys.foo":"got\n it \u0123"]
    depends = ["sys 1.0", "concurrent 1.0"]
    index   = [
      "testSys.single": "works!",
      "testSys.mult": ["testSys-1","testSys-2"],
      //"sys.envProps": "testSys",
    ]
    srcDirs = [`fan/`]
    resDirs = [`res/`, `locale/`, `concurrent/locale/`]
    docApi  = false
  }
}