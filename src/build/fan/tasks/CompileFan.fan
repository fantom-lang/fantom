//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using compiler

**
** Run the fan compiler to produce a Fan pod.
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
    input.depends     = script.parseDepends
    input.dependsDir  = script.resolveDir(script.dependsDir, true)
    input.log         = log
    input.includeDoc  = includeDoc
    input.includeSrc  = includeSrc
    input.mode        = CompilerInputMode.file
    input.homeDir     = script.scriptDir
    input.srcDirs     = script.resolveDirs(script.srcDirs)
    input.resDirs     = script.resolveDirs(script.resDirs)
    input.outDir      = script.libFanDir
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