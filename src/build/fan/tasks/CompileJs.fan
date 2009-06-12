//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Andy Frank  Creation
//

using compiler

**
** Run the javascript compiler to produce a Fan pod.
**
class CompileJs : Task
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
    input.description = script.description
    input.podFacets   = script.podFacets
    input.depends     = script.parseDepends
    input.dependsDir  = script.resolveDir(script.dependsDir, true)
    input.log         = log
    input.mode        = CompilerInputMode.file
    input.homeDir     = script.scriptDir
    input.srcDirs     = script.resolveDirs(script.srcDirs)
    input.outDir      = script.libFanDir
    input.output      = CompilerOutputMode.podFile

    try
    {
      c := Type.find("compilerJs::JsCompiler").make([input])
      c->outDir     = outDir
      c->nativeDirs = nativeDirs
      c->force      = force
      c->compile
    }
    catch (CompilerErr err)
     {
      // all errors should already be logged by Compiler
      throw FatalBuildErr.make
    }
    catch (Err err)
    {
      log.error("Internal compiler error")
      err.trace
      throw FatalBuildErr.make
    }
  }

  File? outDir
  File[] nativeDirs := File[,]
  Bool force := false
}