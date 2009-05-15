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

    // find types to compile
    filter := types.findAll |def| {
      force || def.facets?.get("javascript")?->toStr == "@javascript=true"
    }

    // pod
    out.printLine("with(sys_Pod.\$add(\"$pod.name\"))")
    out.printLine("{")
    filter.each |def|
    {
      base := def.base ?: "sys::Obj"
      out.print("\$at(\"$def.name\",\"$base\")")
      def.slotDefs.each |slot|
      {
        if (slot is FieldDef)
          out.print(".\$af(\"$slot.name\",$slot.flags,\"${slot->fieldType->qname}\")")
      }
      out.printLine(";")
    }
    out.printLine("};")

    // types
    filter.each |def| { JavascriptWriter(this, def, out).write }

    out.close
    // bombIfErr...
    if (!errors.isEmpty) throw errors.first
  }

  **
  ** Directory to write compiled Javascript source files to
  **
  File? outDir

  **
  ** Force all types and slots to be compiled even if they do
  ** have the @javascript facet.
  **
  Bool force := false

}