#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 08  Brian Frank  Creation
//

using build

**
** Build: docTools
**
class Build : BuildPod
{
  new make()
  {
    podName = "docTools"
    summary = "Fantom command line tools"
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