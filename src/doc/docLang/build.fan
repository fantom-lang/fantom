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
    summary = "Language documentation"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Docs",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "http://hg.fantom.org/fan-1.0/"]
    resDirs = [`doc/`]
  }
}