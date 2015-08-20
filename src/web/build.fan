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
               "org.uri":      "http://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "http://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Mercurial",
               "vcs.uri":      "https://bitbucket.org/fantom/fan-1.0/"]
    depends = ["sys 1.0", "concurrent 1.0", "inet 1.0"]
    srcDirs = [`fan/`, `test/`]
    docSrc  = true
  }
}