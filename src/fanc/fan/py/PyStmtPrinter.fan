//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2026  Trevor Adelman  Creation
//

using compiler

**
** Python statement printer
**
class PyStmtPrinter : PyPrinter
{
  new make(PyPrinter parent) : super.make(parent.m.out)
  {
    this.m = parent.m
    this.exprPrinter = PyExprPrinter(this)
  }

  private PyExprPrinter exprPrinter

  ** Print an expression
  Void expr(Expr e) { exprPrinter.expr(e) }

  ** Print a statement
  Void stmt(Stmt s)
  {
    // Check if we need to emit closures before this statement
    emitPendingClosuresForStatement()

    switch (s.id)
    {
      case StmtId.nop:          return  // no-op
      case StmtId.expr:         exprStmt(s)
      case StmtId.localDef:     localDef(s)
      case StmtId.ifStmt:       ifStmt(s)
      case StmtId.returnStmt:   returnStmt(s)
      case StmtId.throwStmt:    throwStmt(s)
      case StmtId.forStmt:      forStmt(s)
      case StmtId.whileStmt:    whileStmt(s)
      case StmtId.breakStmt:    w("break").eos
      case StmtId.continueStmt: continueStmt()
      case StmtId.tryStmt:      tryStmt(s)
      case StmtId.switchStmt:   switchStmt(s)
      default:
        w("# TODO: stmt ${s.id}").eos
    }
  }

//////////////////////////////////////////////////////////////////////////
// Method-Level Closure Scanning
//////////////////////////////////////////////////////////////////////////

  ** Scan entire method body for multi-statement closures
  ** Also pre-scans for Wrap$ definitions so nonlocal names are known before closures emit
  Void scanMethodForClosures(Block b)
  {
    // Pre-scan: find ALL Wrap$ definitions in the method body (recursively)
    // This must happen first so that when closures are emitted, getNonlocalNames()
    // returns all nonlocal variables -- including ones defined after the closure
    scanBlockForNonlocals(b)

    // Use index to track statement location
    b.stmts.each |s, idx|
    {
      m.stmtIndex = idx
      scanStmt(s)
    }
  }

  ** Recursively scan a block for Wrap$ wrapper definitions
  ** Records all nonlocal variable mappings before any closures are emitted
  private Void scanBlockForNonlocals(Block b)
  {
    b.stmts.each |s| { scanStmtForNonlocals(s) }
  }

  ** Scan a statement for Wrap$ definitions (and recurse into nested blocks)
  private Void scanStmtForNonlocals(Stmt s)
  {
    switch (s.id)
    {
      case StmtId.localDef:
        localDef := s as LocalDefStmt
        prescanNonlocal(localDef)
      case StmtId.ifStmt:
        ifStmt := s as IfStmt
        scanBlockForNonlocals(ifStmt.trueBlock)
        if (ifStmt.falseBlock != null)
          scanBlockForNonlocals(ifStmt.falseBlock)
      case StmtId.whileStmt:
        whileStmt := s as WhileStmt
        scanBlockForNonlocals(whileStmt.block)
      case StmtId.forStmt:
        forStmt := s as ForStmt
        if (forStmt.init != null) scanStmtForNonlocals(forStmt.init)
        if (forStmt.block != null)
          scanBlockForNonlocals(forStmt.block)
      case StmtId.tryStmt:
        tryStmt := s as TryStmt
        scanBlockForNonlocals(tryStmt.block)
        tryStmt.catches.each |c| { scanBlockForNonlocals(c.block) }
        if (tryStmt.finallyBlock != null)
          scanBlockForNonlocals(tryStmt.finallyBlock)
      case StmtId.switchStmt:
        switchStmt := s as SwitchStmt
        switchStmt.cases.each |c| { scanBlockForNonlocals(c.block) }
        if (switchStmt.defaultBlock != null)
          scanBlockForNonlocals(switchStmt.defaultBlock)
    }
  }

  ** Pre-scan a localDef statement for Wrap$.make() pattern (same logic as detectAndRecordNonlocal)
  private Void prescanNonlocal(LocalDefStmt s)
  {
    if (s.init == null) return

    // Unwrap coerces and assignments
    initExpr := s.init
    while (initExpr.id == ExprId.coerce)
    {
      tc := initExpr as TypeCheckExpr
      initExpr = tc.target
    }
    if (initExpr.id == ExprId.assign)
    {
      assign := initExpr as BinaryExpr
      initExpr = assign.rhs
      while (initExpr.id == ExprId.coerce)
      {
        tc := initExpr as TypeCheckExpr
        initExpr = tc.target
      }
    }

    if (initExpr.id != ExprId.call) return

    call := initExpr as CallExpr
    if (call.method.name == "make" && call.target == null && !call.method.isStatic && call.args.size == 1)
    {
      parentType := call.method.parent
      if (parentType.isSynthetic && parentType.name.startsWith("Wrap\$"))
      {
        arg := call.args.first
        while (arg.id == ExprId.coerce)
        {
          tc := arg as TypeCheckExpr
          arg = tc.target
        }

        wrapperVarName := s.name
        if (arg.id == ExprId.localVar)
        {
          localArg := arg as LocalVarExpr
          m.recordNonlocal(wrapperVarName, localArg.var.name)
        }
        else
        {
          m.recordNonlocal(wrapperVarName, wrapperVarName)
        }
      }
    }
  }

  ** Recursively scan a statement for closure expressions
  private Void scanStmt(Stmt s)
  {
    switch (s.id)
    {
      case StmtId.expr:
        exprStmt := s as ExprStmt
        scanExprForClosures(exprStmt.expr)
      case StmtId.localDef:
        localDef := s as LocalDefStmt
        if (localDef.init != null)
          scanExprForClosures(localDef.init)
      case StmtId.ifStmt:
        ifStmt := s as IfStmt
        scanExprForClosures(ifStmt.condition)
        scanInnerBlockForClosures(ifStmt.trueBlock)
        if (ifStmt.falseBlock != null)
          scanInnerBlockForClosures(ifStmt.falseBlock)
      case StmtId.returnStmt:
        ret := s as ReturnStmt
        if (ret.expr != null)
          scanExprForClosures(ret.expr)
      case StmtId.throwStmt:
        throwStmt := s as ThrowStmt
        scanExprForClosures(throwStmt.exception)
      case StmtId.whileStmt:
        whileStmt := s as WhileStmt
        scanExprForClosures(whileStmt.condition)
        scanInnerBlockForClosures(whileStmt.block)
      case StmtId.forStmt:
        forStmt := s as ForStmt
        if (forStmt.init != null) scanStmt(forStmt.init)
        if (forStmt.condition != null) scanExprForClosures(forStmt.condition)
        if (forStmt.update != null) scanExprForClosures(forStmt.update)
        if (forStmt.block != null) scanInnerBlockForClosures(forStmt.block)
      case StmtId.tryStmt:
        tryStmt := s as TryStmt
        scanInnerBlockForClosures(tryStmt.block)
        tryStmt.catches.each |c| { scanInnerBlockForClosures(c.block) }
        if (tryStmt.finallyBlock != null)
          scanInnerBlockForClosures(tryStmt.finallyBlock)
      case StmtId.switchStmt:
        switchStmt := s as SwitchStmt
        scanExprForClosures(switchStmt.condition)
        switchStmt.cases.each |c| { scanInnerBlockForClosures(c.block) }
        if (switchStmt.defaultBlock != null)
          scanInnerBlockForClosures(switchStmt.defaultBlock)
    }
  }

  ** Scan inner block (don't increment method stmtIndex)
  private Void scanInnerBlockForClosures(Block b)
  {
    b.stmts.each |s| { scanStmt(s) }
  }

  ** Recursively scan an expression for closures
  private Void scanExprForClosures(Expr e)
  {
    // Check if this is a closure that needs extraction
    if (e.id == ExprId.closure)
    {
      ce := e as ClosureExpr
      if (isMultiStatementClosure(ce))
      {
        // Only register closures at method level (depth == 0)
        // Nested closures (depth > 0) will be emitted inside their parent closure.
        // If a closure has nested multi-statement closures, isMultiStatementClosure
        // returns true, so the parent will be extracted and nested defs can be
        // properly emitted inside it.
        if (m.closureDepth == 0)
        {
          // Find existing or register new closure
          closureId := m.findClosureId(ce)
          if (closureId == null)
          {
            closureId = m.nextClosureId
            m.pendingClosures.add([ce, closureId])
            m.registeredClosures.add([ce, closureId])
          }

          // Record first usage location if not already recorded
          if (!m.closureFirstUse.containsKey(closureId))
          {
            m.closureFirstUse[closureId] = m.stmtIndex
          }
        }
      }
    }

    // Recursively scan child expressions
    scanExprChildren(e)
  }

  ** Scan children of an expression
  private Void scanExprChildren(Expr e)
  {
    switch (e.id)
    {
      case ExprId.call:
        ce := e as CallExpr
        if (ce.target != null) scanExprForClosures(ce.target)
        ce.args.each |arg| { scanExprForClosures(arg) }
      case ExprId.construction:
        // Constructor calls - scan args for closures
        ce := e as CallExpr
        ce.args.each |arg| { scanExprForClosures(arg) }
      case ExprId.listLiteral:
        // List literals can contain closures
        le := e as ListLiteralExpr
        le.vals.each |val| { scanExprForClosures(val) }
      case ExprId.mapLiteral:
        // Map literals can contain closures in values
        me := e as MapLiteralExpr
        me.keys.each |key| { scanExprForClosures(key) }
        me.vals.each |val| { scanExprForClosures(val) }
      case ExprId.shortcut:
        se := e as ShortcutExpr
        if (se.target != null) scanExprForClosures(se.target)
        se.args.each |arg| { scanExprForClosures(arg) }
      case ExprId.ternary:
        te := e as TernaryExpr
        scanExprForClosures(te.condition)
        scanExprForClosures(te.trueExpr)
        scanExprForClosures(te.falseExpr)
      case ExprId.boolOr:
        co := e as CondExpr
        co.operands.each |op| { scanExprForClosures(op) }
      case ExprId.boolAnd:
        ca := e as CondExpr
        ca.operands.each |op| { scanExprForClosures(op) }
      case ExprId.coerce:
        tc := e as TypeCheckExpr
        scanExprForClosures(tc.target)
      case ExprId.assign:
        be := e as BinaryExpr
        scanExprForClosures(be.lhs)
        scanExprForClosures(be.rhs)
      case ExprId.elvis:
        ee := e as BinaryExpr
        scanExprForClosures(ee.lhs)
        scanExprForClosures(ee.rhs)
      case ExprId.field:
        // Field expressions can have targets that contain closures
        // e.g., ActorPool() { maxThreads = 2 }.maxThreads
        fe := e as FieldExpr
        if (fe.target != null) scanExprForClosures(fe.target)
      case ExprId.closure:
        // Scan INSIDE the closure body for nested closures
        // Increment depth so nested closures won't be registered at method level
        cl := e as ClosureExpr
        Block? codeBlock := null
        if (cl.doCall != null && cl.doCall.code != null)
          codeBlock = cl.doCall.code
        else if (cl.call != null && cl.call.code != null)
          codeBlock = cl.call.code
        else if (cl.code != null)
          codeBlock = cl.code
        if (codeBlock != null)
        {
          m.closureDepth++
          scanInnerBlockForClosures(codeBlock)
          m.closureDepth--
        }
      // localVar, literals etc have no children with closures
    }
  }

  ** Scan a closure body for nested multi-statement closures and register them
  ** This allows nested closures to be emitted as defs before being used
  private Void scanClosureBodyForNestedClosures(ClosureExpr ce)
  {
    codeBlock := ce.doCall?.code ?: ce.code
    if (codeBlock == null) return

    // Scan each statement, tracking index for closure emission
    codeBlock.stmts.each |s, idx|
    {
      m.stmtIndex = idx
      scanStmtForNestedClosures(s)
    }
  }

  ** Scan a statement for nested closures (registers them for emission)
  private Void scanStmtForNestedClosures(Stmt s)
  {
    switch (s.id)
    {
      case StmtId.expr:
        exprStmt := s as ExprStmt
        scanExprForNestedClosures(exprStmt.expr)
      case StmtId.localDef:
        localDef := s as LocalDefStmt
        if (localDef.init != null)
          scanExprForNestedClosures(localDef.init)
      case StmtId.returnStmt:
        ret := s as ReturnStmt
        if (ret.expr != null)
          scanExprForNestedClosures(ret.expr)
      case StmtId.ifStmt:
        ifStmt := s as IfStmt
        scanExprForNestedClosures(ifStmt.condition)
        ifStmt.trueBlock.stmts.each |st| { scanStmtForNestedClosures(st) }
        if (ifStmt.falseBlock != null)
          ifStmt.falseBlock.stmts.each |st| { scanStmtForNestedClosures(st) }
      case StmtId.whileStmt:
        whileStmt := s as WhileStmt
        scanExprForNestedClosures(whileStmt.condition)
        whileStmt.block.stmts.each |st| { scanStmtForNestedClosures(st) }
      case StmtId.forStmt:
        forStmt := s as ForStmt
        if (forStmt.init != null) scanStmtForNestedClosures(forStmt.init)
        if (forStmt.condition != null) scanExprForNestedClosures(forStmt.condition)
        if (forStmt.update != null) scanExprForNestedClosures(forStmt.update)
        if (forStmt.block != null) forStmt.block.stmts.each |st| { scanStmtForNestedClosures(st) }
    }
  }

  ** Scan an expression for nested closures (registers them)
  ** Only registers IMMEDIATE nested closures - deeper nesting will be handled
  ** recursively when each nested closure writes its own body
  private Void scanExprForNestedClosures(Expr e)
  {
    if (e.id == ExprId.closure)
    {
      ce := e as ClosureExpr
      if (isMultiStatementClosure(ce))
      {
        // Register for emission inside parent closure
        closureId := m.findClosureId(ce)
        if (closureId == null)
        {
          closureId = m.nextClosureId
          m.pendingClosures.add([ce, closureId])
          m.registeredClosures.add([ce, closureId])
        }
        if (!m.closureFirstUse.containsKey(closureId))
        {
          m.closureFirstUse[closureId] = m.stmtIndex
        }
      }

      // DON'T recursively scan inside - that will happen when writeClosure
      // processes this closure's body and calls scanClosureBodyForNestedClosures
      return
    }

    // Scan children (but not inside closures - handled above)
    scanExprChildrenForNestedClosures(e)
  }

  ** Scan children of an expression for nested closures
  private Void scanExprChildrenForNestedClosures(Expr e)
  {
    switch (e.id)
    {
      case ExprId.call:
        ce := e as CallExpr
        if (ce.target != null) scanExprForNestedClosures(ce.target)
        ce.args.each |arg| { scanExprForNestedClosures(arg) }
      case ExprId.construction:
        ce := e as CallExpr
        ce.args.each |arg| { scanExprForNestedClosures(arg) }
      case ExprId.shortcut:
        se := e as ShortcutExpr
        if (se.target != null) scanExprForNestedClosures(se.target)
        se.args.each |arg| { scanExprForNestedClosures(arg) }
      case ExprId.ternary:
        te := e as TernaryExpr
        scanExprForNestedClosures(te.condition)
        scanExprForNestedClosures(te.trueExpr)
        scanExprForNestedClosures(te.falseExpr)
      case ExprId.boolOr:
        co := e as CondExpr
        co.operands.each |op| { scanExprForNestedClosures(op) }
      case ExprId.boolAnd:
        ca := e as CondExpr
        ca.operands.each |op| { scanExprForNestedClosures(op) }
      case ExprId.coerce:
        tc := e as TypeCheckExpr
        scanExprForNestedClosures(tc.target)
      case ExprId.assign:
        be := e as BinaryExpr
        scanExprForNestedClosures(be.lhs)
        scanExprForNestedClosures(be.rhs)
      case ExprId.elvis:
        ee := e as BinaryExpr
        scanExprForNestedClosures(ee.lhs)
        scanExprForNestedClosures(ee.rhs)
    }
  }

  ** Check if a closure requires multi-statement def extraction
  private Bool isMultiStatementClosure(ClosureExpr ce)
  {
    // Check all possible code block locations (matching PyExprPrinter)
    Block? codeBlock := null
    if (ce.doCall != null && ce.doCall.code != null)
      codeBlock = ce.doCall.code
    else if (ce.call != null && ce.call.code != null)
      codeBlock = ce.call.code
    else if (ce.code != null)
      codeBlock = ce.code

    if (codeBlock == null) return false

    stmts := codeBlock.stmts

    // Check if closure has local variable declarations
    hasLocalVars := stmts.any |s| { s.id == StmtId.localDef }
    if (hasLocalVars) return true

    // Check if closure has assignments (can't be in lambda body)
    // Must unwrap coerces since assignments are often wrapped in type coercions
    hasAssign := stmts.any |s|
    {
      if (s.id == StmtId.expr)
      {
        es := s as ExprStmt
        return isAssignmentExpr(es.expr)
      }
      if (s.id == StmtId.returnStmt)
      {
        ret := s as ReturnStmt
        if (ret.expr != null)
          return isAssignmentExpr(ret.expr)
      }
      return false
    }
    if (hasAssign) return true

    // Check if closure has control flow statements that can't be in lambda body
    // These include if, switch, for, while, try - they have nested blocks
    hasControlFlow := stmts.any |s|
    {
      s.id == StmtId.ifStmt ||
      s.id == StmtId.switchStmt ||
      s.id == StmtId.forStmt ||
      s.id == StmtId.whileStmt ||
      s.id == StmtId.tryStmt
    }
    if (hasControlFlow) return true

    // Count real statements (excluding synthetic returns)
    realStmtCount := 0
    stmts.each |s|
    {
      if (s.id == StmtId.returnStmt)
      {
        ret := s as ReturnStmt
        if (ret.expr != null) realStmtCount++
      }
      else if (s.id != StmtId.nop)
      {
        realStmtCount++
      }
    }

    if (realStmtCount > 1) return true

    // Check if this closure contains any nested multi-statement closures.
    // If so, this closure must ALSO be extracted as a def so that the nested
    // closure can be properly emitted inside it (and capture variables from
    // this closure's scope). This is recursive - the containsNestedMultiStatement
    // check will propagate up the entire closure tree.
    if (containsNestedMultiStatementClosure(codeBlock)) return true

    return false
  }

  ** Recursively check if a code block contains any nested multi-statement closures
  private Bool containsNestedMultiStatementClosure(Block b)
  {
    return b.stmts.any |s| { stmtContainsNestedMultiStatementClosure(s) }
  }

  ** Check if a statement contains a nested multi-statement closure
  private Bool stmtContainsNestedMultiStatementClosure(Stmt s)
  {
    switch (s.id)
    {
      case StmtId.expr:
        exprStmt := s as ExprStmt
        return exprContainsNestedMultiStatementClosure(exprStmt.expr)
      case StmtId.localDef:
        localDef := s as LocalDefStmt
        if (localDef.init != null)
          return exprContainsNestedMultiStatementClosure(localDef.init)
        return false
      case StmtId.returnStmt:
        ret := s as ReturnStmt
        if (ret.expr != null)
          return exprContainsNestedMultiStatementClosure(ret.expr)
        return false
      default:
        return false
    }
  }

  ** Check if an expression contains or IS a nested multi-statement closure
  private Bool exprContainsNestedMultiStatementClosure(Expr e)
  {
    // Check if this IS a multi-statement closure
    if (e.id == ExprId.closure)
    {
      ce := e as ClosureExpr
      // NOTE: Use a non-recursive check here to avoid infinite recursion.
      // We only need to check if THIS closure is multi-statement (local vars, etc.)
      // The recursive call from isMultiStatementClosure will handle deeper nesting.
      if (closureNeedsExtractionDirect(ce)) return true
    }

    // Check children
    switch (e.id)
    {
      case ExprId.call:
        ce := e as CallExpr
        if (ce.target != null && exprContainsNestedMultiStatementClosure(ce.target)) return true
        return ce.args.any |arg| { exprContainsNestedMultiStatementClosure(arg) }
      case ExprId.construction:
        ce := e as CallExpr
        return ce.args.any |arg| { exprContainsNestedMultiStatementClosure(arg) }
      case ExprId.shortcut:
        se := e as ShortcutExpr
        if (se.target != null && exprContainsNestedMultiStatementClosure(se.target)) return true
        return se.args.any |arg| { exprContainsNestedMultiStatementClosure(arg) }
      case ExprId.coerce:
        tc := e as TypeCheckExpr
        return exprContainsNestedMultiStatementClosure(tc.target)
      case ExprId.ternary:
        te := e as TernaryExpr
        return exprContainsNestedMultiStatementClosure(te.condition) ||
               exprContainsNestedMultiStatementClosure(te.trueExpr) ||
               exprContainsNestedMultiStatementClosure(te.falseExpr)
      case ExprId.boolOr:
        co := e as CondExpr
        return co.operands.any |op| { exprContainsNestedMultiStatementClosure(op) }
      case ExprId.boolAnd:
        ca := e as CondExpr
        return ca.operands.any |op| { exprContainsNestedMultiStatementClosure(op) }
      case ExprId.closure:
        // Already checked above, but need to check INSIDE for deeply nested
        cl := e as ClosureExpr
        Block? codeBlock := null
        if (cl.doCall != null && cl.doCall.code != null)
          codeBlock = cl.doCall.code
        else if (cl.call != null && cl.call.code != null)
          codeBlock = cl.call.code
        else if (cl.code != null)
          codeBlock = cl.code
        if (codeBlock != null)
          return containsNestedMultiStatementClosure(codeBlock)
        return false
      default:
        return false
    }
  }

  ** Check if a closure needs extraction WITHOUT the recursive nested check.
  ** This prevents infinite recursion when checking for nested multi-statement closures.
  private Bool closureNeedsExtractionDirect(ClosureExpr ce)
  {
    Block? codeBlock := null
    if (ce.doCall != null && ce.doCall.code != null)
      codeBlock = ce.doCall.code
    else if (ce.call != null && ce.call.code != null)
      codeBlock = ce.call.code
    else if (ce.code != null)
      codeBlock = ce.code

    if (codeBlock == null) return false

    stmts := codeBlock.stmts

    // Check if closure has local variable declarations
    if (stmts.any |s| { s.id == StmtId.localDef }) return true

    // Check if closure has assignments
    hasAssign := stmts.any |s|
    {
      if (s.id == StmtId.expr)
      {
        es := s as ExprStmt
        return isAssignmentExpr(es.expr)
      }
      if (s.id == StmtId.returnStmt)
      {
        ret := s as ReturnStmt
        if (ret.expr != null)
          return isAssignmentExpr(ret.expr)
      }
      return false
    }
    if (hasAssign) return true

    // Check for control flow
    if (stmts.any |s|
    {
      s.id == StmtId.ifStmt ||
      s.id == StmtId.switchStmt ||
      s.id == StmtId.forStmt ||
      s.id == StmtId.whileStmt ||
      s.id == StmtId.tryStmt
    }) return true

    // Count real statements
    realStmtCount := 0
    stmts.each |s|
    {
      if (s.id == StmtId.returnStmt)
      {
        ret := s as ReturnStmt
        if (ret.expr != null) realStmtCount++
      }
      else if (s.id != StmtId.nop)
      {
        realStmtCount++
      }
    }

    return realStmtCount > 1
  }

  ** Check if expression is an assignment (can't be in lambda body)
  ** Handles coerce wrapping, shortcuts (compound assignments), etc.
  private Bool isAssignmentExpr(Expr e)
  {
    // Unwrap coerce expressions
    while (e.id == ExprId.coerce)
    {
      tc := e as TypeCheckExpr
      e = tc.target
    }

    // Direct assignment
    if (e.id == ExprId.assign) return true

    // Index set (list[i] = x) or compound assignment (x += 5)
    if (e.id == ExprId.shortcut)
    {
      se := e as ShortcutExpr
      if (se.op == ShortcutOp.set) return true
      // Compound assignment, but NOT increment/decrement (those return values)
      if (se.isAssign && se.op != ShortcutOp.increment && se.op != ShortcutOp.decrement)
        return true
    }

    return false
  }

//////////////////////////////////////////////////////////////////////////
// Closure Emission
//////////////////////////////////////////////////////////////////////////

  ** Emit any pending closures that are first used in the current statement
  private Void emitPendingClosuresForStatement()
  {
    if (m.pendingClosures.isEmpty) return

    // Find closures to emit for this statement
    toEmit := [,]
    remaining := [,]

    m.pendingClosures.each |item|
    {
      data := item as Obj[]
      closureId := data[1] as Int
      firstUse := m.closureFirstUse[closureId]

      // Emit if this is the first use statement, OR if usage wasn't tracked (fallback)
      if (firstUse == m.stmtIndex || firstUse == null)
        toEmit.add(item)
      else
        remaining.add(item)
    }

    if (toEmit.isEmpty) return

    // Update pending list
    m.pendingClosures = remaining

    // Emit closures
    toEmit.each |item|
    {
      data := item as Obj[]
      ce := data[0] as ClosureExpr
      closureId := data[1] as Int
      writeClosure(ce, closureId)
    }
  }

  ** Write a multi-statement closure as a def function
  private Void writeClosure(ClosureExpr ce, Int closureId)
  {
    // def _closure_N(params, _self=self):
    w("def _closure_${closureId}(")

    // Get the signature - this is the EXPECTED type (what the target method wants)
    // which may have fewer params than declared in source code (Fantom allows coercion)
    sig := ce.signature as FuncType
    expectedParamCount := sig?.params?.size ?: 0

    // Parameters from closure's doCall method - these have the actual names
    // from the source code, but LIMIT to expected count from signature
    // ALL params get =None default because Python (unlike JS) requires all args
    // JS: f(a,b) called as f() gives a=undefined, b=undefined
    // Python: f(a,b) called as f() raises TypeError
    hasParams := false
    if (ce.doCall?.params != null && !ce.doCall.params.isEmpty)
    {
      // Only output up to expectedParamCount params (or all if signature unavailable)
      maxParams := expectedParamCount > 0 ? expectedParamCount : ce.doCall.params.size
      actualCount := ce.doCall.params.size.min(maxParams)

      actualCount.times |i|
      {
        if (i > 0) w(", ")
        w(escapeName(ce.doCall.params[i].name)).w("=None")
        hasParams = true
      }
    }
    else
    {
      // Fallback to signature names (for it-blocks with implicit it)
      // sig was already defined above
      if (sig != null && !sig.params.isEmpty)
      {
        // Check if this is an it-block (uses implicit it)
        if (ce.isItBlock)
        {
          w("it=None")
          hasParams = true
        }
        else
        {
          sig.names.each |name, i|
          {
            if (i > 0) w(", ")
            if (name.isEmpty)
              w("_p${i}=None")
            else
              w(escapeName(name)).w("=None")
            hasParams = true
          }
        }
      }
    }

    // Add _self=self for outer self capture if needed
    needsOuter := ce.cls?.fieldDefs?.any |f| { f.name == "\$this" } ?: false
    if (needsOuter)
    {
      if (hasParams) w(", ")
      w("_self=self")
    }

    w(")").colon
    indent

    // Multi-statement closures use _self=self, not _outer=self
    // Ensure the flag is false so $this references output _self
    m.inClosureWithOuter = false

    // Emit nonlocal declarations for closure-captured mutable variables
    // Python requires nonlocal to assign to variables from enclosing scope
    nonlocalNames := m.getNonlocalNames
    if (!nonlocalNames.isEmpty)
    {
      w("nonlocal ")
      nonlocalNames.each |name, i|
      {
        if (i > 0) w(", ")
        w(escapeName(name))
      }
      eos
    }

    // Save method-level closure state - nested closures have their own scope
    savedPending := m.pendingClosures.dup
    savedFirstUse := m.closureFirstUse.dup
    savedStmtIndex := m.stmtIndex
    m.pendingClosures = [,]
    m.closureFirstUse = [:]

    // Scan and register nested closures for emission inside this closure
    // This ensures nested defs are written before they're referenced
    scanClosureBodyForNestedClosures(ce)

    // Write the closure body
    codeBlock := ce.doCall?.code ?: ce.code
    hasContent := false
    if (codeBlock != null && !codeBlock.stmts.isEmpty)
    {
      codeBlock.stmts.each |s, idx|
      {
        // Skip self-referential captured variable assignments (js$0 = js$0 -> js = js)
        // Python captures variables automatically from the enclosing scope
        if (isCapturedVarSelfAssign(s)) return

        // Track statement index for nested closure emission
        m.stmtIndex = idx

        // Note: inClosureWithOuter stays false for multi-statement closures
        // because they use _self=self parameter, not _outer=self
        stmt(s)
        hasContent = true
      }
    }

    // Restore method-level closure state
    m.pendingClosures = savedPending
    m.closureFirstUse = savedFirstUse
    m.stmtIndex = savedStmtIndex

    if (!hasContent)
    {
      pass
    }

    unindent
    nl

    // Wrap the closure with Func.make_closure for proper Fantom Func methods
    w("_closure_${closureId} = sys.Func.make_closure({")

    // Returns type
    retType := sig?.returns?.signature ?: "sys::Void"
    w("\"returns\": ").str(retType).w(", ")

    // Immutability case from compiler analysis
    immutCase := m.closureImmutability(ce)
    w("\"immutable\": ").str(immutCase).w(", ")

    // Params (sanitize Java FFI type signatures)
    w("\"params\": [")
    if (ce.doCall?.params != null)
    {
      maxParams := expectedParamCount > 0 ? expectedParamCount : ce.doCall.params.size
      actualCount := ce.doCall.params.size.min(maxParams)
      actualCount.times |i|
      {
        if (i > 0) w(", ")
        p := ce.doCall.params[i]
        pSig := PyUtil.sanitizeJavaFfi(p.type.signature)
        w("{\"name\": ").str(p.name).w(", \"type\": ").str(pSig).w("}")
      }
    }
    else if (sig != null && !sig.params.isEmpty)
    {
      sig.params.each |p, i|
      {
        if (i > 0) w(", ")
        name := sig.names.getSafe(i) ?: "_p${i}"
        pSig := PyUtil.sanitizeJavaFfi(p.signature)
        w("{\"name\": ").str(name).w(", \"type\": ").str(pSig).w("}")
      }
    }
    w("]}, _closure_${closureId})").eos
  }

  ** Check if statement is a self-referential captured variable assignment
  ** These are generated by Fantom compiler like: js$0 = js$0
  ** Python captures variables automatically so we skip these
  private Bool isCapturedVarSelfAssign(Stmt s)
  {
    // Must be expression statement
    if (s.id != StmtId.expr) return false

    exprStmt := s as ExprStmt

    // Must be assignment expression
    if (exprStmt.expr.id != ExprId.assign) return false

    assign := exprStmt.expr as BinaryExpr

    // Both sides must be field expressions
    if (assign.lhs.id != ExprId.field || assign.rhs.id != ExprId.field) return false

    lhsField := assign.lhs as FieldExpr
    rhsField := assign.rhs as FieldExpr

    // Both must reference the same captured variable field (pattern: name$N)
    lhsName := lhsField.field.name
    rhsName := rhsField.field.name

    if (lhsName != rhsName) return false

    // Check if it's a captured variable pattern (name$N where N is digits)
    if (!lhsName.contains("\$")) return false

    idx := lhsName.index("\$")
    if (idx == null || idx >= lhsName.size - 1) return false

    suffix := lhsName[idx+1..-1]
    return !suffix.isEmpty && suffix.all |c| { c.isDigit }
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  ** Print a block of statements
  ** Handles "effectively empty" blocks (all nops or catch vars) by adding pass
  Void block(Block? b, Bool isCatchBlock := false)
  {
    indent

    hasContent := false
    if (b != null && !b.stmts.isEmpty)
    {
      b.stmts.each |s|
      {
        // Skip nops - they produce no output
        if (s.id == StmtId.nop) return

        // In catch blocks, skip catch variable declarations (handled by except...as)
        if (isCatchBlock && s.id == StmtId.localDef && (s as LocalDefStmt).isCatchVar) return

        stmt(s)
        hasContent = true
      }
    }

    // Python requires content in blocks - add pass if effectively empty
    if (!hasContent)
      pass

    unindent
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  private Void exprStmt(ExprStmt s)
  {
    // For statement-level local variable assignments, use = not :=
    // The walrus operator (:=) should only be used inside expressions
    // (e.g., conditions, function arguments, etc.)
    e := s.expr

    // Unwrap coerces to find the underlying assignment
    while (e.id == ExprId.coerce)
    {
      tc := e as TypeCheckExpr
      e = tc.target
    }

    // Check if this is a local variable assignment at statement level
    if (e.id == ExprId.assign)
    {
      assign := e as BinaryExpr
      if (assign.lhs.id == ExprId.localVar)
      {
        // Statement-level local var assignment: use regular = not :=
        localExpr := assign.lhs as LocalVarExpr
        w(escapeName(localExpr.var.name))
        w(" = ")
        expr(assign.rhs)
        eos
        return
      }
    }

    // For all other expressions, use the normal expression printer
    expr(s.expr)
    eos
  }

  private Void localDef(LocalDefStmt s)
  {
    // Skip catch vars - handled in tryStmt
    if (s.isCatchVar) return

    // Skip captured variable self-assignments (js = js$0 -> js = js)
    // Python captures variables automatically from enclosing scope
    if (isCapturedVarLocalDef(s)) return

    // Check if this is a Wrap$ wrapper definition (closure-captured mutable variable)
    // If so, skip the line entirely -- we use nonlocal instead of cvar wrappers
    if (detectAndRecordNonlocal(s)) return

    w(escapeName(s.name))
    if (s.init != null)
    {
      w(" = ")
      // If init is an assignment, only output the RHS
      if (s.init.id == ExprId.assign)
      {
        assign := s.init as BinaryExpr
        expr(assign.rhs)
      }
      else
      {
        expr(s.init)
      }
    }
    else
    {
      w(" = None")
    }
    eos
  }

  ** Detect if this is a Wrap$ wrapper definition and record for nonlocal handling
  ** Pattern: wrapperVar := Wrap$Type.make(originalVar)
  ** Returns true if this line should be skipped (it's a wrapper we handle via nonlocal)
  private Bool detectAndRecordNonlocal(LocalDefStmt s)
  {
    if (s.init == null) return false

    // Unwrap coerces and assignments to get the actual call
    initExpr := s.init
    while (initExpr.id == ExprId.coerce)
    {
      tc := initExpr as TypeCheckExpr
      initExpr = tc.target
    }
    if (initExpr.id == ExprId.assign)
    {
      assign := initExpr as BinaryExpr
      initExpr = assign.rhs
      while (initExpr.id == ExprId.coerce)
      {
        tc := initExpr as TypeCheckExpr
        initExpr = tc.target
      }
    }

    // Check if it's a call expression (for Wrap$.make pattern)
    if (initExpr.id != ExprId.call) return false

    call := initExpr as CallExpr

    // Pattern: Wrap$Type.make(arg) -- synthetic wrapper constructor
    if (call.method.name == "make" && call.target == null && !call.method.isStatic && call.args.size == 1)
    {
      parentType := call.method.parent
      if (parentType.isSynthetic && parentType.name.startsWith("Wrap\$"))
      {
        // Extract the argument (the value being wrapped)
        arg := call.args.first
        while (arg.id == ExprId.coerce)
        {
          tc := arg as TypeCheckExpr
          arg = tc.target
        }

        wrapperVarName := s.name

        if (arg.id == ExprId.localVar)
        {
          // Case 1: Wrap$.make(existingVar) - the original variable already exists
          // Skip this line entirely; the original variable is already defined
          localArg := arg as LocalVarExpr
          originalVarName := localArg.var.name
          m.recordNonlocal(wrapperVarName, originalVarName)
          return true  // Skip this line
        }
        else
        {
          // Case 2: Wrap$.make(literal/expr) - no separate original variable
          // e.g., params = Wrap$Str.make(null), buf = Wrap$Buf.make(self.make(...))
          // Rewrite as: varName = <arg expression> and record for nonlocal
          m.recordNonlocal(wrapperVarName, wrapperVarName)
          w(escapeName(wrapperVarName))
          w(" = ")
          expr(call.args.first)  // Use original arg (with coerces) for proper output
          eos
          return true  // We emitted the rewritten line
        }
      }
    }
    return false
  }

  ** Check if this localDef is a captured variable initialization
  ** Pattern: js := assign(field(js$0)) where js$0 is a captured variable field
  private Bool isCapturedVarLocalDef(LocalDefStmt s)
  {
    if (s.init == null) return false

    // Unwrap coerce expressions to get to the actual content
    initExpr := s.init
    while (initExpr.id == ExprId.coerce)
    {
      tc := initExpr as TypeCheckExpr
      initExpr = tc.target
    }

    // Check if init is assignment - get the RHS
    if (initExpr.id == ExprId.assign)
    {
      assign := initExpr as BinaryExpr
      initExpr = assign.rhs
      // Unwrap coerce on RHS too
      while (initExpr.id == ExprId.coerce)
      {
        tc := initExpr as TypeCheckExpr
        initExpr = tc.target
      }
    }

    // Check if we have a field reference to a captured variable
    if (initExpr.id != ExprId.field) return false

    fieldExpr := initExpr as FieldExpr
    fieldName := fieldExpr.field.name

    // Check if field name matches pattern: varName$N
    if (!fieldName.contains("\$")) return false

    idx := fieldName.index("\$")
    if (idx == null || idx >= fieldName.size - 1) return false

    baseName := fieldName[0..<idx]
    suffix := fieldName[idx+1..-1]

    // Suffix must be all digits
    if (suffix.isEmpty || !suffix.all |c| { c.isDigit }) return false

    // Base name must match the local variable being defined
    return baseName == s.name
  }

  private Void ifStmt(IfStmt s)
  {
    w("if ")
    expr(s.condition)
    colon
    block(s.trueBlock)
    if (s.falseBlock != null)
    {
      w("else")
      colon
      block(s.falseBlock)
    }
  }

  private Void returnStmt(ReturnStmt s)
  {
    if (s.expr != null)
    {
      // Unwrap coerces to check for assignment
      unwrapped := unwrapCoerce(s.expr)

      // Handle return with assignment: return x = 5
      if (unwrapped.id == ExprId.assign)
      {
        assign := unwrapped as BinaryExpr

        // For field assignments with leave=true, ObjUtil.setattr_return already
        // returns the assigned value. Just return it directly.
        // This avoids calling the getter which would trigger extra side effects.
        if (assign.lhs.id == ExprId.field)
        {
          w("return ")
          expr(s.expr)
          eos
          return
        }

        // For local var assignments: execute assignment, then return the var
        expr(s.expr)
        eos
        w("return ")
        // Return the LHS (the variable that now holds the assigned value)
        // This avoids re-evaluating the RHS which may have side effects
        expr(assign.lhs)
        eos
        return
      }

      // Handle return with index set: return acc[name] = hit -> acc[name] = hit; return hit
      // Handle return with compound assignment: return x += 5 -> x += 5; return x
      if (unwrapped.id == ExprId.shortcut)
      {
        shortcut := unwrapped as ShortcutExpr

        // Index set (container[key] = value)
        if (shortcut.op == ShortcutOp.set)
        {
          // Execute index set first
          expr(s.expr)
          eos
          // Then return the assigned value (the second arg to set)
          w("return ")
          expr(shortcut.args[1])
          eos
          return
        }

        // Compound assignment (x += 5, x *= 2, etc.)
        if (shortcut.isAssign)
        {
          // Execute assignment first
          expr(s.expr)
          eos
          // Then return the target (the updated value)
          w("return ")
          expr(shortcut.target)
          eos
          return
        }
      }
    }

    w("return")
    if (s.expr != null)
    {
      w(" ")
      expr(s.expr)
    }
    eos
  }

  ** Unwrap coerce expressions
  private Expr unwrapCoerce(Expr e)
  {
    if (e.id == ExprId.coerce)
    {
      tc := e as TypeCheckExpr
      return unwrapCoerce(tc.target)
    }
    return e
  }

  private Void throwStmt(ThrowStmt s)
  {
    w("raise ")
    expr(s.exception)
    eos
  }

  private Void forStmt(ForStmt s)
  {
    // Fantom for loop: for (init; cond; update)
    // Python equivalent: init; while cond: block; update
    //
    // IMPORTANT: We track the update expression so that continue statements
    // inside the loop body can emit it before jumping. Otherwise continue
    // would skip the update and cause an infinite loop.
    if (s.init != null) stmt(s.init)
    w("while ")
    if (s.condition != null)
      expr(s.condition)
    else
      w("True")
    colon
    indent

    // Set forLoopUpdate so continue statements know to emit it
    savedUpdate := m.forLoopUpdate
    m.forLoopUpdate = s.update

    if (s.block != null)
      s.block.stmts.each |st| { stmt(st) }

    // Restore previous update (for nested for loops)
    m.forLoopUpdate = savedUpdate

    if (s.update != null)
    {
      expr(s.update)
      eos
    }
    unindent
  }

  ** Handle continue statement - must emit for loop update expression first
  private Void continueStmt()
  {
    // If we're in a for loop with an update expression, emit it before continue
    // This prevents infinite loops where continue skips the i++ update
    if (m.forLoopUpdate != null)
    {
      expr(m.forLoopUpdate)
      eos
    }
    w("continue").eos
  }

  private Void whileStmt(WhileStmt s)
  {
    w("while ")
    expr(s.condition)
    colon
    block(s.block)
  }

  private Void tryStmt(TryStmt s)
  {
    w("try")
    colon
    block(s.block)

    s.catches.each |c|
    {
      w("except")
      if (c.errType != null)
      {
        w(" ")
        // For sys::Err (base class), catch all Python exceptions
        // This ensures Python native exceptions (KeyError, etc.) are also caught
        if (c.errType.qname == "sys::Err")
        {
          w("Exception")
        }
        else
        {
          // For specific error types, use the Fantom type
          // Also catch corresponding Python native exceptions where applicable
          curPod := m.curType?.pod?.name
          errPod := c.errType.pod.name
          errName := PyUtil.escapeTypeName(c.errType.name)

          // Map Fantom exceptions to Python native exceptions
          // These need to catch both Fantom and Python versions
          pyNative := pythonNativeException(c.errType.qname)
          if (pyNative != null)
          {
            // Catch both Fantom and Python exceptions: except (sys.IndexErr, IndexError)
            w("(")
            if (errPod == "sys" && curPod != "sys")
              w("sys.")
            w(errName)
            w(", ")
            w(pyNative)
            w(")")
          }
          else
          {
            if (errPod == "sys" && curPod != "sys")
              w("sys.")
            w(errName)
          }
        }
      }
      else
      {
        w(" Exception")
      }
      if (c.errVariable != null)
      {
        w(" as ").w(escapeName(c.errVariable))
      }
      colon
      // Wrap native Python exceptions to ensure they have .trace() method
      // This is needed because except Exception catches native exceptions
      // that don't have Fantom Err methods
      if (c.errVariable != null && (c.errType == null || c.errType.qname == "sys::Err"))
      {
        indent
        w(escapeName(c.errVariable)).w(" = sys.Err.wrap(").w(escapeName(c.errVariable)).w(")").eos
        unindent
      }
      block(c.block, true)  // isCatchBlock=true for catch variable handling
    }

    if (s.finallyBlock != null)
    {
      w("finally")
      colon
      block(s.finallyBlock)
    }
  }

  private Void switchStmt(SwitchStmt s)
  {
    // Python doesn't have switch, use if/elif/else
    // IMPORTANT: Evaluate condition once to avoid side effects being repeated
    // (e.g., switch(i++) must only increment i once)
    switchVarId := m.nextSwitchVarId
    w("_switch_${switchVarId} = ")
    expr(s.condition)
    eos

    first := true
    s.cases.each |c|
    {
      if (first)
      {
        w("if ")
        first = false
      }
      else
      {
        w("elif ")
      }

      // Match any of the case values against the cached condition
      c.cases.each |e, i|
      {
        if (i > 0) w(" or ")
        w("(")
        w("_switch_${switchVarId}")
        w(" == ")
        expr(e)
        w(")")
      }
      colon
      block(c.block)
    }

    if (s.defaultBlock != null)
    {
      if (!first) w("else")
      else w("if True")
      colon
      block(s.defaultBlock)
    }
  }

  ** Map Fantom exception types to corresponding Python native exceptions
  ** Returns the Python exception name if there's a mapping, null otherwise
  private Str? pythonNativeException(Str qname)
  {
    switch (qname)
    {
      case "sys::IndexErr":     return "IndexError"
      case "sys::ArgErr":       return "ValueError"
      case "sys::IOErr":        return "IOError"
      case "sys::UnknownKeyErr": return "KeyError"
      default:                  return null
    }
  }
}
