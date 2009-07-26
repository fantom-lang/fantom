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
    this.support = CompilerSupport(compiler)
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("Translate")

    this.out = JsWriter(compiler.out)
    this.natives = compiler.natives?.dup ?: Str:File[:]

    JsPod(support, compiler.pod, compiler.toCompile).write(out)
    writeTypes
    writeNatives

    bombIfErr
  }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  Void writeTypes()
  {

    compiler.toCompile.each |def|
    {
      // we inline closures directly, so no need to generate
      // anonymous types like we do in Java and .NET
      if (def.isClosure) return
      if (def.qname.contains("\$Cvars")) return

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
      JsType(support, def).write(out)
    }

    // emit referenced synthentic types
    compiler.synth.each |def|
    {
      JsType(support, def).write(out)
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
// need to check if inside str
//      i := s.index("//")
//      if (i != null) s = s[0..<i]
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

  CompilerSupport support
  [Str:File]? natives
  JsWriter? out

}

