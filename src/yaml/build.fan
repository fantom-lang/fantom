#! /usr/bin/env fan
//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 2022  Kiera O'Flynn   Creation
//

using build
using util
using web

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
    // Download latest data tag from yaml/yaml-test-suite
    reqHeaders := Str:Str[:] { caseInsensitive = true }.add("User-Agent", "Fantom/1.0")
    tag := (JsonInStream(
              WebClient(`https://api.github.com/repos/yaml/yaml-test-suite/tags`)
              { it.reqHeaders = reqHeaders }
              .getIn)
            .readJson as [Str:Str][])
            .find |tag| { tag["name"].startsWith("data") }

    // Find target directory
    target := Env.cur.homeDir + `etc/yaml/tests/`

    // Delete old directory, if applicable
    if (target.exists)
      target.delete

    // Create new directory to unzip to
    target.create
    zip := Zip.read(
            WebClient(tag["zipball_url"].toUri)
            { it.reqHeaders = reqHeaders }
            .getIn)
    File? f
    while ((f = zip.readNext) != null)
    {
      if (f.uri == `/`) continue
      if (!f.uri.toStr.contains("/tags/") && !f.uri.toStr.contains("/name/"))
        f.copyTo(target + f.uri.relTo(("/${f.uri.path[0]}/").toUri), ["overwrite":false])
    }

    echo("SUCCESS: downloaded tests [$target.osPath]")
  }

  @Target { help = "Clear any downloaded tests from your Fantom installation" }
  Void cleantest()
  {
    target := Env.cur.homeDir + `etc/yaml/tests/`
    if (target.exists)
      target.delete
  }
}