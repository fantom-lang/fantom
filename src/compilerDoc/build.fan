#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

using build

**
** Build: compilerDoc
**
class Build : BuildPod
{
  new make()
  {
    podName    = "compilerDoc"
    summary    = "Compiler to model and generate API docs"
    meta       = ["org.name":     "Fantom",
                  "org.uri":      "https://fantom.org/",
                  "proj.name":    "Fantom Core",
                  "proj.uri":     "https://fantom.org/",
                  "license.name": "Academic Free License 3.0",
                  "vcs.name":     "Git",
                  "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends    = ["sys 1.0",
                  "concurrent 1.0",
                  "fandoc 1.0",
                  "syntax 1.0",
                  "util 1.0",
                  "web 1.0"]
    srcDirs    = [`fan/env/`, `fan/model/`, `fan/renderers/`, `fan/util/`, `test/`]
    resDirs    = [`res/`]
    docSrc     = true
  }
}