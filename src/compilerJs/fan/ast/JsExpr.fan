//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsExpr
**
** TODO FIXIT - TEMP TILL WE REFACTOR THIS CODE!!!!
**
class JsExpr : JsBlock
{
  new make(Node n) : super(n) {}
  override Void write(JsWriter out)
  {
    this.out = out
    expr(x)
  }
}

