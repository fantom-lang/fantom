//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 09  Andy Frank  Creation
//

using compiler

**
** Run the javascript compiler to produce a Fantom pod.
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
    input.inputLoc    = Loc.makeFile(script.scriptFile)
    input.podName     = script.podName
    input.version     = script.version
    input.dependsDir  = script.resolveDir(script.dependsDir, true)
    input.log         = log
    input.mode        = CompilerInputMode.file
    input.podDef      = script.podDef
    input.outDir      = script.libFanDir
    input.output      = CompilerOutputMode.podFile

    try
    {
      c := Type.find("compilerJs::JsCompiler").make([input])
      c->output     = CompilerOutput()
      c->out        = out
      c->nativeDirs = nativeDirs
      c->compile
    }
    catch (CompilerErr err)
     {
      // all errors should already be logged by Compiler
      throw FatalBuildErr.make
    }
    catch (Err err)
    {
      log.err("Internal compiler error")
      err.trace
      throw FatalBuildErr.make
    }
  }

  OutStream? out
  File[]? nativeDirs
}