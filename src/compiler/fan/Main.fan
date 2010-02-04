//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    3 Jun 06  Brian Frank  Ported from Java to Fantom - Megan's b-day
//

**
** Main is the main entry point for the Fantom compiler.
** Originally it was used for "fanc" command line, but it
** encapsualtes static methods used by sys.
**
class Main
{


  **
  ** Compile the script file into a transient pod.
  ** See `sys::Env.compileScript` for option definitions.
  **
  static Pod compileScript(Str podName, File file, [Str:Obj]? options := null)
  {
    input := CompilerInput.make
    input.podName        = podName
    input.summary        = "script"
    input.version        = Version("0")
    input.log.level      = LogLevel.warn
    input.includeDoc     = true
    input.isScript       = true
    input.srcStr         = file.readAllStr
    input.srcStrLoc      = Loc.makeFile(file)
    input.mode           = CompilerInputMode.str
    input.output         = CompilerOutputMode.transientPod

    if (options != null)
    {
      log := options["log"]
      if (log != null) input.log = log

      logOut := options["logOut"]
      if (logOut != null) input.log = CompilerLog(logOut)

      logLevel := options["logLevel"]
      if (logLevel != null) input.log.level = logLevel

      fcodeDump := options["fcodeDump"]
      if (fcodeDump == true) input.fcodeDump = true
    }

    return Compiler(input).compile.transientPod
  }

}