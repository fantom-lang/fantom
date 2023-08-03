#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Sep 09  Brian Frank  Creation
//   01 Sep 11  Brian Frank  Check compile only (compilerDoc rework)
//

using build
using compiler

**
** Build: examples
**
class Build : BuildPod
{
  new make()
  {
    podName    = "examples"
    summary    = "Example code"
    meta       = ["org.name":     "Fantom",
                  "org.uri":      "http://fantom.org/",
                  "proj.name":    "Fantom Core",
                  "proj.uri":     "http://fantom.org/",
                  "license.name": "Academic Free License 3.0",
                  "vcs.name":     "Mercurial",
                  "vcs.uri":      "http://hg.fantom.org/fan-1.0/"]
    depends    = ["sys 1.0"]
    resDirs    = [`index.fog`, `concurrent/`, `email/`, `java/`, `js/`, `sys/`, `util/`, `web/`]
  }

  @Target { help = "Verify all examples compile" }
  override Void compile()
  {
    log.info("Compile code into HTML!")

    // load toc and filter out files
    toc := (scriptDir + `index.fog`).readObj as List
    Uri[] scripts := toc.findType(List#).map |List p->Uri| { p[0] }

    // verify that each script compiles
    fail := false
    scripts.each |scriptUri|
    {
      log.info("    $scriptUri ...")
      try
        Env.cur.compileScript(scriptDir + scriptUri)
      catch (Err e)
      {
        log.err("Failed to compile $scriptUri", e)
        fail = true
      }
    }

    // if we had any failures
    if (fail) throw fatal("One or more files failed to compile!")

    super.compile
  }

}

