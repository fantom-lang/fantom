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
    log.debug("Translate")

    natives = compiler.natives.dup
    writeTypeInfo
    writeTypes
    writeNatives

    bombIfErr
  }

//////////////////////////////////////////////////////////////////////////
// TypeInfo
//////////////////////////////////////////////////////////////////////////

  Void writeTypeInfo()
  {
    out := compiler.out
    out.printLine("with(sys_Pod.\$add(\"$pod.name\"))")
    out.printLine("{")

    // types
    compiler.toCompile.each |def,i|
    {
      base := def.base ?: "sys::Obj"
      out.printLine("var \$$i=\$at(\"$def.name\",\"$base\")")
    }

    // slots
    compiler.toCompile.each |def,i|
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

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  Void writeTypes()
  {
    refs := Str:CType[:]

    compiler.toCompile.each |def|
    {
      // always write peer first
      key := "${def.name}Peer"
      peer := natives[key]
      if (peer != null)
      {
        in := peer.in
        minify(in, compiler.out)
        in.close
        natives.remove(key)
      }

      // compile type
      w := JsWriter(compiler, def, compiler.out)
      w.write
      refs.setAll(w.refs)
    }

    refs.each |def|
    {
      if (!def.name.startsWith("Curry\$")) return
      JsWriter(compiler, def, compiler.out).write
    }
  }

//////////////////////////////////////////////////////////////////////////
// Natives
//////////////////////////////////////////////////////////////////////////

  Void writeNatives()
  {
    natives.each |f|
    {
      in := f.in
      minify(in, compiler.out)
      in.close
    }
  }

  Void minify(InStream in, OutStream out)
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

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  [Str:File]? natives

}

