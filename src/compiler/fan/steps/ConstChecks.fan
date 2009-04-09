//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Apr 09  Brian Frank  Creation
//

**
** ConstChecks adds hooks into constructors and it-blocks
** to ensure that an attempt to set a const field will throw
** ConstErr if not in the objects constructor.
**
** For each it-block which sets const fields:
**
**   doCall(Foo it)
**   {
**     this.checkInCtor(it)
**     ...
**   }
**
** For each constructor which takes an it-block:
**
**   new make(..., |This| f)
**   {
**     f?.enterCtor(this)
**     ...
**     f?.exitCtor()  // for every return
**     return
**   }
**
**
class ConstChecks : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("ConstChecks")

    // walk all the closures
    compiler.closures.each |ClosureExpr c| { processClosure(c) }

    // walk all the constructors
    types.each |TypeDef t|
    {
      t.ctorDefs.each |MethodDef ctor| { processCtor(ctor) }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Process Closure
//////////////////////////////////////////////////////////////////////////

  private Void processClosure(ClosureExpr c)
  {
    // don't process anything but it-blocks which use const fields
    if (!c.isItBlock || !c.setsConst) return

    // add inCtor check
    loc := c.location
    check := CallExpr.makeWithMethod(loc, ThisExpr(loc), ns.funcCheckInCtor, [ItExpr(loc)])
    check.noLeave
    c.doCall.code.stmts.insert(0, check.toStmt)
  }

//////////////////////////////////////////////////////////////////////////
// Process Constructor
//////////////////////////////////////////////////////////////////////////

  private Void processCtor(MethodDef ctor)
  {
    // only process constructors with an it-block as last arg
    if (ctor.params.isEmpty) return
    lastArg := ctor.params.last.paramType.deref.toNonNullable as FuncType
    if (lastArg == null || lastArg.params.size != 1) return
    this.curCtor = ctor

    // add enterCtor
    loc := ctor.location
    enter := CallExpr.makeWithMethod(loc, LocalVarExpr(loc, itBlockVar), ns.funcEnterCtor, [ThisExpr(loc)])
    enter.isSafe = true
    enter.noLeave
    ctor.code.stmts.insert(0, enter.toStmt)

    // walk all the statements and insert exitCtor before each return
    ctor.code.walk(this, VisitDepth.stmt)
  }

  override Stmt[]? visitStmt(Stmt stmt)
  {
    if (stmt.id !== StmtId.returnStmt) return null
    loc := stmt.location
    exit := CallExpr.makeWithMethod(loc, LocalVarExpr(loc, itBlockVar), ns.funcExitCtor)
    exit.isSafe = true
    exit.noLeave
    return [exit.toStmt, stmt]
  }

  private MethodVar itBlockVar() { curCtor.vars[curCtor.params.size-1] }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  MethodDef? curCtor
}