//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsBlock
**
class JsBlock : JsNode
{
  new make(CompilerSupport support, Block block, Bool inClosure)
    : super(support)
  {
    this.inClosure = inClosure
    this.stmts = block.stmts.map |s->JsStmt| { JsStmt.makeFor(support, s, inClosure) }
  }

  override Void write(JsWriter out)
  {
    stmts.each |s|
    {
      s.write(out)
      out.w(";").nl
    }
  }

  JsStmt[] stmts   // statements for this block
  Bool inClosure   // does this block occur inside a closure
}