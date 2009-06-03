//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jan 07  Brian Frank  Creation
//

**
** CurryResolver handles the process of resolving a CurryExpr.
**
class CurryResolver : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor
  **
  new make(Compiler compiler, TypeDef curType, Int curryCount, CurryExpr expr)
    : super(compiler)
  {
    this.loc        = expr.location
    this.curType    = curType
    this.curryCount = curryCount
    this.expr       = expr
    this.call       = (CallExpr)expr.operand
    this.method     = call.method
  }

//////////////////////////////////////////////////////////////////////////
// Resolve
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve into a method call or field access
  **
  Expr resolve()
  {
    try
    {
      // curry on Func instance uses reflection Func.curry
      if (call.target != null && method.qname.startsWith("sys::Func.call"))
        return reflection

      // generate method signature
      genSignature

      // optimize static with no partials
      if (method.isStatic && call.args.isEmpty)
        return simpleStatic

      // define curry type Curry$xx used to store partial
      // arguments as fields and implement the curried method
      defineCurry
      return mapCurry
    }
    catch (CompilerErr err)
    {
      expr.ctype = ns.error
      return expr
    }
  }

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  **
  ** Define the signature of the curries method which
  ** is any partial parameters left incomplete.
  **
  Void genSignature()
  {
    // if more arguments were provided than parameters
    if (call.args.size > method.params.size)
      throw err("Too many arguments for curry", loc)

    // get the incomplete CParams
    incompletes := method.params[call.args.size..-1]

    // map incomplete CParams to CTypes
    CType[] params := incompletes.map |CParam p->CType| { p.paramType }

    // map incomplete CParams to names
    Str[] names := incompletes.map |CParam p->Str| { p.name }

    // check if we have an instance method with no target, in that
    // case then this must be passed as first argument to curried function
    thisIsParam = !method.isStatic && (call.target == null || call.target.id == ExprId.staticTarget)
    if (thisIsParam)
    {
      params.insert(0, method.parent)
      names.insert(0, "\$this")
    }

    // define the signature
    sig = FuncType.make(params, names, method.returnType)
  }

//////////////////////////////////////////////////////////////////////////
// Simple Static
//////////////////////////////////////////////////////////////////////////

  **
  ** If the curry is a static method with no arguments, then
  ** really it isn't a curry per se, because we can optimize
  ** to just a method lookup.
  **
  Expr simpleStatic()
  {
    // replace curry with Slot.findMethod
    result := CallExpr.makeWithMethod(loc, null, ns.slotFindFunc)
    result.args.add(LiteralExpr.make(loc, ExprId.strLiteral, ns.strType, method.qname))
    result.ctype = sig
    return result
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  **
  ** Calling curry on a Func instance is just
  ** syntax sugar for calling Func.curry
  **
  Expr reflection()
  {
    loc := call.location
    arg := call.args

    // replace with Func.curry(args)
    result := CallExpr.makeWithMethod(loc, call.target, ns.funcCurry)
    if (method.name == "callList")
      result.args = call.args
    else
      result.args = [ListLiteralExpr.makeFor(call.location, ns.objType.toListOf, call.args)]

    // compute curried signature from orig func type
    targetType := call.target.ctype
    if (targetType is FuncType)
    {
      orig := targetType as FuncType
      result.ctype = FuncType.make(
        orig.params[arg.size..-1],
        orig.names[arg.size..-1],
        orig.ret)
    }
    else if (targetType.fits(ns.funcType))
    {
      result.ctype = targetType
    }
    else
    {
      throw err("Unexpected target for curry $call.target.ctype", loc)
    }

    return result
  }

//////////////////////////////////////////////////////////////////////////
// Define Curry
//////////////////////////////////////////////////////////////////////////

  **
  ** Define a synthetic class called Curry$xx.
  **
  Void defineCurry()
  {
    // define curry class
    curry = TypeDef.make(ns, loc, curType.unit, "Curry\$${curryCount}")
    curry.flags = FConst.Internal | FConst.Synthetic
    curry.base  = sig
    curry.curry = expr
    addTypeDef(curry)

    // define ctor
    ctor = MethodDef.make(loc, curry)
    ctor.flags = FConst.Ctor | FConst.Internal | FConst.Synthetic
    ctor.name  = "make"
    ctor.ret   = ns.voidType
    ctor.code  = Block.make(loc)
    curry.addSlot(ctor)

    // override Func.method
    fm := MethodDef.make(loc, curry)
    fm.flags = FConst.Public | FConst.Override | FConst.Synthetic
    fm.name  = "method"
    fm.ret   = ns.methodType
    fm.code  = Block.make(loc)
    expr := CallExpr.makeWithMethod(loc, null, ns.slotFindMethod)
    expr.args.add(LiteralExpr.make(loc, ExprId.strLiteral, ns.strType, method.qname))
    fm.code.add(ReturnStmt.makeSynthetic(loc, expr))
    curry.addSlot(fm)
  }

//////////////////////////////////////////////////////////////////////////
// Map Curry
//////////////////////////////////////////////////////////////////////////

  **
  ** For each argument specified we need to pass to the constructor
  ** and stash away and in a field for use in redirecting to the
  ** target method.
  **
  Expr mapCurry()
  {
    // this is our redirect to the method call to be used in Func.call
    doCall := CallExpr.makeWithMethod(loc, null, method);

    // these are the arguments to provided to curried function
    args := call.args.dup
    allArgsConst := true

    // figure out if there is an implied this parameter to curry, if
    // so then we need to include this in the implied arguments
    Expr? self := null
    if (!method.isStatic && call.target != null && call.target.id != ExprId.staticTarget)
      args.insert(0, self = call.target)

    // for each partial argument:
    //   - add field to curry class
    //   - add parameter to constructor
    //   - store field in constructor
    //   - load field in doCall
    args.each |Expr expr, Int i|
    {
      // name and type of argument
      name := "p$i"
      ctype := expr.ctype

      // keep track if all our args are const
      if (!ctype.isConst)
        allArgsConst = false

      // add field to curry class
      field := FieldDef.make(loc, curry)
      field.name  = name
      field.flags = FConst.Internal | FConst.Storage | FConst.Synthetic
      field.fieldType = ctype
      curry.addSlot(field)

      // add parameter to ctor
      ctor.params.add(ParamDef.make(loc, ctype, name))

      // add field set assignment statement in ctor
      lhs := FieldExpr.make(loc, ThisExpr.make(loc), field, false)
      rhs := UnknownVarExpr.make(loc, null, name)
      assign := BinaryExpr.makeAssign(lhs, rhs)
      ctor.code.stmts.add(assign.toStmt)

      // add field get to doCall statement
      loadField := FieldExpr.make(loc, ThisExpr.make(loc), field, false)
      if (expr === self)
        doCall.target = loadField
      else
        doCall.args.add(loadField)
    }

    // finish ctor
    ctor.code.stmts.add(ReturnStmt.makeSynthetic(loc))

    // Method.callX()
    InitClosures.genMethodCall(compiler, loc, curry, sig, doCall, thisIsParam)

    // generate isImmutable method
    InitClosures.genIsImmutableMethod(compiler, loc, curry, allArgsConst)

    // replace curry with call to CurryXX.make
    result := CallExpr.makeWithMethod(loc, null, ctor)
    result.args = args
    result.ctype = sig
    return result
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Location loc       // location of curry expr
  private TypeDef curType    // current enclosing type
  private Int curryCount     // total number of curries in compilation unit
  private CurryExpr expr     // curry expr being resolved
  private CallExpr call      // call operand of curry
  private CMethod method     // target method
  private FuncType? sig      // signature of result
  private Bool thisIsParam   // is the "this" target of method incomplete
  private TypeDef? curry     // curry implementation class
  private MethodDef? ctor    // curry implementation class ctor

}