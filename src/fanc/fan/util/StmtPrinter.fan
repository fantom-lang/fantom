//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split out from CodePrinter
//

using build
using compiler
using util

**
** CodePrinter routing for Stmt nodes
**
mixin StmtPrinter : CodePrinter
{
  virtual This block(Block x)
  {
    x.stmts.each |s| { stmt(s) }
    return this
  }

  virtual This stmt(Stmt x)
  {
    if  (!m.exprStack.isEmpty) throw Err(m.exprStack.toStr)
    switch (x.id)
    {
      case StmtId.expr:         return exprStmt(x)
      case StmtId.localDef:     return localDefStmt(x)
      case StmtId.ifStmt:       return ifStmt(x)
      case StmtId.returnStmt:   return returnStmt(x)
      case StmtId.throwStmt:    return throwStmt(x)
      case StmtId.tryStmt:      return tryStmt(x)
      case StmtId.forStmt:      return forStmt(x)
      case StmtId.whileStmt:    return whileStmt(x)
      case StmtId.breakStmt:    return breakStmt(x)
      case StmtId.continueStmt: return continueStmt(x)
      case StmtId.switchStmt:   return switchStmt(x)
      default: throw Err(x.id.toStr)
    }
  }

  abstract This exprStmt(ExprStmt x)

  abstract This localDefStmt(LocalDefStmt x)

  abstract This ifStmt(IfStmt x)

  abstract This returnStmt(ReturnStmt x)

  abstract This throwStmt(ThrowStmt x)

  abstract This tryStmt(TryStmt x)

  abstract This forStmt(ForStmt x)

  abstract This whileStmt(WhileStmt x)

  abstract This breakStmt(BreakStmt x)

  abstract This continueStmt(ContinueStmt x)

  abstract This switchStmt(SwitchStmt x)

}

