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
class Build : BuildScript
{
  @Target { help = "Verify all examples compile" }
  Void compile()
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
  }

}

