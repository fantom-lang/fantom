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
    summary = "Documentation for DomKit HTML5 UI framework"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Docs",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    resDirs = [`doc/`]
  }
}