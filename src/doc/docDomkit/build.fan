#! /usr/bin/env fan
//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Jan 2017  Andy Frank  Creation
//

using build

**
** Build: docDomkit
**
class Build : BuildPod
{
  new make()
  {
    podName = "docDomkit"
    summary = "Fantom DomKit HTML5 UI framework documentation"
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