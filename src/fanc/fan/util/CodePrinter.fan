//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using build
using compiler
using util

**
** Pretty print transpiled source code
**
mixin CodePrinter
{

  ** Class state
  abstract CodePrinterState m()

  ** Indent next lines
  This indent()
  {
    m.indentation++
    return this
  }

  ** Unindent next lines
  This unindent()
  {
    m.indentation--
    if (m.indentation < 0) m.indentation = 0
    return this
  }

  ** Print object - must never include newline, use` nl`
  This w(Obj o)
  {
    if (m.needIndent)
    {
      spaces := m.indentation * 2
      m.out.writeChars(Str.spaces(spaces))
      m.needIndent = false
    }
    str := o.toStr
    m.out.writeChars(str)
    return this
  }

  ** Print space
  This sp()
  {
    w(" ")
  }

  ** Print newline
  This nl()
  {
    m.needIndent = true
    m.out.printLine
    return this
  }
}

**************************************************************************
** CodePrinterState
**************************************************************************

class CodePrinterState
{
  new make(OutStream out) { this.out = out }
  internal Int indentation
  internal OutStream out
  internal Bool needIndent
  internal Expr[] exprStack := [,]
}

