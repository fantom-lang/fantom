#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

using build

**
** Build: dom
**
class Build : BuildPod
{
  new make()
  {
    podName = "dom"
    summary = "Web Browser DOM API"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends = ["sys 1.0", "concurrent 1.0", "web 1.0"]
    srcDirs = [`fan/`, `test/`]
    jsDirs  = [`js/`]
    docSrc  = true
  }
}

