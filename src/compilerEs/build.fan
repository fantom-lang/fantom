#! /usr/bin/env fan
//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Mar 23  Matthew Giannini  Creation
//

using build

**
** Build: compilerJsx
**
class Build : BuildPod
{
  new make()
  {
    podName = "compilerEs"
    summary = "Fantom to ECMAScript Compiler"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "compiler 1.0",]
    srcDirs = [`fan/`,
               `fan/ast/`,
               `fan/util/`,
              ]
    docSrc  = true
  }
}