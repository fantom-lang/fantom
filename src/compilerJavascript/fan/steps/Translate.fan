//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank  Creation
//

using compiler

**
** Translate AST into JavaScript source code
**
class Translate : JsCompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(JsCompiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("GenerateOutput")
    file  := compiler.outDir.createFile("${pod.name}.js")
    peers := Str:File[:]
    out   := file.out

    // resolve nativeDirs to file map
    compiler.nativeDirs.each |dir| {
      dir.listFiles.each |f| { peers[f.basename] = f }
    }

    // find types to compile
    jsTypes := types.findAll |def|
    {
      if (compiler.force) return true
      if (def.facets?.get("javascript")?->toStr == "@javascript=true") return true
      return false
    }

    // write pod
    typeDefs(out, jsTypes)
    refs := Str:CType[:]
    jsTypes.each |def|
    {
      // check for native first
      key := "${def.name}Peer"
      peer := peers[key]
      if (peer != null)
      {
        in := peer.in
        minify(in, out)
        in.close
        peers.remove(key)
      }

      // compile type
      w := JsWriter(compiler, def, out)
      w.write
      refs.setAll(w.refs)
    }

    // write out refs
    refs.each |def|
    {
      if (!def.name.startsWith("Curry\$")) return
      JsWriter(compiler, def, out).write
    }

    // write any left over natives
    peers.each |f|
    {
      in := f.in
      minify(in, out)
      in.close
    }

    out.close
    bombIfErr
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
  ** Minify JavaScript source code from the InStream and write
  ** the results to the OutStream.
  **
  private Void minify(InStream in, OutStream out)
  {
    inBlock := false
    in.readAllLines.each |line|
    {
      s := line
      // line comments
      i := s.index("//")
      if (i != null) s = s[0..<i]
      // block comments
      temp := s
      a := temp.index("/*")
      if (a != null)
      {
        s = temp[0..<a]
        inBlock = true
      }
      if (inBlock)
      {
        b := temp.index("*/")
        if (b != null)
        {
          s = (a == null) ? temp[b+2..-1] : s + temp[b+2..-1]
          inBlock = false
        }
      }
      // trim and print
      s = s.trim
      if (inBlock) return
      if (s.size == 0) return
      out.printLine(s)
    }
  }

}

