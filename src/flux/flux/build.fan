#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using build

**
** Build: flux
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "flux"
    version     = globalVersion
    description = "Flux: Core Application"
    depends     = ["sys 1.0", "gfx 1.0", "fwt 1.0", "compiler 1.0"]
    srcDirs     = [`fan/`, `fan/views/`, `fan/sidebars/`, `test/`]
    resDirs     = [`locale/`, `test/files/`, `test/files/sub/`]
    includeSrc  = true
    podFacets =
    [
      "sys::indexFacets":
      [
        "flux::fluxResource",
        "flux::fluxSideBar",
        "flux::fluxView",
        "flux::fluxViewMimeType"
      ]
    ]
  }

}