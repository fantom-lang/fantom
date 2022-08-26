#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 2022  Kiera O'Flynn   Creation
//

using build

class Build : build::BuildPod
{
  new make()
  {
    podName = "yaml"
    summary = "YAML parser for Fantom"
    meta    = ["org.name":     "Fantom",
               "org.uri":      "https://fantom.org/",
               "proj.name":    "Fantom Core",
               "proj.uri":     "https://fantom.org/",
               "license.name": "Academic Free License 3.0",
               "vcs.name":     "Git",
               "vcs.uri":      "https://github.com/fantom-lang/fantom",
              ]
    depends = ["sys 1.0",
               "util 1.0",
              ]
    srcDirs = [`fan/`, `test/`]
    docSrc  = true
  }


  @Target { help = "Download the latest release of https://github.com/yaml/yaml-test-suite into your Fantom installation for testing" }
  Void preptest()
  {
    Slot.findMethod("yaml::PrepTest.main").call
  }

  @Target { help = "Clear any downloaded tests from your Fantom installation" }
  Void cleantest()
  {
    target := Env.cur.homeDir + `etc/yaml/tests/`
    if (target.exists)
      target.delete
  }
}