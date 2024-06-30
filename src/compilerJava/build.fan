#! /usr/bin/env fansubstitute
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Nov 08  Brian Frank  Creation
//

using build

**
** Build: compilerJava
**
class Build : BuildPod
{
  new make()
  {
    podName    = "compilerJava"
    summary    = "Compiler FFI Plugin for Java"
    meta       = ["org.name":     "Fantom",
                  "org.uri":      "https://fantom.org/",
                  "proj.name":    "Fantom Core",
                  "proj.uri":     "https://fantom.org/",
                  "license.name": "Academic Free License 3.0",
                  "vcs.name":     "Git",
                  "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends    = ["sys 1.0", "compiler 1.0"]
    srcDirs    = [`fan/`, `fan/cp/`, `fan/dasm/`]
    docSrc     = true
    dependsDir = devHomeDir.uri + `lib/fan/`
    outPodDir  = devHomeDir.uri + `lib/fan/`
    index      = ["compiler.bridge.java": "compilerJava::JavaBridge"]
  }
}

