#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  17 Jul 2023  Matthew Giannini creation
//

using build

**
** Build: nodeJs
**
class Build : BuildPod
{
  new make()
  {
    podName = "nodeJs"
    summary = "Utilities for running Fantom in Node JS"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom",
               ]
    depends = ["sys 1.0",
               "build 1.0",
               "compiler 1.0",
               "compilerEs 1.0",
               "fandoc 1.0",
               "fanc 1.0",
               "fanc 1.0",
               "util 1.0",
              ]
    srcDirs = [
               `fan/`,
               `fan/cmd/`,
               `fan/fanc/`,
               `fan/ts/`,
              ]
    resDirs = [
               `res/`,
              ]
    index   = [
               "fanc.cmd": "nodeJs::JsCmd",
              ]
    docApi  = false
  }
}