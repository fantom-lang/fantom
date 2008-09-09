//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using compiler

**
** FanScript is used to compiler a Fan script into
** memory and run it via reflection.
**
class FanScript : Task
{
  new make(BuildScript script, File file, Obj[] args := null)
    : super(script)
  {
    this.file = file
    this.args = args
  }

  Pod compile()
  {
    try
    {
      // TODO - this is a temp hack to compile a script
      podName := file.uri.toStr.replace("/", "_").replace(":", "").replace(".", "_")
      input := CompilerInput.make
      input.podName    = podName
      input.log.level  = LogLevel.error // TODO - use my own log
      input.isScript   = true
      input.mode       = CompilerInputMode.str
      input.srcStr     = file.readAllStr
      input.srcStrLocation = Location.makeFile(file)
      input.output     = CompilerOutputMode.transientPod
      return Compiler.make(input).compile.transientPod
    }
    catch (CompilerErr err)
    {
      // all errors should already be logged by Compiler
      throw FatalBuildErr.make
    }
    catch (Err err)
    {
      err.trace
      throw fatal("Cannot load script [$file]")
    }
  }

  override Void run()
  {
    // run main on first type with specified args
    t := compile.types.first
    main := t.method("main")
    if (main.isStatic)
      main.call(args)
    else
      main.callOn(t.make, args)
  }

  File file
  Obj[] args
}