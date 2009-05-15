//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 06  Brian Frank  Creation
//

**
** BuildCs is the base class for build scripts used to manage
** building C# source code into a .NET exe or dll.
**
abstract class BuildCs : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Pod Meta-Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Required output file created by the compiler.
  **
  File? output

  **
  ** Required output type. Possible values are 'exe',
  ** 'winexe', 'library' or 'module'.
  **
  Str? targetType

  **
  ** Required list of directories to compile.  All C# source
  ** files in each directory will be compiled.
  **
  File[]? dirs

  **
  ** List of libraries to link to.
  **
  File[]? libs

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    ok := true
    ok &= validateReqField("output")
    ok &= validateReqField("targetType")
    ok &= validateReqField("dirs")
    if (!ok) throw FatalBuildErr.make
  }

//////////////////////////////////////////////////////////////////////////
// BuildScript
//////////////////////////////////////////////////////////////////////////

  **
  ** Default target is `compile`.
  **
  override Target defaultTarget() { return target("compile") }

//////////////////////////////////////////////////////////////////////////
// Dump Env
//////////////////////////////////////////////////////////////////////////

  @target="Dump env details to help build debugging"
  override Void dumpenv()
  {
    super.dumpenv

    if (!isWindows)
    {
      log.out.printLine("  skipped (not windows)")
      return
    }

    oldLevel := log.level
    log.level = LogLevel.silent
    try
      log.out.printLine("  dotnetHome:  ${CompileCs(this).dotnetHomeDir}")
    catch (Err e)
      log.out.printLine("  dotnetHome:  $e")
    finally
      log.level = oldLevel
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="compile C# source into exe or dll"
  Void compile()
  {
    if (!isWindows)
    {
      log.info("skipping [${scriptDir.name}]")
      return
    }

    log.info("compile [${scriptDir.name}]")
    log.indent

    // compile source
    csc := CompileCs.make(this)
    csc.output = output
    csc.targetType = targetType
    csc.src  = dirs
    csc.libs = libs
    csc.run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="delete all intermediate and target files"
  Void clean()
  {
    log.info("clean [${scriptDir.name}]")
    log.indent
    Delete.make(this, output).run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// CompileAll
//////////////////////////////////////////////////////////////////////////

  @target="alias for compile"
  Void compileAll()
  {
    compile
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @target= "clean+compile"
  Void full()
  {
    clean
    compile
  }
}