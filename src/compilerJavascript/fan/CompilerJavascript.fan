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
    this.output = CompilerOutput()
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
    jsTypes := types.findAll |def| {
      force || def.facets?.get("javascript")?->toStr == "@javascript=true"
    }

    // write pod
    typeDefs(out, jsTypes)
    jsTypes.each |def| { JavascriptWriter(this, def, out).write }

    out.close
    // bombIfErr...
    if (!errors.isEmpty) throw errors.first
  }

  **
  ** Write the TypeDefs.
  **
  private Void typeDefs(OutStream out, TypeDef[] types)
  {
    out.printLine("with(sys_Pod.\$add(\"$pod.name\"))")
    out.printLine("{")

    // types
    types.each |def,i|
    {
      base := def.base ?: "sys::Obj"
      out.printLine("var \$$i=\$at(\"$def.name\",\"$base\")")
    }

    // slots
    types.each |def,i|
    {
      if (def.slotDefs.size > 0)
      {
        out.print("\$$i")
        def.slotDefs.each |slot|
        {
          if (slot is FieldDef)
            out.print(".\$af(\"$slot.name\",$slot.flags,\"${slot->fieldType->signature}\")")
          else if (slot is MethodDef && !slot->isFieldAccessor)
            out.print(".\$am(\"$slot.name\")")
        }
        out.printLine(";")
      }
    }

    out.printLine("};")
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