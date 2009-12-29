//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsWriter.
**
class JsWriter
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Make for specified output stream
  **
  new make(OutStream out)
  {
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Write and then return this.
  **
  JsWriter w(Obj o)
  {
    if (needIndent)
    {
      out.writeChars(Str.spaces(indentation*2))
      needIndent = false
    }
    out.writeChars(o.toStr)
    return this
  }

  **
  ** Write newline and then return this.
  **
  public JsWriter nl()
  {
    w("\n")
    needIndent = true
    out.flush
    return this
  }

  **
  ** Increment the indentation.
  **
  JsWriter indent()
  {
    indentation++
    return this
  }

  **
  ** Decrement the indentation.
  **
  JsWriter unindent()
  {
    indentation--
    if (indentation < 0) indentation = 0
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Minify
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the minified content of the InSteam.
  **
  Void minify(InStream in)
  {
    inBlock := false
    in.readAllLines.each |line|
    {
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
      if (s.size == 0) return
      out.printLine(s)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out
  Int indentation := 0
  Bool needIndent := false

}