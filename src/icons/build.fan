#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 08  Brian Frank  Creation
//

using build

**
** Build: icons
**
class Build : BuildPod
{
  new make()
  {
    podName = "icons"
    summary = "Standard icons library"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0"]
    resDirs = [`x16/`, `x32/`, `x48/`, `x64/`, `x256/`]
    docApi  = false
  }
}