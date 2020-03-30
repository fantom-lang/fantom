#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

using build

**
** Build: web
**
class Build : BuildPod
{
  new make()
  {
    podName = "web"
    summary = "Standard weblet APIs for processing HTTP requests"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "concurrent 1.0", "inet 1.0"]
    srcDirs = [`fan/`, `test/`]
    docSrc  = true
  }
}