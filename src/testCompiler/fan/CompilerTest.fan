//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Aug 06  Brian Frank  Creation
//

using compiler

**
** Abstract base with useful utilities common to compiler tests.
**
abstract class CompilerTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Str podName() { return id.replace("::", "_") + "_" + podNameSuffix }

  Void compile(Str src, LogLevel logLevel := LogLevel.error, Bool isScript := true)
  {
    input := CompilerInput.make
    input.podName     = podName
    input.version     = Version.defVal
    input.log.level   = logLevel
    input.isTest      = true
    input.isScript    = isScript
    input.output      = CompilerOutputMode.transientPod
    input.mode        = CompilerInputMode.str
    input.srcStr      = src
    input.podStr      = podStr
    input.srcStrLocation = Location.make("Script")

    compiler = Compiler.make(input)
    pod = compiler.compile.transientPod
    podNameSuffix++
  }

  Void verifyErrors(Str src, Obj[] errors, Bool isScript := true)
  {
    try
    {
      compile(src, LogLevel.silent, isScript)
    }
    catch (CompilerErr e)
    {
    }
    catch (Err e)
    {
      e.trace
      fail
    }
    podStr = null
    doVerifyErrors(errors)
  }

  Void doVerifyErrors(Obj[] errors)
  {
    c := compiler
    if (dumpErrors)
      echo(c.errors.join("\n") |CompilerErr e->Str| { return "${e.location.toLocationStr.justl(14)} $e.toStr" })
    verifyEq("size=${c.errors.size}", "size=${errors.size / 3}")
    for (i := 0; i<errors.size/3; ++i)
    {
      verifyEq(c.errors[i].message,       errors[i*3+2])
      verifyEq(c.errors[i].location.line, errors[i*3+0])
      verifyEq(c.errors[i].location.col,  errors[i*3+1])
    }
  }

  Str symbolsStr
  {
    get { throw UnsupportedErr() }
    set { podStr = "pod $podName {\n" + val  + "\n}" }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Compiler? compiler      // compile()
  Pod? pod                // compiled pod
  Str? podStr             // "pod.fan" to pass to compiler
  Int podNameSuffix := 0
  Bool dumpErrors := false

}