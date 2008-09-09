//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Dec 05  Brian Frank  Creation
//

**
** Walk the AST to resolve:
**   - Manage local variable scope
**   - Resolve loop for breaks and continues
**   - Resolve LocalDefStmt.init into full assignment expression
**   - Resolve Expr.ctype
**   - Resolve UknownVarExpr -> LocalVarExpr, FieldExpr, or CallExpr
**   - Resolve CallExpr to their CMethod
**
class ResolveExpr : CompilerStep
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
    log.debug("ResolveExpr")
    walk(types, VisitDepth.expr)
    bombIfErr
  }

//////////////////////////////////////////////////////////////////////////
// Method
//////////////////////////////////////////////////////////////////////////

  override Void enterMethodDef(MethodDef m)
  {
    super.enterMethodDef(m)
    this.inClosure = (curType.isClosure && curType.closure.doCall === m)
    initMethodVars
  }

//////////////////////////////////////////////////////////////////////////
// Stmt
//////////////////////////////////////////////////////////////////////////

  override Void enterStmt(Stmt stmt) { stmtStack.push(stmt) }

  override Void visitStmt(Stmt stmt)
  {
    stmtStack.pop
    switch (stmt.id)
    {
      case StmtId.expr:         resolveExprStmt((ExprStmt)stmt)
      case StmtId.forStmt:      resolveFor((ForStmt)stmt)
      case StmtId.breakStmt:    resolveBreak((BreakStmt)stmt)
      case StmtId.continueStmt: resolveContinue((ContinueStmt)stmt)
      case StmtId.localDef:     resolveLocalVarDef((LocalDefStmt)stmt)
    }
  }

  private Void resolveExprStmt(ExprStmt stmt)
  {
    // stand alone expr statements, shouldn't be left on the stack
    stmt.expr = stmt.expr.noLeave
  }

  private Void resolveLocalVarDef(LocalDefStmt def)
  {
    // check for type inference
    if (def.ctype == null)
      def.ctype = def.init.ctype

    // bind to scope as a method variable
    bindToMethodVar(def)

    // if init is null, then we default the variable to null (Fan
    // doesn't do true definite assignment checking since most local
    // variables use type inference anyhow)
    if (def.init == null)
      def.init = LiteralExpr.make(def.location, ExprId.nullLiteral, def.ctype, null)

    // turn init into full assignment
    def.init = BinaryExpr.makeAssign(LocalVarExpr.make(def.location, def.var), def.init)
  }

  private Void resolveFor(ForStmt stmt)
  {
    // don't leave update expression on the stack
    if (stmt.update != null) stmt.update = stmt.update.noLeave
  }

  private Void resolveBreak(BreakStmt stmt)
  {
    // find which loop we're inside of (checked in CheckErrors)
    stmt.loop = findLoop
  }

  private Void resolveContinue(ContinueStmt stmt)
  {
    // find which loop we're inside of (checked in CheckErrors)
    stmt.loop = findLoop
  }

//////////////////////////////////////////////////////////////////////////
// Expr
//////////////////////////////////////////////////////////////////////////

  override Expr visitExpr(Expr expr)
  {
    // resolve the expression
    expr = resolveExpr(expr)

    // expr type must be resolved at this point
    if (expr.ctype == null)
      throw err("Expr type not resolved: ${expr.id}: ${expr}", expr.location)

    // if we resolved to a generic parameter like V or K,
    // then use its real underlying type
    if (expr.ctype.isGenericParameter)
      expr.ctype = expr.ctype.raw

    return expr
  }

  private Expr resolveExpr(Expr expr)
  {
    switch (expr.id)
    {
      case ExprId.slotLiteral:     return resolveSlotLiteral((SlotLiteralExpr)expr)
      case ExprId.listLiteral:     return resolveList((ListLiteralExpr)expr)
      case ExprId.mapLiteral:      return resolveMap((MapLiteralExpr)expr)
      case ExprId.boolNot:
      case ExprId.cmpNull:
      case ExprId.cmpNotNull:      expr.ctype = ns.boolType
      case ExprId.assign:          return resolveAssign((BinaryExpr)expr)
      case ExprId.elvis:           resolveElvis((BinaryExpr)expr)
      case ExprId.same:
      case ExprId.notSame:
      case ExprId.boolOr:
      case ExprId.boolAnd:
      case ExprId.isExpr:          expr.ctype = ns.boolType
      case ExprId.isnotExpr:       expr.ctype = ns.boolType
      case ExprId.asExpr:          expr.ctype = ((TypeCheckExpr)expr).check
      case ExprId.call:            return resolveCall((CallExpr)expr)
      case ExprId.construction:    return resolveConstruction((CallExpr)expr)
      case ExprId.shortcut:        return resolveShortcut((ShortcutExpr)expr)
      case ExprId.thisExpr:        return resolveThis((ThisExpr)expr)
      case ExprId.superExpr:       return resolveSuper((SuperExpr)expr)
      case ExprId.unknownVar:      return resolveVar((UnknownVarExpr)expr)
      case ExprId.storage:         return resolveStorage((UnknownVarExpr)expr)
      case ExprId.cast:            expr.ctype = ((TypeCheckExpr)expr).check
      case ExprId.ternary:         resolveTernary((TernaryExpr)expr)
      case ExprId.withSub:         resolveWithSub((WithSubExpr)expr)
      case ExprId.curry:           return resolveCurry((CurryExpr)expr)
      case ExprId.closure:         resolveClosure((ClosureExpr)expr)
    }

    return expr
  }

  **
  ** Resolve slot literal
  **
  private Expr resolveSlotLiteral(SlotLiteralExpr expr)
  {
    slot := expr.parent.slot(expr.name)
    if (slot == null)
    {
      err("Unknown slot literal '${expr.parent.signature}.${expr.name}'", expr.location)
      expr.ctype = ns.error
      return expr
    }
    expr.ctype = slot is CField ? ns.fieldType : ns.methodType
    expr.slot = slot
    return expr
  }

  **
  ** Resolve list literal
  **
  private Expr resolveList(ListLiteralExpr expr)
  {
    if (expr.explicitType != null)
    {
      expr.ctype = expr.explicitType
    }
    else
    {
      // infer from list item expressions
      v := Expr.commonType(ns, expr.vals)
      expr.ctype = v.toListOf
    }
    return expr
  }

  **
  ** Resolve map literal
  **
  private Expr resolveMap(MapLiteralExpr expr)
  {
    if (expr.explicitType != null)
    {
      expr.ctype = expr.explicitType
    }
    else
    {
      // infer from key/val expressions
      k := Expr.commonType(ns, expr.keys)
      v := Expr.commonType(ns, expr.vals)
      expr.ctype = MapType.make(k, v)
    }
    return expr
  }

  **
  ** Resolve this keyword expression
  **
  private Expr resolveThis(ThisExpr expr)
  {
    if (inClosure)
    {
      loc := expr.location
      closure := curType.closure

      // if the closure is in a static method, report an error
      if (closure.enclosingMethod.isStatic)
      {
        expr.ctype = ns.error
        err("Cannot access 'this' within closure of static context", loc)
        return expr
      }

      // otherwise replace this with $this field access
      return FieldExpr.make(loc, ThisExpr.make(loc), closure.outerThisField)
    }

    expr.ctype = curType
    return expr
  }

  **
  ** Resolve super keyword expression
  **
  private Expr resolveSuper(SuperExpr expr)
  {
    if (inClosure)
    {
      // it would be nice to support super from within a closure,
      // but the Java VM has the stupid restriction that invokespecial
      // cannot be used outside of the class - we could potentially
      // work around this using a wrapper method - but for now we will
      // just disallow it
      err("Invalid use of 'super' within closure", expr.location)
      expr.ctype = ns.error
      return expr
    }

    if (expr.explicitType != null)
      expr.ctype = expr.explicitType
    else
      expr.ctype = curType.base

    return expr
  }

  **
  ** Resolve an assignment operation
  **
  private Expr resolveAssign(BinaryExpr expr)
  {
    // check for left hand side the [] shortcut, because []= is set
    shortcut := expr.lhs as ShortcutExpr
    if (shortcut != null && shortcut.op == ShortcutOp.get)
    {
      shortcut.op = ShortcutOp.set
      shortcut.name = "set"
      shortcut.args.add(expr.rhs)
      shortcut.method = null
      return resolveCall(shortcut)
    }

    // check for left hand side the -> shortcut, because a->x=b is trap.a("x", [b])
    call := expr.lhs as CallExpr
    if (call != null && call.isDynamic)
    {
      call.args.add(expr.rhs)
      return resolveCall(call)
    }

    // assignment is typed by lhs
    expr.ctype = expr.lhs.ctype

    return expr
  }

  **
  ** Resolve an UnknownVar to its replacement node.
  **
  private Expr resolveVar(UnknownVarExpr var)
  {
    // if there is no target, attempt to bind to local variable
    if (var.target == null)
    {
      // attempt to a name in the current scope
      binding := resolveLocal(var.name)
      if (binding != null)
        return LocalVarExpr.make(var.location, binding)
    }

    // at this point it can't be a local variable, so it must be
    // a slot on either myself or the variable's target
    return CallResolver.make(compiler, curType, curMethod, var).resolve
  }

  **
  ** Resolve storage operator
  **
  private Expr resolveStorage(UnknownVarExpr var)
  {
    // resolve as normal unknown variable
    resolved := resolveVar(var)
    if (resolved.id !== ExprId.field)
    {
      if (resolved.ctype !== ns.error)
        err("Invalid use of field storage operator '@'", var.location)
      return resolved
    }

    f := resolved as FieldExpr
    f.useAccessor = false
    if (f.field is FieldDef) ((FieldDef)f.field).flags |= FConst.Storage
    return f
  }

  **
  ** Resolve "x ?: y" expression
  **
  private Expr resolveElvis(BinaryExpr expr)
  {
    expr.ctype = CType.common(ns, [expr.lhs.ctype, expr.rhs.ctype])
    return expr
  }

  **
  ** Resolve "x ? y : z" ternary expression
  **
  private Expr resolveTernary(TernaryExpr expr)
  {
    if (expr.trueExpr.id === ExprId.nullLiteral)
      expr.ctype = expr.falseExpr.ctype
    else if (expr.falseExpr.id === ExprId.nullLiteral)
      expr.ctype = expr.trueExpr.ctype
    else
      expr.ctype = CType.common(ns, [expr.trueExpr.ctype, expr.falseExpr.ctype])
    return expr
  }

  **
  ** Resolve with-sub expression
  **
  private Expr resolveWithSub(WithSubExpr sub)
  {
    // update if sub-expr was resolved as 'with.add(expr)'
    if (sub.add != null)
      sub.expr = CallExpr.makeWithMethod(sub.location, WithBaseExpr.make(sub.withBlock), sub.add, [sub.expr])

    // we never leave sub-expr on the stack
    sub.expr  = sub.expr.noLeave

    sub.ctype = sub.expr.ctype
    return sub
  }

  **
  ** Resolve a call to it's Method and return type.
  **
  private Expr resolveCall(CallExpr call)
  {
    // dynamic calls are just syntactic sugar for Obj.trap
    if (call.isDynamic)
    {
      call.method = ns.objTrap
      call.ctype = ns.objType
      return call
    }

    // if there is no target, attempt to bind to local variable
    if (call.target == null)
    {
      // attempt to a name in the current scope
      binding := resolveLocal(call.name)
      if (binding != null)
        return resolveCallOnLocalVar(call, LocalVarExpr.make(call.location, binding))
    }

    return CallResolver.make(compiler, curType, curMethod, call).resolve
  }

  **
  ** Resolve the () operator on a local variable - if the local
  ** is a Method, then () is syntactic sugar for Method.callx()
  **
  private Expr resolveCallOnLocalVar(CallExpr call, LocalVarExpr binding)
  {
    // if binding isn't a sys::Func then no can do
    if (!binding.ctype.fits(ns.funcType))
    {
      if (binding.ctype != ns.error)
        err("Cannot call local variable '$call.name' like a function", call.location)
      call.ctype = ns.error
      return call
    }

    // can only handle zero to eight arguments; I could wrap up the
    // arguments into a List and use call(List) - but methods with
    // that many arguments are just inane so tough luck
    if (call.args.size > 8)
    {
      err("Tough luck - cannot use () operator with more than 8 arguments, use call(List)", call.location)
      call.ctype = ns.error
      return call
    }

    // invoking the () operator on a sys::Func is syntactic
    // sugar for invoking one of the Func.callX methods
    callx := binding.ctype.method("call${call.args.size}")
    return CallExpr.makeWithMethod(call.location, binding, callx, call.args)
  }

  **
  ** Resolve a construction call Type(args)
  **
  private Expr resolveConstruction(CallExpr call)
  {
    base := call.target.ctype

    // construction always resolves to base type (we
    // double check this in CheckErrors)
    call.ctype = base

    // check for fromStr
    if (call.args.size == 1 && call.args.first.ctype.isStr)
    {
      fromStr := base.method("fromStr")
      if (fromStr != null)
      {
        call.method = fromStr
        return call
      }
    }

    // resolve make
    call.method = base.method("make")
    if (call.method == null)
      err("Unknown construction method '${base.qname}.make'", call.location)
    return call
  }

  **
  ** Resolve ShortcutExpr.
  **
  private Expr resolveShortcut(ShortcutExpr expr)
  {
    // if this is an indexed assigment such as x[y] += z
    if (expr.isAssign && expr.target.id === ExprId.shortcut)
      return resolveIndexedAssign(expr)

    // if a binary operation
    if (expr.args.size == 1)
    {
      // extract lhs and rhs
      lhs := expr.target
      rhs := expr.args.first

      // if arg is Range, then get() is really slice()
      if (expr.op === ShortcutOp.get && rhs.ctype.isRange)
      {
        expr.op = ShortcutOp.slice
        expr.name = "slice"
      }

      // string concat is always optimized, and performs a bit
      // different since a non-string can be used as the lhs
      if (expr.isStrConcat)
      {
        expr.ctype  = ns.strType
        expr.method = ns.strPlus
        return ConstantFolder.make(compiler).fold(expr)
      }
    }

    // resolve the call, if optimized, then return it immediately
    result := resolveCall(expr)
    if (result !== expr) return result

    // the comparision operations are special case that call a method
    // that return an Int, but leave a Bool on the stack (we also handle
    // specially in assembler)
    switch (expr.opToken)
    {
      case Token.lt:
      case Token.ltEq:
      case Token.gt:
      case Token.gtEq:
        expr.ctype = ns.boolType
    }

    return expr
  }

  **
  ** If we have an assignment against an indexed shortcut
  ** such as x[y] += z, then process specially to return
  ** a IndexedAssignExpr subclass of ShortcutExpr.
  **
  private Expr resolveIndexedAssign(ShortcutExpr orig)
  {
    // if target is in error, don't bother
    if (orig.target.ctype === ns.error)
    {
      orig.ctype = ns.error
      return orig
    }

    // we better have a x[y] indexed get expression
    if (orig.target.id != ExprId.shortcut && orig.target->op === ShortcutOp.get)
    {
      err("Expected indexed expression", orig.location)
      return orig
    }

    // wrap the shorcut as an IndexedAssignExpr
    expr := IndexedAssignExpr.makeFrom(orig)

    // resolve it normally - if the orig is "x[y] += z" then we
    // are resolving Int.plus here - the target is "x[y]" and should
    // already be resolved
    resolveCall(expr)

    // we need two scratch variables to manipulate the stack cause
    // .NET is lame when it comes to doing anything with the stack
    expr.scratchA = curMethod.addLocalVar(expr.ctype, null, null)
    expr.scratchB = curMethod.addLocalVar(expr.ctype, null, null)

    // resolve the set method which matches
    // the get method on the target
    get := ((ShortcutExpr)expr.target).method
    set := get.parent.method("set")
    if (set == null || set.params.size != 2 || set.isStatic ||
        set.params[0].paramType != get.params[0].paramType ||
        set.params[1].paramType != get.returnType)
      err("No matching 'set' method for '$get.qname'", orig.location)
    expr.setMethod = set

    // return the new IndexedAssignExpr
    return expr
  }

  **
  ** CurryExpr
  **
  private Expr resolveCurry(CurryExpr expr)
  {
    // if the operand isn't a CallExpr, then we have a problem
    if (expr.operand.id !== ExprId.call)
    {
      err("Invalid operand '$expr.operand.id' for curry operator", expr.location)
      expr.ctype = ns.error
      return expr
    }

    // use CurryResolver for all the heavy lifting
    return CurryResolver.make(compiler, curType, curryCount++, expr).resolve
  }

  **
  ** ClosureExpr will just output its substitute expression.  But we take
  ** this opportunity to capture the local variables in the closure's scope
  ** and cache them on the ClosureExpr.  We also do variable name checking.
  **
  private Void resolveClosure(ClosureExpr expr)
  {
    // save away current locals in scope
    expr.enclosingLocals = localsInScope

    // make sure none of the closure's parameters
    // conflict with the locals in scope
    expr.doCall.paramDefs.each |ParamDef p|
    {
      if (expr.enclosingLocals.containsKey(p.name))
        err("Closure parameter '$p.name' is already defined in current block", p.location)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Scope
//////////////////////////////////////////////////////////////////////////

  **
  ** Setup the MethodVars for the parameters.
  **
  private Void initMethodVars()
  {
    m := curMethod
    reg := m.isStatic ?  0 : 1

    m.paramDefs.each |ParamDef p|
    {
      var := MethodVar.makeForParam(reg++, p)
      m.vars.add(var)
    }
  }

  **
  ** Bind the specified local variable definition to a
  ** MethodVar (and register number).
  **
  private Void bindToMethodVar(LocalDefStmt def)
  {
    // make sure it doesn't exist in the current scope
    if (resolveLocal(def.name) != null)
      err("Variable '$def.name' is already defined in current block", def.location)

    // create and add it
    def.var = curMethod.addLocalVar(def.ctype, def.name, currentBlock)
  }

  **
  ** Resolve a local variable using current scope based on
  ** the block stack and possibly the scope of a closure.
  **
  private MethodVar resolveLocal(Str name)
  {
    // if not in method, then we can't have a local
    if (curMethod == null) return null

    // attempt to a name in the current scope
    binding := curMethod.vars.find |MethodVar var->Bool|
    {
      return var.name == name && isBlockInScope(var.scope)
    }
    if (binding != null) return binding

    // if a closure, check parent scope
    if (inClosure)
    {
      closure := curType.closure
      binding = closure.enclosingLocals[name]
      if (binding != null)
      {
        // mark the local var as being used in a closure so that
        // we know to generate a cvar field for it in ClosureVars
        binding.usedInClosure = true

        // mark this closure as using cvars
        closure.usesCvars = true

        // mark the enclosing method and recursively
        // any outer closures as needing cvars
        closure.enclosingMethod.needsCvars = true
        for (p := closure.enclosingClosure; p != null; p = p.enclosingClosure)
          p.doCall.needsCvars = true

        return binding
      }
    }

    // not found
    return null
  }

  **
  ** Get a list of all the local method variables that
  ** are currently in scope.
  **
  private Str:MethodVar localsInScope()
  {
    Str:MethodVar acc
    if (inClosure)
      acc = curType.closure.enclosingLocals.dup
    else
      acc = Str:MethodVar[:]

    curMethod.vars.each |MethodVar var|
    {
      if (isBlockInScope(var.scope))
        acc[var.name] = var
    }

    return acc
  }

  **
  ** Get the current block which defines our scope.  We make
  ** a special case for "for" loops which can declare variables.
  **
  private Block currentBlock()
  {
    if (stmtStack.peek is ForStmt)
      return ((ForStmt)stmtStack.peek).block
    else
      return blockStack.peek
  }

  **
  ** Check if the specified block is currently in scope.  We make
  ** a specialcase for "for" loops which can declare variables.
  **
  private Bool isBlockInScope(Block block)
  {
    // the null block within the whole method (ctorChains or defaultParams)
    if (block == null) return true

    // special case for "for" loops
    if (stmtStack.peek is ForStmt)
    {
      if (((ForStmt)stmtStack.peek).block === block)
        return true
    }

    // look in block stack which models scope chain
    return blockStack.any |Block b->Bool| { return b === block }
  }

//////////////////////////////////////////////////////////////////////////
// StmtStack
//////////////////////////////////////////////////////////////////////////

  private Stmt findLoop()
  {
    for (i:=stmtStack.size-1; i>=0; --i)
    {
      stmt := stmtStack[i]
      if (stmt.id === StmtId.whileStmt) return stmt
      if (stmt.id === StmtId.forStmt)   return stmt
    }
    return null
  }

//////////////////////////////////////////////////////////////////////////
// BlockStack
//////////////////////////////////////////////////////////////////////////

  override Void enterBlock(Block block) { blockStack.push(block) }
  override Void exitBlock(Block block)  { blockStack.pop }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Stmt[] stmtStack  := Stmt[,]    // statement stack
  Block[] blockStack := Block[,]  // block stack used for scoping
  Bool inClosure := false         // are we inside a closure's block
  Int curryCount := 0             // total number of curry exprs processed

}