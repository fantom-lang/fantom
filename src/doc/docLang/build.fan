#! /usr/bin/env fan
//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 May 07  Brian Frank  Creation
//

using build

**
** Build: docLang
**
class Build : BuildPod
{
  new make()
  {
    podName = "docLang"
    summary = "Fantom language documentation"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Docs",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    resDirs = [`doc/`]
  }
}