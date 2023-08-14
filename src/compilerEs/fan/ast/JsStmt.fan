//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsStmt
**
class JsStmt : JsNode
{
  new make(CompileEsPlugin plugin, Stmt stmt) : super(plugin, stmt)
  {
  }

  override Stmt? node() { super.node }
  Stmt stmt() { this.node }

  override Void write()
  {
    switch (stmt.id)
    {
      case StmtId.nop:          return
      case StmtId.expr:         writeExprStmt(stmt)
      case StmtId.localDef:     writeLocalDefStmt(stmt)
      case StmtId.ifStmt:       writeIfStmt(stmt)
      case StmtId.returnStmt:   writeReturnStmt(stmt)
      case StmtId.throwStmt:    writeThrowStmt(stmt)
      case StmtId.forStmt:      writeForStmt(stmt)
      case StmtId.whileStmt:    writeWhileStmt(stmt)
      case StmtId.breakStmt:    js.w("break")
      case StmtId.continueStmt: js.w("continue")
      case StmtId.tryStmt:      writeTryStmt(stmt)
      case StmtId.switchStmt:   writeSwitchStmt(stmt)
      default:
        stmt.print(AstWriter())
        throw err("Unknown StmtId: ${stmt.id} ${stmt.typeof}", stmt.loc)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Expr
//////////////////////////////////////////////////////////////////////////

  private Void writeExprStmt(ExprStmt stmt)
  {
    writeExpr(stmt.expr)
  }

//////////////////////////////////////////////////////////////////////////
// LocalDef
//////////////////////////////////////////////////////////////////////////

  private Void writeLocalDefStmt(LocalDefStmt stmt)
  {
    // don't write def for catch vars since we handle that ourselves in writeCatches()
    if (stmt.isCatchVar) return

    js.w("let ", loc)
    if (stmt.init == null) js.w(stmt.name, loc)
    else
    {
      JsExpr(plugin, stmt.init) { it.isLocalDefStmt = true }.write
    }
  }

//////////////////////////////////////////////////////////////////////////
// If
//////////////////////////////////////////////////////////////////////////

  private Void writeIfStmt(IfStmt stmt)
  {
    js.w("if ("); writeExpr(stmt.condition); js.wl(") {")
    js.indent
    writeBlock(stmt.trueBlock)
    js.unindent.wl("}")
    if (stmt.falseBlock != null)
    {
      js.wl("else {")
      js.indent
      writeBlock(stmt.falseBlock)
      js.unindent.wl("}")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Return
//////////////////////////////////////////////////////////////////////////

  private Void writeReturnStmt(ReturnStmt stmt)
  {
    js.w("return", loc)
    if (stmt.expr != null)
    {
      js.w(" ")
      writeExpr(stmt.expr)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Throw
//////////////////////////////////////////////////////////////////////////

  private Void writeThrowStmt(ThrowStmt ts)
  {
    js.w("throw ")
    writeExpr(ts.exception)
  }

//////////////////////////////////////////////////////////////////////////
// For
//////////////////////////////////////////////////////////////////////////

  private Void writeForStmt(ForStmt fs)
  {
    js.w("for ("); writeStmt(fs.init); js.w("; ")
      writeExpr(fs.condition); js.w("; ")
      writeExpr(fs.update); js.wl(") {").indent
    writeBlock(fs.block)
    js.unindent.wl("}")
  }

//////////////////////////////////////////////////////////////////////////
// While
//////////////////////////////////////////////////////////////////////////

  private Void writeWhileStmt(WhileStmt ws)
  {
    js.w("while ("); writeExpr(ws.condition); js.wl(") {").indent
    writeBlock(ws.block)
    js.unindent.wl("}")
  }

//////////////////////////////////////////////////////////////////////////
// Try
//////////////////////////////////////////////////////////////////////////

  private Void writeTryStmt(TryStmt ts)
  {
    js.wl("try {").indent
    writeBlock(ts.block)
    js.unindent.wl("}")

    writeCatches(ts.catches)

    if (ts.finallyBlock != null)
    {
      js.wl("finally {").indent
      writeBlock(ts.finallyBlock)
      js.unindent.wl("}")
    }
  }

  private Void writeCatches(Catch[] catches)
  {
    if (catches.isEmpty) return

    var := uniqName
    hasTyped    := catches.any |c| { c.errType != null }
    hasCatchAll := catches.any |c| { c.errType == null }

    js.wl("catch (${var}) {").indent
    if (hasTyped) js.wl("${var} = sys.Err.make(${var});")

    doElse := false
    catches.each |c|
    {
      if (c.errType != null)
      {
        qname := qnameToJs(c.errType)
        cVar  := c.errVariable ?: uniqName
        if (doElse) js.w("else ")
        else doElse = true

        js.wl("if (${var} instanceof ${qname}) {").indent
        js.wl("let ${cVar} = ${var};")
        writeBlock(c.block)
        js.unindent.wl("}")
      }
      else
      {
        hasElse := catches.size > 1
        if (hasElse) js.wl("else {").indent
        writeBlock(c.block)
        if (hasElse) js.unindent.wl("}")
      }
    }

    if (!hasCatchAll)
    {
      js.wl("else {").indent
      js.wl("throw ${var};")
      js.unindent.wl("}")
    }

    js.unindent.wl("}")
  }

//////////////////////////////////////////////////////////////////////////
// Switch
//////////////////////////////////////////////////////////////////////////

  private Void writeSwitchStmt(SwitchStmt ss)
  {
    var := uniqName
    js.w("let ${var} = "); writeExpr(ss.condition); js.wl(";")

    ss.cases.each |c, i|
    {
      if (i > 0) js.w("else ")
      js.w("if (")
      c.cases.each |e, j|
      {
        if (j > 0) js.w(" || ")
        js.w("sys.ObjUtil.equals(${var}, "); writeExpr(e); js.w(")")
      }
      js.wl(") {").indent
      writeBlock(c.block)
      js.unindent.wl("}")
    }

    if (ss.defaultBlock != null)
    {
      if (!ss.cases.isEmpty)
      {
        js.wl("else {").indent
        writeBlock(ss.defaultBlock)
        js.unindent.wl("}")

      }
      else writeBlock(ss.defaultBlock)
    }
  }
}