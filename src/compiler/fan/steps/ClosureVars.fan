//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 06  Brian Frank  Creation
//   4 Oct 06  Brian Frank  Port from Java to Fan
//

**
** ClosureVars (cvars) is used to pull local variables used by closures
** into an auto-generated anonymous class so that they can be
** used outside and inside the closure as well as have a lifetime
** once the method returns:
**   1) scan for methods with have locals used by their closures
**   3) define the cvars class
**   4) remove method vars which are stored in cvars
**   5) walk the method body
**      a) remap local var access to cvars field access
**      b) accumulate all the ClosureExprs
**   6) walk accumlated ClosureExprs in method body
**      a) add $cvars field to closure implementation class
**      b) add $cvars parameter to implementation class constructor
**      c) pass $cvars arg from method body to implementation constructor
**      d) walk implementation class code and remap local var access
**   7) decide if closure is thread-safe or not and mark isConst
**
** Note: this same process is used to process nested closure doCall methods
**   too; but they do things a bit differently since they always share the
**   outmost method's cvars.
**
class ClosureVars : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
    closures = ClosureExpr[,]
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    types.each |TypeDef t| { scanType(t) }
  }

  private Void scanType(TypeDef t)
  {
    t.methodDefs.each |MethodDef m|
    {
      if (m.needsCvars) process(m)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Process
//////////////////////////////////////////////////////////////////////////

  private Void process(MethodDef method)
  {
    this.method     = method
    this.location   = method.location
    this.inClosure  = method.parentDef.isClosure && method.parentDef.closure.doCall === method
    this.cvars      = null
    this.cvarsCtor  = null
    this.cvarsLocal = null
    this.closures.clear

    defineCvarsClass
    reorderVars
    insertCvarsInit
    remapVarsInMethod
    remapVarsInClosures
  }

//////////////////////////////////////////////////////////////////////////
// Define Cvars Class
//////////////////////////////////////////////////////////////////////////

  **
  ** Walk the current method and create the cvars class, a default
  ** constructor, and a field for every local variable used inside
  ** closures.  If this is a closure itself, then we just reuse
  ** the cvar class of the outer most method.
  **
  private Void defineCvarsClass()
  {
    // if in a closure body, then reuse the enclosing
    // method's cvar class (which should have already
    // been defined)
    if (inClosure)
    {
      closure := method.parentDef.closure
      name := toCvarsTypeName(closure.enclosingType, closure.enclosingSlot)
      cvars = (TypeDef)compiler.pod.resolveType(name, true)
    }

    // define the Cvars class and generate no arg constructor
    else
    {
      // define type def
      name := toCvarsTypeName(method.parentDef, method)
      cvars = TypeDef(ns, location, method.parentDef.unit, name)
      cvars.flags = FConst.Internal | FConst.Synthetic
      cvars.base  = ns.objType
      addTypeDef(cvars)

      // generate no arg constructor
      cvarsCtor = DefaultCtor.addDefaultCtor(cvars, FConst.Internal | FConst.Synthetic)
    }

    // generate the fields used to store each local
    method.vars.each |MethodVar var|
    {
      if (var.usedInClosure)
      {
        f := FieldDef(location, cvars)
        f.name      = "${var.name}\$${cvars.slots.size}"
        f.fieldType = var.ctype
        f.flags     = syntheticFieldFlags
        cvars.addSlot(f)
        var.cvarsField = f
      }
    }
  }

  private static Str toCvarsTypeName(TypeDef t, SlotDef s)
  {
    m := s as MethodDef
    if (m != null)
    {
      if (m.isGetter) return "${t.name}\$${s.name}\$GetCvars"
      if (m.isSetter) return "${t.name}\$${s.name}\$SetCvars"
    }
    return "${t.name}\$${s.name}\$Cvars"
  }

//////////////////////////////////////////////////////////////////////////
// Reorder Vars
//////////////////////////////////////////////////////////////////////////

  **
  ** Once all the variables of a method body have been processed
  ** into cvars fields, this method strips out any non-parameter
  ** locals and optimally reorders them.  We return the local
  ** variable to use for the cvar reference itself.
  **
  private Void reorderVars()
  {
    // remove any non-parameter, locally defined variables
    // from the list which are to moved into the cvars class
    method.vars = method.vars.exclude |MethodVar v->Bool|
    {
      return !v.isParam && v.usedInClosure && !v.isCatchVar
    }

    // if in a closure, then the $cvars local variable was
    // created previously by remapVarInClosure() while processing
    // the enclosing method, so just look it up
    if (inClosure)
    {
      cvarsLocal = method.vars[method.params.size]
      if (cvarsLocal.name != "\$cvars")
        throw err("Internal error", method.location)
    }

    // now insert the cvars (right after params so that we can
    // use optimized register access such as ILOAD_2 for Java)
    else
    {
      cvarsLocal = MethodVar(-1, cvars, "\$cvars")
      method.vars.insert(method.params.size, cvarsLocal)
    }

    // re-index the registers
    reg := method.isStatic ? 0 : 1
    method.vars.each |MethodVar v| { v.register = reg++ }
  }

//////////////////////////////////////////////////////////////////////////
// Insert Cvars Initialization
//////////////////////////////////////////////////////////////////////////

  private Void insertCvarsInit()
  {
    //  method(Foo x)
    //  {
    //    $cvars := $Cvars.make()
    //    $cvars.x = x // for all params
    //    ...
    //  }

    // if not in closure then generate "$cvars = $Cvars.make()"
    // constructor call; if in closure, then we've already
    // generated "$cvars = this.$cvars" in remapVarInClosure()
    // while processing the enclosng method
    if (!inClosure)
    {
      local := LocalVarExpr(location, cvarsLocal)
      local.ctype = cvars

      ctorCall := CallExpr.makeWithMethod(location, null, cvarsCtor)

      assign := BinaryExpr.makeAssign(local, ctorCall)

      method.code.stmts.insert(0, assign.toStmt)
    }

    // init any params we are going to remap to cvars
    method.vars.each |MethodVar var|
    {
      if (!var.isParam || var.cvarsField == null) return

      lhs := fieldExpr(location, LocalVarExpr(location, cvarsLocal), var.cvarsField)

      rhs := LocalVarExpr(location, var)
      rhs.noRemapToCvars = true // don't want to replace this access with cvars field

      assign := BinaryExpr.makeAssign(lhs, rhs)
      method.code.stmts.insert(1, assign.toStmt)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Remap Vars in Method
//////////////////////////////////////////////////////////////////////////

  private Void remapVarsInMethod()
  {
    method.code.walkExpr |Expr expr->Expr|
    {
      switch (expr.id)
      {
        case ExprId.localVar: return remapLocalVar((LocalVarExpr)expr)
        case ExprId.closure:  closures.add((ClosureExpr)expr)
      }
      return expr
    }
  }

  Expr remapLocalVar(LocalVarExpr local)
  {
    // x -> $cvars.x
    if (local.var.cvarsField == null) return local
    if (local.noRemapToCvars) return local
    loc := local.location
    return fieldExpr(loc, LocalVarExpr(loc, cvarsLocal), local.var.cvarsField)
  }

//////////////////////////////////////////////////////////////////////////
// Remap Vars in Closures
//////////////////////////////////////////////////////////////////////////

  private Void remapVarsInClosures()
  {
    // closures now contains all the ClosureExpr we found inside
    // the current method body, now we need to walk them; this is
    // also where we change isImmutable() to return false because
    // capturing locals into a cvars is not thread safe
    closures.each |ClosureExpr c|
    {
      if (remapVarInClosure(c))
        markMutable(c)
    }
  }

  **
  ** Remap local variables to cvars.  Return false if no
  ** locals are captured in the given closure.
  **
  private Bool remapVarInClosure(ClosureExpr closure)
  {
    doCall := closure.cls.methodDef("doCall")

    // walk closure implementation looking for cvars
    MethodVar? cvarsLocal := null
    doCall.code.walkExpr |Expr expr->Expr|
    {
      // if we've encountered a nested closure which uses cvars,
      // then this closure must pass the cvars thru - we will
      // process this closure fully in process() eventually because
      // it should have been marked needsCvars in ResolveExpr
      if (expr is ClosureExpr)
      {
        nested := (ClosureExpr)expr
        if (nested.usesCvars && cvarsLocal == null)
          cvarsLocal = MethodVar(-1, cvars, "\$cvars")
        return expr
      }

      // check if it a local from my outer scope
      local := expr as LocalVarExpr
      if (local == null ||
          local.var == null ||
          local.var.cvarsField == null) return expr

      // if I haven't yet allocated my own local to access
      // the whole cvars instance, let's do that now
      if (cvarsLocal == null)
        cvarsLocal = MethodVar(-1, cvars, "\$cvars")

      // replace "x" with "$cvars.x"
      loc := local.location
      return fieldExpr(loc, LocalVarExpr(loc, cvarsLocal), local.var.cvarsField)
    }

    // if no expressions within the closure use cvars,
    // then our work here is done
    if (cvarsLocal == null) return false

    // add cvars field to closure implementation class
    loc := closure.location
    field := FieldDef(loc, closure.cls)
    field.name      = "\$cvars"
    field.fieldType = TypeRef(loc, cvars)
    field.flags     = syntheticFieldFlags
    closure.cls.addSlot(field)

    // add parameter to closure implementation constructor
    ctor := closure.cls.methodDef("make")
    param := ParamDef(loc, cvars, "\$cvars")
    paramVar := MethodVar.makeForParam(ctor.params.size+1, param, param.paramType)
    ctor.params.add(param)
    ctor.vars.add(paramVar)

    // set field in constructor
    assign := BinaryExpr.makeAssign(
      fieldExpr(loc, ThisExpr(loc), field),
      LocalVarExpr(loc, paramVar))
    ctor.code.stmts.insert(0, assign.toStmt)

    // pass cvars instance to closure class constructor
    closure.substitute.args.add(LocalVarExpr(loc, this.cvarsLocal))

    // add local variable $cvars into doCall
    cvarsLoad := BinaryExpr.makeAssign(
      LocalVarExpr(loc, cvarsLocal),
      fieldExpr(loc, ThisExpr(loc), field))
    doCall.vars.insert(doCall.params.size, cvarsLocal)
    doCall.vars.each |MethodVar v, Int i| { v.register = i+1 }
    doCall.code.stmts.insert(0, cvarsLoad.toStmt)
    return true
  }

//////////////////////////////////////////////////////////////////////////
// Outer This Field
//////////////////////////////////////////////////////////////////////////

  **
  ** This method is called by ClosureExpr to auto-generate the
  ** implicit outer "this" field in the Closure's implementation
  ** class:
  **   - add $this field to closure's anonymous class
  **   - add $this param to closure's make constructor
  **   - set field from param in constructor
  **   - update substitute to make sure this is passed to ctor
  **
  static CField makeOuterThisField(ClosureExpr closure)
  {
    loc      := closure.location
    thisType := closure.enclosingType
    implType := closure.cls

    // define outer this as "$this"
    field := FieldDef(loc, implType)
    field.name  = "\$this"
    field.flags = syntheticFieldFlags
    field.fieldType = thisType
    implType.addSlot(field)

    // pass this to subtitute closure constructor - if this is a nested
    // closure, then we have to get $this from it's own $this field
    if (closure.enclosingClosure != null)
    {
      outerThis := closure.enclosingClosure.outerThisField
      closure.substitute.args.add(fieldExpr(loc, ThisExpr(loc), outerThis))
    }
    else
    {
      // outer most closure just uses this
      closure.substitute.args.add(ThisExpr(loc))
    }

    // add parameter to constructor
    ctor  := implType.methodDef("make")
    param := ParamDef(loc, thisType, "\$this")
    var   := MethodVar.makeForParam(ctor.params.size+1, param, param.paramType)
    ctor.params.add(param)
    ctor.vars.add(var)

    // set field in constructor
    assign := BinaryExpr.makeAssign(fieldExpr(loc, ThisExpr(loc), field), LocalVarExpr(loc, var))
    ctor.code.stmts.insert(0, assign.toStmt)

    // we can longer assume this closure is thread safe
    markMutable(closure)

    return field
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private static Void markMutable(ClosureExpr c)
  {
    // if the closure captures any state, then we change the is
    // isImmutable() method added in InitClosures to return false
    ns := c.cls.ns
    falseLiteral := LiteralExpr(c.location, ExprId.falseLiteral, ns.boolType, false)
    c.cls.methodDef("isImmutable").code.stmts.first->expr = falseLiteral
  }

  private static FieldExpr fieldExpr(Location loc, Expr target, CField field)
  {
    // need to make sure all the synthetic field access is direct
    fexpr := FieldExpr(loc, target, field)
    fexpr.useAccessor = false
    return fexpr
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const static Int syntheticFieldFlags:= FConst.Internal | FConst.Storage | FConst.Synthetic

  private MethodDef? method         // current method being processed
  private Location? location        // method.location
  private Bool inClosure            // is method itself a closure doCall body
  private TypeDef? cvars            // cvars class implementation
  private MethodDef? cvarsCtor      // constructor for cvars class
  private MethodVar? cvarsLocal     // local var referencing cvars in method body
  private ClosureExpr[] closures    // acc for closures found in method body

}