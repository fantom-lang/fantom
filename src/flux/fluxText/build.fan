#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 08  Brian Frank  Creation
//

using build

**
** Build: fluxText
**
class Build : BuildPod
{
  new make()
  {
    podName = "fluxText"
    summary = "Flux: Text Editor"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    depends = ["sys 1.0", "concurrent 1.0", "syntax 1.0", "gfx 1.0", "fwt 1.0", "flux 1.0"]
    srcDirs = [`fan/`, `test/`]
    resDirs = [`locale/`]
    docSrc  = true
    index   = ["flux.view.mime.text": "fluxText::TextEditor"]
  }
}