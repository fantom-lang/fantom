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
      if (x.expr != null && x.expr.isStmt) sp.expr(x.expr).w("; ")
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

      var := c.errVariable
      if (var == null)
      {
        w("catch (Throwable ignore) {").nl
      }
      else if (c.errType.qname == "sys::Err")
      {
        w("catch (Throwable").sp.varName(var).w("\$)").sp.w("{").nl
        w("  ").typeSig(c.errType).sp.varName(var).w(" = fan.sys.Err.make(").w(var).w("\$)").eos
      }
      else
      {
        w("catch (").typeSig(c.errType).sp.varName(var).w(") {").nl
      }
      indent
      c.block.stmts.each |s| { stmt(s) }
      unindent
      w("}").nl
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
    type := toSwitchType(x)
    if (type == "empty") return emptySwitch(x)
    if (type == "ifElse") return ifElseSwitch(x)
    return javaSwitch(x, type)
  }

  private Str? toSwitchType(SwitchStmt x)
  {
    types := Str:Str[:]
    x.cases.each |c|
    {
      c.cases.each |e|
      {
        type := toJavaSwitchCaseType(e) ?: "ifElse"
        types[type] = type
      }
    }
    if (types.isEmpty) return "empty"
    if (types.size == 1) return types.keys.first
    return "ifElse"
  }

  private This emptySwitch(SwitchStmt x)
  {
    block(x.defaultBlock).nl
  }

  private This ifElseSwitch(SwitchStmt x)
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
    return this
  }

  private This javaSwitch(SwitchStmt x, Str type)
  {
    w("switch(").javaSwitchCondition(x.condition, type).w(") {").nl
    indent
    x.cases.each |c|
    {
      c.cases.each |caseExpr|
      {
        w("case ").javaSwitchCase(caseExpr).w(": ").nl
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

  private This javaSwitchCondition(Expr x, Str type)
  {
    if (type == "int")
    {
      if (x.ctype.isNullable) return w("((Long)").expr(x).w(").intValue()")
      return w("(int)(").expr(x).w(")")
    }
    else if (type == "enum")
    {
      return w("(int)(").expr(x).w(").ordinal()")
    }
    else if (x.ctype.isStr)
    {
      return expr(x)
    }
    else
    {
      return qnFanObj.w(".toStr(").expr(x).w(")")
    }
  }

  private Str? toJavaSwitchCaseType(Expr x)
  {
    if (x.id === ExprId.intLiteral || isNegInt(x)) return "int"
    if (x.id === ExprId.strLiteral) return "str"
    if (x.id === ExprId.field && ((FieldExpr)x).field.isEnum) return "enum"
    return null
  }

  private This javaSwitchCase(Expr x)
  {
    if (x.id === ExprId.intLiteral) return w(((LiteralExpr)x).val)
    if (x.id === ExprId.strLiteral) return str(((LiteralExpr)x).val)
    if (isNegInt(x)) return w(x.toStr)
    if (x.id === ExprId.field)
    {
      f := ((FieldExpr)x).field
      return typeSig(f.parent).w(".").w(f.name.upper)
    }
    warn("Cannot generate java case: $x", x.loc)
    return expr(x)
  }

  private Bool isNegInt(Expr x)
  {
    if (x.id !== ExprId.shortcut) return false
    sc := (ShortcutExpr)x
    return sc.args.isEmpty && sc.target.id === ExprId.intLiteral
  }

  private This switchBlock(Block? b)
  {
    if (b == null) return this
    indent
    b.stmts.each |s| { stmt(s) }
    if (switchNeedBreak(b)) w("break").eos
    unindent
    return this
  }

  private Bool switchNeedBreak(Block b)
  {
    if (b.isExit) return false
    last := b.stmts.last
    if (last.id == StmtId.continueStmt) return false
    if (last.id == StmtId.breakStmt) warn("Switch block cannot use break", b.loc)
    return true
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

