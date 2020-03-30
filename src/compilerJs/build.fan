#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Dec 08  Andy Frank  Creation
//

using build

**
** Build: compilerJs
**
class Build : BuildPod
{
  new make()
  {
    podName = "compilerJs"
    summary = "Fantom to JavaScript Compiler"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "compiler 1.0"]
    srcDirs = [`fan/`, `fan/ast/`, `fan/runner/`, `fan/util/`]
    resDirs = [`res/`]
    docSrc  = true
  }
}