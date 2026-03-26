//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsWriter
**
class JsWriter
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(OutStream out, SourceMap? sourcemap := null)
  {
    this.out = out
    this.sourcemap = sourcemap
  }

  private OutStream out
  private SourceMap? sourcemap := null
  Int line := 0 { private set }
  Int col  := 0 { private set }
  private Bool needIndent := false
  private Int indentation := 0
  @NoDoc Bool trace := false

//////////////////////////////////////////////////////////////////////////
// JsWriter
//////////////////////////////////////////////////////////////////////////

  ** Write and then return this. If loc is not null, the text will be
  ** added to the generated source map.
  JsWriter w(Obj o, Loc? loc := null, Str? name := null)
  {
    if (needIndent)
    {
      spaces := indentation * 2
      out.writeChars(Str.spaces(spaces))
      col += spaces
      needIndent = false
    }
    str := o.toStr
    if (str.containsChar('\n')) throw Err("cannot w() str with newline: ${str}")
    if (loc != null) sourcemap?.add(str, Loc(loc.file, line, col), loc, name)
    if (trace) Env.cur.out.print(str)
    out.writeChars(str)
    col += str.size
    return this
  }

  ** Convenience for 'w(o,loc,name).nl'.
  JsWriter wl(Obj o, Loc? loc := null, Str? name := null)
  {
    this.w(o, loc, name).nl
  }

  ** Write newline and then return this.
  JsWriter nl()
  {
    if (trace) Env.cur.out.printLine
    out.writeChar('\n')
    ++line
    col = 0
    needIndent = true
    out.flush
    return this
  }


  ** Increment the indentation
  JsWriter indent() { indentation++; return this }

  ** Decrement the indentation
  JsWriter unindent()
  {
    indentation--
    if (indentation < 0) indentation = 0
    return this
  }

  JsWriter minify(InStream in, Bool close := true)
  {
    inBlock := false
    in.readAllLines.each |line|
    {
      // TODO: temp hack for inlining already minified js
      if (line.size > 1024) { w(line).nl; return }

      s := line
      // line comments
      if (s.size > 1 && (s[0] == '/' && s[1] == '/')) return
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
      s = s.trimEnd
      if (inBlock) return
      // if (s.size == 0) return
      w(s).nl
    }
    if (close) in.close
    return this
  }

}
