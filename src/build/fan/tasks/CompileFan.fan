//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using compiler

**
** Run the compiler to produce a Fantom pod.
**
class CompileFan : Task
{
  new make(BuildPod script)
    : super(script)
  {
  }

  override Void run()
  {
    script := script as BuildPod

    input := CompilerInput.make
    input.inputLoc    = Location.makeFile(script.scriptFile)
    input.podName     = script.podName
    input.version     = script.version
    input.dependsDir  = script.resolveDir(script.dependsDir, true)
    input.log         = log
    input.includeDoc  = includeDoc
    input.mode        = CompilerInputMode.file
    input.podDef      = script.podDef
    input.outDir      = script.outDir.toFile
    input.output      = CompilerOutputMode.podFile

    try
    {
      Compiler(input).compile
    }
    catch (CompilerErr err)
     {
      // all errors should already be logged by Compiler
      throw FatalBuildErr()
    }
    catch (Err err)
    {
      log.error("Internal compiler error")
      err.trace
      throw FatalBuildErr.make
    }
  }

  Bool includeDoc := false
  Bool includeSrc := false
}