//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 09  Andy Frank  Creation
//

using compiler

**
** JsStmt
**
abstract class JsStmt : JsNode
{
  new make(CompilerSupport s, Bool inClosure) : super(s)
  {
    this.inClosure = inClosure
  }

  static JsStmt makeFor(CompilerSupport s, Stmt stmt, Bool inClosure)
  {
    switch (stmt.id)
    {
      case StmtId.nop:          return JsNoOpStmt(s)
      case StmtId.expr:         return JsExprStmt(s, stmt, inClosure)
      case StmtId.localDef:     return JsLocalDefStmt(s, stmt, inClosure)
      case StmtId.ifStmt:       return JsIfStmt(s, stmt, inClosure)
      case StmtId.returnStmt:   return JsReturnStmt(s, stmt, inClosure)
      case StmtId.throwStmt:    return JsThrowStmt(s, stmt, inClosure)
      case StmtId.forStmt:      return JsForStmt(s, stmt, inClosure)
      case StmtId.whileStmt:    return JsWhileStmt(s, stmt, inClosure)
      case StmtId.breakStmt:    return JsBreakStmt(s)
      case StmtId.continueStmt: return JsContinueStmt(s)
      case StmtId.tryStmt:      return JsTryStmt(s, stmt, inClosure)
      case StmtId.switchStmt:   return JsSwitchStmt(s, stmt, inClosure)
      default: throw s.err("Unknown StmtId: $stmt.id", stmt.location)
    }
  }

  Bool inClosure   // does this stmt occur inside a closure
}

**************************************************************************
** JsNoOpStmt
**************************************************************************

class JsNoOpStmt : JsStmt
{
  new make(CompilerSupport s) : super(s, false) {}
  override Void write(JsWriter out) {}
}

**************************************************************************
** JsExprStmt
**************************************************************************

class JsExprStmt : JsStmt
{
  new make(CompilerSupport s, ExprStmt stmt, Bool inClosure) : super(s, inClosure)
  {
    this.expr = JsExpr(s, stmt.expr, inClosure)
  }
  override Void write(JsWriter out)
  {
    expr.write(out)
  }
  JsExpr expr
}

**************************************************************************
** JsLocalDefStmt
**************************************************************************

class JsLocalDefStmt : JsStmt
{
  new make(CompilerSupport s, LocalDefStmt lds, Bool inClosure) : super(s, inClosure)
  {
    this.name = lds.name
    this.init = (lds.init != null) ? JsExpr(s, lds.init, inClosure) : null
  }
  override Void write(JsWriter out)
  {
    out.w("var ")
    if (init == null) out.w(name)
    else init.write(out)
  }
  Str name
  JsExpr? init
}

**************************************************************************
** JsIfStmt
**************************************************************************

class JsIfStmt : JsStmt
{
  new make(CompilerSupport s, IfStmt fs, Bool inClosure) : super(s, inClosure)
  {
    this.cond = JsExpr(s, fs.condition, inClosure)
    this.trueBlock  = JsBlock(s, fs.trueBlock, inClosure)
    if (fs.falseBlock != null)
    {
      this.falseBlock = JsBlock(s, fs.falseBlock, inClosure)
      this.hasElseIf  = fs.falseBlock.stmts.first is IfStmt
    }
  }

  override Void write(JsWriter out)
  {
    out.w("if ("); cond.write(out); out.w(")").nl
    out.w("{").nl
    out.indent
    trueBlock.write(out)
    out.unindent
    out.w("}").nl
    if (falseBlock != null)
    {
      if (hasElseIf)
      {
        out.w("else ")
        falseBlock.write(out)
      }
      else
      {
        out.w("else").nl
        out.w("{").nl
        out.indent
        falseBlock.write(out)
        out.unindent
        out.w("}").nl
      }
    }
  }

  JsExpr cond
  JsBlock trueBlock
  JsBlock? falseBlock
  Bool hasElseIf := false
}

**************************************************************************
** JsReturnStmt
**************************************************************************

class JsReturnStmt : JsStmt
{
  new make(CompilerSupport s, ReturnStmt rs, Bool inClosure) : super(s, inClosure)
  {
    expr = (rs.expr != null) ? JsExpr(s, rs.expr, inClosure) : null
  }
  override Void write(JsWriter out)
  {
    out.w("return")
    if (expr != null)
    {
      out.w(" ")
      expr.write(out)
    }
  }
  JsExpr? expr
}

**************************************************************************
** JsThrowStmt
**************************************************************************

class JsThrowStmt : JsStmt
{
  new make(CompilerSupport s, ThrowStmt ts, Bool inClosure) : super(s, inClosure)
  {
    this.expr = JsExpr(s, ts.exception, inClosure)
  }
  override Void write(JsWriter out)
  {
    out.w("throw ")
    expr.write(out)
  }
  JsExpr? expr
}

**************************************************************************
** JsForStmt
**************************************************************************

class JsForStmt : JsStmt
{
  new make(CompilerSupport s, ForStmt fs, Bool inClosure) : super(s, inClosure)
  {
    this.init   = (fs.init != null) ? JsStmt.makeFor(s, fs.init, inClosure) : null
    this.cond   = (fs.condition != null) ? JsExpr(s, fs.condition, inClosure) : null
    this.update = (fs.update != null) ? JsExpr(s, fs.update, inClosure) : null
    this.block  = (fs.block != null) ? JsBlock(s, fs.block, inClosure) : null
  }

  override Void write(JsWriter out)
  {
    out.w("for ("); init?.write(out); out.w("; ")
      cond?.write(out); out.w("; ")
      update?.write(out); out.w(")").nl
    out.w("{").nl
    out.indent
    block?.write(out)
    out.unindent
    out.w("}").nl
  }

  JsStmt? init
  JsExpr? cond
  JsExpr? update
  JsBlock? block
}

**************************************************************************
** JsWhileStmt
**************************************************************************

class JsWhileStmt : JsStmt
{
  new make(CompilerSupport s, WhileStmt ws, Bool inClosure) : super(s, inClosure)
  {
    this.cond  = JsExpr(s, ws.condition, inClosure)
    this.block = JsBlock(s, ws.block, inClosure)
  }

  override Void write(JsWriter out)
  {
    out.w("while ("); cond.write(out); out.w(")").nl
    out.w("{").nl
    out.indent
    block.write(out)
    out.unindent
    out.w("}").nl
  }

  JsExpr cond
  JsBlock block
}

**************************************************************************
** JsBreakStmt
**************************************************************************

class JsBreakStmt : JsStmt
{
  new make(CompilerSupport s) : super(s, false) {}
  override Void write(JsWriter out) { out.w("break") }
}

**************************************************************************
** JsContinueStmt
**************************************************************************

class JsContinueStmt : JsStmt
{
  new make(CompilerSupport s) : super(s, false) {}
  override Void write(JsWriter out) { out.w("continue") }
}

**************************************************************************
** JsTryStmt
**************************************************************************

class JsTryStmt : JsStmt
{
  new make(CompilerSupport s, TryStmt ts, Bool inClosure) : super(s, inClosure)
  {
    this.block  = (ts.block != null) ? JsBlock(s, ts.block, inClosure) : null
    this.catches = ts.catches.map |c->JsCatch| { JsCatch(s, c, inClosure) }
    this.finallyBlock = (ts.finallyBlock != null) ? JsBlock(s, ts.finallyBlock, inClosure) : null
  }

  override Void write(JsWriter out)
  {
    out.w("try").nl
    out.w("{").nl
    out.indent
    block?.write(out)
    out.unindent
    out.w("}").nl

    if (!catches.isEmpty) writeCatches(out)

    if (finallyBlock != null)
    {
      out.w("finally").nl
      out.w("{").nl
      out.indent
      finallyBlock.write(out)
      out.unindent
      out.w("}").nl
    }
  }

  private Void writeCatches(JsWriter out)
  {
    var := unique
    hasTyped    := catches.any |c| { c.qname != null }
    hasCatchAll := catches.any |c| { c.qname == null }

    out.w("catch ($var)").nl
    out.w("{").nl
    out.indent
    if (hasTyped) out.w("$var = fan.sys.Err.make($var);").nl

    doElse := false
    catches.each |c|
    {
      if (c.qname != null)
      {
        if (doElse) out.w("else ")
        else doElse = true

        out.w("if ($var instanceof $c.qname)").nl
        out.w("{").nl
        out.indent
        out.w("var $c.var = $var;").nl
        c.write(out)
        out.unindent
        out.w("}").nl
      }
      else
      {
        hasElse := catches.size > 1
        if (hasElse)
        {
          out.w("else").nl
          out.w("{").nl
          out.indent
        }
        c.write(out)
        if (hasElse)
        {
          out.unindent
          out.w("}").nl
        }
      }
    }

    if (!hasCatchAll)
    {
      out.w("else").nl
      out.w("{").nl
      out.indent
      out.w("throw $var;").nl
      out.unindent
      out.w("}").nl
    }
    out.unindent
    out.w("}").nl
  }

  JsBlock? block         // try block
  JsCatch[] catches      // catch blocks
  JsBlock? finallyBlock  // finally block
}

**************************************************************************
** JsCatch
**************************************************************************

class JsCatch : JsNode
{
  new make(CompilerSupport s, Catch c, Bool inClosure) : super(s)
  {
    this.var   = c.errVariable ?: unique
    this.qname = (c.errType != null) ? qnameToJs(c.errType) : null
    this.block = (c.block != null) ? JsBlock(s, c.block, inClosure) : null
  }
  override Void write(JsWriter out)
  {
    block?.write(out)
  }
  Str var          // name of expection variable
  Str? qname       // qname of err type
  JsBlock? block   // catch block
}

**************************************************************************
** JsSwitchStmt
**************************************************************************

class JsSwitchStmt : JsStmt
{
  new make(CompilerSupport s, SwitchStmt ss, Bool inClosure) : super(s, inClosure)
  {
    this.cond  = JsExpr(s, ss.condition, inClosure)
    this.cases = ss.cases.map |c->JsCase| { JsCase(s, c, inClosure) }
    this.defBlock = (ss.defaultBlock != null) ? JsBlock(s, ss.defaultBlock, inClosure) : null
  }

  override Void write(JsWriter out)
  {
    var := unique
    out.w("var $var = "); cond.write(out); out.w(";").nl
    cases.each |c, i|
    {
      if (i > 0) out.w("else ")
      out.w("if (")
      c.cases.each |e, j|
      {
        if (j > 0) out.w(" || ")
        out.w("fan.sys.Obj.equals($var,"); e.write(out); out.w(")")
      }
      out.w(")").nl
      out.w("{").nl
      out.indent
      c.block?.write(out)
      out.unindent
      out.w("}").nl
    }
    if (defBlock != null)
    {
      if (!cases.isEmpty)
      {
        out.w("else").nl
        out.w("{").nl
        out.indent
        defBlock.write(out)
        out.unindent
        out.w("}").nl
      }
      else { defBlock.write(out) }
    }
  }

  JsExpr cond         // switch condition
  JsCase[] cases      // case stmts
  JsBlock? defBlock   // default case

}

**************************************************************************
** JsCase
**************************************************************************

class JsCase : JsNode
{
  new make(CompilerSupport s, Case c, Bool inClosure) : super(s)
  {
    this.cases = c.cases.map |ex->JsExpr| { JsExpr(s, ex, inClosure) }
    this.block = (c.block != null) ? JsBlock(s, c.block, inClosure) : null
  }
  override Void write(JsWriter out)
  {
    block?.write(out)
  }
  JsExpr[] cases
  JsBlock? block
}

