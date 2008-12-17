//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank  Creation
//

using compiler

**
** Fan to Javascript Compiler.
**
class CompilerJavascript : Compiler
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with reasonable defaults
  **
  new make(CompilerInput input)
    : super(input)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile fan source code from the configured CompilerInput
  ** into a fan pod and return the resulting CompilerOutput.
  **
  override CompilerOutput compile()
  {
    log.info("Compile [${input.podName}]")
    log.indent

    InitInput(this).run
    ResolveDepends(this).run
    ScanForUsingsAndTypes(this).run
    ResolveImports(this).run
    Parse(this).run
    OrderByInheritance(this).run
    CheckInheritance(this).run
    Inherit(this).run
    DefaultCtor(this).run
    InitEnum(this).run
    InitClosures(this).run
    Normalize(this).run
    ResolveExpr(this).run
    CheckErrors(this).run
    CheckParamDefs(this).run
    ClosureVars(this).run
    //Assemble(this).run
    //GenerateOutput(this).run
    generateOutput

    log.unindent
    return output
  }

  **
  ** Directory to write compiled Javascript source files to
  **
  Void generateOutput()
  {
    log.debug("GenerateOutput")
    file := outDir.createFile("${pod.name}.js")
    out  := file.out
    types.each |TypeDef def|
    {
      JavascriptWriter(this, def, out).write
    }
    out.close
    // bombIfErr...
    if (!errors.isEmpty) throw errors.first
  }

  **
  ** Directory to write compiled Javascript source files to
  **
  File outDir

}