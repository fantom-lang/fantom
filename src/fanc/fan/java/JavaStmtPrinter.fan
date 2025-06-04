//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split from JavaPrinter
//

using compiler

**
** Java transpiler printer for stmts
**
internal class JavaStmtPrinter : JavaPrinter, StmtPrinter
{
  new make(JavaPrinter parent) : super(parent) {}

  override JavaPrinterState m() { super.m }

//////////////////////////////////////////////////////////////////////////
// StmtPrinter
//////////////////////////////////////////////////////////////////////////

  override This exprStmt(ExprStmt x)
  {
    expr(x.expr).eos
  }

  override This localDefStmt(LocalDefStmt x)
  {
    doLocalDefStmt(x).eos
  }

  private This doLocalDefStmt(LocalDefStmt x)
  {
    typeSig(x.ctype).sp.varName(x.name)
    if (x.init != null) w(" = ").expr(x.initVal)
    return this
  }

  override This ifStmt(IfStmt x)
  {
    w("if (").expr(x.condition).w(") ")
    block(x.trueBlock)
    if (x.falseBlock != null) w(" else ").block(x.falseBlock)
    return nl
  }

  override This returnStmt(ReturnStmt x)
  {
    if (curMethod.isStaticInit) return this

    if (curMethod.returns.isVoid)
    {
      // in fantom we allow return of anything in void
      if (x.expr != null) sp.expr(x.expr).w("; ")
      return w("return").eos
    }
    else
    {
      // normal return
      w("return")
      if (x.expr != null) sp.expr(x.expr)
      return eos
    }
  }

  override This throwStmt(ThrowStmt x)
  {
    w("throw ").expr(x.exception).eos
  }

  override This tryStmt(TryStmt x)
  {
    w("try").sp
    block(x.block).nl
    x.catches.each |c|
    {
      // remove first stmt which redeclares local var
      first := c.block.stmts.first as LocalDefStmt
      if (first != null && first.isCatchVar)
        c.block.stmts.removeAt(0)

      if (c.errVariable == null)
        w("catch (Throwable ignore)").sp
      else
        w("catch (").typeSig(c.errType).w(" ").varName(c.errVariable).w(")").sp
      block(c.block).nl
    }
    if (x.finallyBlock != null)
    {
      w("finally").sp
      block(x.finallyBlock).nl
    }
    return this
  }

  override This forStmt(ForStmt x)
  {
    w("for (")
    if (x.init != null)
    {
      // can only be expr or local
      switch (x.init.id)
      {
        case StmtId.expr:      expr(((ExprStmt)x.init).expr)
        case StmtId.localDef:  doLocalDefStmt(x.init)
        default:               throw Err(x.init.toStr)
      }
    }
    w("; ")
    if (x.condition != null) expr(x.condition)
    w("; ")
    if (x.update != null) expr(x.update)
    w(")").sp
    block(x.block)
    return nl
  }

  override This whileStmt(WhileStmt x)
  {
    w("while (").expr(x.condition).w(") ").block(x.block).nl
  }

  override This breakStmt(BreakStmt x)
  {
    w("break").eos
  }

  override This continueStmt(ContinueStmt x)
  {
    w("continue").eos
  }

  override This block(Block x)
  {
    if (x.isEmpty) return w("{}")
    w("{").nl
    indent
    x.stmts.each |s| { stmt(s) }
    unindent
    w("}")
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Switch
//////////////////////////////////////////////////////////////////////////

  override This switchStmt(SwitchStmt x)
  {
    if (isJavaSwitch(x))
      javaSwitch(x)
    else
      ifElseSwitch(x)
    return this
  }

  private Bool isJavaSwitch(SwitchStmt x)
  {
    x.cases.all |c|
    {
      c.cases.all |e| { isJavaSwitchCase(e) }
    }
  }

  private Void javaSwitch(SwitchStmt x)
  {
    w("switch(").switchCondition(x.condition).w(") {").nl
    indent
    x.cases.each |c|
    {
      c.cases.each |caseExpr|
      {
        w("case ").caseCondition(caseExpr).w(": ").nl
      }
      switchBlock(c.block)
    }
    if (x.defaultBlock != null)
    {
      w("default:").nl
      switchBlock(x.defaultBlock)
    }
    unindent
    w("}").nl
    return this
  }

  private Void ifElseSwitch(SwitchStmt x)
  {
    condVar := curMethod.transpileTempVar
    cond := x.condition
    typeSig(cond.ctype).sp.w(condVar).w(" = ").expr(cond).eos
    x.cases.each |c, i|
    {
      if (i > 0) w("else ")
      w(" if (")
      c.cases.each |caseExpr, j|
      {
        if  (j > 0) w(" || ")
        qnOpUtil.w(".compareEQ(").w(condVar).w(", ").expr(caseExpr).w(")")
      }
      w(")")
      if (c.block == null) w(" {}").nl
      else block(c.block)
      nl
    }
    if (x.defaultBlock != null)
    {
      w("else ").block(x.defaultBlock).nl
    }
  }

  private This switchCondition(Expr x)
  {
    if (x.ctype.isInt)
    {
      if (x.ctype.isNullable) return w("((Long)").expr(x).w(").intValue()")
      w("(int)")
    }
    else if (x.ctype.isEnum)
    {
      return w("(int)").expr(x).w(".ordinal()")
    }
    return expr(x)
  }

  private Bool isJavaSwitchCase(Expr x)
  {
    if (x.id === ExprId.intLiteral) return true
    if (x.id === ExprId.strLiteral) return true
    if (x.id === ExprId.field) return ((FieldExpr)x).field.isEnum
    return false
  }

  private This caseCondition(Expr x)
  {
    if (x.id === ExprId.intLiteral) return w(((LiteralExpr)x).val)
    if (x.id === ExprId.strLiteral) return str(((LiteralExpr)x).val)
    if (x.id === ExprId.field)
    {
      f := ((FieldExpr)x).field
      return typeSig(f.parent).w(".").w(f.name.upper)
    }
    throw Err("TODO: $x.id $x")
  }

  private This switchBlock(Block? b)
  {
    if (b == null) return this
    indent
    b.stmts.each |s| { stmt(s) }
    if (!b.isExit) w("break").eos
    unindent
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  This expr(Expr expr)
  {
    JavaExprPrinter(this).expr(expr)
    return this
  }

}

