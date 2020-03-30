#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using build

**
** Build: sys
**
** Note: this script just builds the Fan sys.pod; scripts in
** the java/ and dotnet/ subdirectories are used to build
** sys.jar and sys.dll
**
class Build : BuildPod
{
  new make()
  {
    podName   = "sys"
    summary   = "Fantom system runtime"
    meta      = ["org.name":     "Fantom",
                 "org.uri":      "https://fantom.org/",
                 "proj.name":    "Fantom Core",
                 "proj.uri":     "https://fantom.org/",
                 "license.name": "Academic Free License 3.0",
                 "vcs.name":     "Git",
                 "vcs.uri":      "https://github.com/fantom-lang/fantom"]
    srcDirs   = [`fan/`]
    resDirs   = [`locale/`]
    docSrc    = true
    outPodDir = devHomeDir.uri + `lib/fan/`
    index     = ["sys.uriScheme.fan": "sys::FanScheme",
                 "sys.uriScheme.file": "sys::FileScheme"]
  }
}