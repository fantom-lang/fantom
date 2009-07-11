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

  **
  ** Write the JavaScript qname for a CType.
  **
  JsWriter qname(CType t)
  {
    w("fan.${t.pod.name}.$t.name")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out
  Int indentation := 0
  Bool needIndent := false

}