#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jun 2009  Andy Frank   Creation
//  17 Mar 2011  Andy Frank   Move from frescoKit to webfwt
//  20 Jul 2012  Brian Frank  Move to fantom core
//

using build

**
** Build: webfwt
**
class Build : BuildPod
{
  new make()
  {
    podName = "webfwt"
    summary = "Web extensions to the FWT toolkit"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "gfx 1.0", "fwt 1.0", "web 1.0"]
    srcDirs = [`fan/`,
               //`fan/internal/`,
               `fan/hud/`,
               `test/`]
    jsDirs  = [`js/`]
    resDirs = [`locale/`, `res/img/`]
    docSrc  = true
  }
}