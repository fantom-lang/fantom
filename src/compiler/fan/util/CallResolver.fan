//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    5 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** CallResolver handles the process of resolving a CallExpr or
** UnknownVarExpr to a method call or a field access.
**
class CallResolver : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with NameExpr (base class of CallExpr and UnknownVarExpr)
  **
  new make(Compiler compiler, TypeDef curType, MethodDef? curMethod, NameExpr expr)
    : super(compiler)
  {
    this.curType   = curType
    this.curMethod = curMethod
    this.expr      = expr
    this.location  = expr.location
    this.target    = expr.target
    this.name      = expr.name

    call := expr as CallExpr
    if (call != null)
    {
      this.isVar = false
      this.args  = call.args
      this.found = call.method
    }
    else
    {
      this.isVar = true
      this.args  = Expr[,]
    }
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
      if (isStaticLiteral) return result
      resolveBase
      find
      if (result != null) return result
      insertImplicitThisOrIt
      resolveToExpr
      inferClosureType
      resolveForeign
      constantFolding
      castForThisType
      ffiCoercion
      safeToNullable
      return result
    }
    catch (CompilerErr err)
    {
      expr.ctype = ns.error
      return expr
    }
  }

//////////////////////////////////////////////////////////////////////////
// Static Literal
//////////////////////////////////////////////////////////////////////////

  **
  ** If this is a standalone name without a base target
  ** such as "Foo" and the name maps to a type name, then
  ** this is a type literal.
  **
  Bool isStaticLiteral()
  {
    if (target == null && isVar)
    {
      stypes := curType.unit.importedTypes[name]
      if (stypes != null)
      {
        if (stypes.size > 1)
          throw err("Ambiguous type: " + stypes.join(", "), location)
        else
          result = StaticTargetExpr.make(location, stypes.first)
        return true
      }
    }
    return false
  }

//////////////////////////////////////////////////////////////////////////
// Resolve Base
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve the base type which defines the slot we are calling.
  **
  Void resolveBase()
  {
    // if target unspecified, then assume a slot on the current
    // class otherwise the slot must be on the target type
    if (target == null)
    {
      // if we are in a closure - then base is the enclosing class;
      // if closure is it-block when we need to keep track of it too
      if (curType.isClosure)
      {
        base = curType.closure.enclosingType
        if (curType.closure.isItBlock) baseIt = curType.closure.itType
      }
      else
      {
        base = curType
      }
    }
    else
    {
      base = target.ctype
    }

    // if base is the error type, then we already logged an error
    // trying to resolve the target and it's pointless to continue
    if (base === ns.error) throw CompilerErr("ignore", location, null)

    // sanity check
    if (base == null) throw err("Internal error", location)
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  **
  ** Find the method or field with the specified name.
  **
  Void find()
  {
    // if already "found", then skip this step
    if (found != null) return

    // look it up in base type
    found = findOn(base)

    // if we have an it in scope, then also attempt to resolve against it
    if (baseIt != null)
    {
      foundIt := findOn(baseIt)

      // if we found a match on both base and it, that is an error
      if (found != null && foundIt != null)
        throw err("Ambiguous slot '$name' on both 'this' ($base) and 'it' ($baseIt)", location)

      // resolved against implicit it
      if (foundIt != null)
      {
        found = foundIt
        foundOnIt = true
      }
    }

    // if still not found, then error
    if (found == null)
    {
      if (isVar)
      {
        if (target == null)
          throw err("Unknown variable '$name'", location)
        else
          throw err("Unknown slot '$errSig'", location)
      }
      else
      {
        throw err("Unknown method '$errSig'", location)
      }
    }
  }

  private CSlot? findOn(CType base)
  {
    // if base is the error type, short circuit
    if (base === ns.error) return null

    // if simple variable access attempt to lookup as field first,
    // then as method if that fails (only matters in case of FFI)
    if (isVar) return base.field(name) ?: base.method(name)

    // lookup as method
    CSlot? found := base.method(name) ?: base.field(name)

    // if we found a FFI field, then try to lookup a method
    // overloaded by that name; this is a bit hacked b/c since
    // we don't support overloaded methods in the AST we are
    // routing this call to the FFI type (such as JavaType);
    // but this only works if all of our overloads are actually
    // declared by that class (since we don't support overriding
    // overloaded methods we can elimate the interface case)
    if (found is CField && found.isForeign)
      found = found.parent.method(name)

    // if we resolve a method call against a field that is an error
    if (found is CField)
      throw err("Expected method, not field '$errSig'", location)

    return found
  }

  private Str errSig() { return "${base.qname}.${name}" }

//////////////////////////////////////////////////////////////////////////
// Implicit This
//////////////////////////////////////////////////////////////////////////

  **
  ** If the call has no explicit target, and is a instance field
  ** or method, then we need to insert an implicit this or it.
  **
  private Void insertImplicitThisOrIt()
  {
    if (target != null) return
    if (found.isStatic || found.isCtor) return
    if (curMethod.isStatic) return

    if (foundOnIt)
    {
      target = ItExpr.make(location, baseIt)
    }
    else if (curType.isClosure)
    {
      closure := curType.closure
      if (!closure.enclosingSlot.isStatic)
        target = FieldExpr.make(location, ThisExpr.make(location, closure.enclosingType), closure.outerThisField)
    }
    else
    {
      target = ThisExpr.make(location, curType)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Resolve Expr Type
//////////////////////////////////////////////////////////////////////////

  **
  ** Compute the expression type the call itself (what gets left on the stack).
  **
  private Void resolveToExpr()
  {
    if (found is CField)
    {
      result = resolveToFieldExpr
    }
    else
    {
      result = resolveToCallExpr
    }
  }

  private CallExpr resolveToCallExpr()
  {
    method := (CMethod)found

    call := expr as CallExpr
    if (call == null)
    {
      call = CallExpr.make(location)
      call.name   = name
      call.args   = args
    }
    call.target   = target
    call.isSafe   = expr.isSafe
    call.noParens = isVar

    call.method = method
    if (method.isCtor)
      call.ctype = method.parent
    else
      call.ctype = method.returnType

    return call
  }

  private FieldExpr resolveToFieldExpr()
  {
    f := (CField)found

    field := FieldExpr.make(location)
    field.target = target
    field.name   = name
    field.field  = f
    field.ctype  = f.fieldType
    field.isSafe = expr.isSafe

    return field
  }

//////////////////////////////////////////////////////////////////////////
// Infer Closure Type
//////////////////////////////////////////////////////////////////////////

  **
  ** If the last argument to the resolved call is a closure,
  ** then use the method to infer the function type
  **
  private Void inferClosureType()
  {
    if (result is CallExpr)
      result = inferClosureTypeFromCall(result)
  }

  **
  ** If the last argument to the resolved call is a closure,
  ** then use the method to infer the function type.  If the
  ** last arg is a closure, but the call doesn't take a closure,
  ** then translate into an implicit call to Obj.with
  **
  static Expr inferClosureTypeFromCall(CallExpr call)
  {
    // check if last argument is closure
    c := call.args.last as ClosureExpr
    if (c == null) return call

    // if the resolved slot is a method where the last param
    // is expected to be a function type, then use that to
    // infer the type signature of the closure
    lastParam := call.method.params.last?.paramType?.deref?.toNonNullable
    if (lastParam is FuncType)
    {
      if (call.target != null)
        lastParam = ((FuncType)lastParam).parameterizeThis(call.target.ctype)
      c.setInferredSignature(lastParam)
      return call
    }

    // otherwise if the closure is an it-block, we infer
    // its type to be the result of the target expression
    if (c.isItBlock)
    {
      call.args.removeAt(-1)
      return c.toWith(call)
    }
    return call
  }

//////////////////////////////////////////////////////////////////////////
// FFI
//////////////////////////////////////////////////////////////////////////

  **
  ** If we have a FFI call, then give the foreign bridge a chance
  ** to resolve the method and deal with method overloading.  Note
  ** at this point we've already resolved the call by name to *some*
  ** method (in the find step).  But this callback gives the bridge
  ** a chance to resolve to the *correct* overloaded method.  We need
  ** to this during ResolveExpr in order to infer local variables
  ** correctly.
  **
  private Void resolveForeign()
  {
    bridge := found.usesBridge
    if (bridge != null && result is CallExpr)
      result = bridge.resolveCall(result)
  }

//////////////////////////////////////////////////////////////////////////
// Constant Folding
//////////////////////////////////////////////////////////////////////////

  **
  ** If the epxression is a call, check for constant folding.
  **
  private Void constantFolding()
  {
    call := result as CallExpr
    if (call != null)
      result = ConstantFolder.make(compiler).fold(call)
  }

//////////////////////////////////////////////////////////////////////////
// Cast for This Type
//////////////////////////////////////////////////////////////////////////

  **
  ** If the epxression is a call which returns sys::This,
  ** then we need to insert an implicit cast.
  **
  private Void castForThisType()
  {
    // only care about calls that return This
    if (!result.ctype.isThis) return

    // check that we are calling a method
    method := found as CMethod
    if (method == null) return

    // the result of a method which returns This
    // is always the base target type - if we aren't
    // calling against the original declaring type
    // then we also need an implicit cast operation
    result.ctype = base
    if (method.inheritedReturnType != base)
      result = TypeCheckExpr.coerce(result, base) { from = method.inheritedReturnType }
  }

//////////////////////////////////////////////////////////////////////////
// FFI Coercion
//////////////////////////////////////////////////////////////////////////

  **
  ** If this field access or method call returns a type which
  ** isn't directly represented in the Fan type system, then
  ** implicitly coerce it
  **
  private Void ffiCoercion()
  {
    if (result.ctype.isForeign)
    {
      foreign := result.ctype
      inferred := foreign.inferredAs
      if (foreign !== inferred)
      {
        result = foreign.bridge.coerce(result, inferred) |,|
        {
          throw err("Cannot coerce call return to Fan type", location)
        }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Safe to Nullable
//////////////////////////////////////////////////////////////////////////

  **
  ** If the epxression is a safe call using "?.", then
  ** the resulting expression type is nullable.
  **
  private Void safeToNullable()
  {
    if (expr.isSafe)
      result.ctype = result.ctype.toNullable
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  TypeDef curType      // current type of scope
  MethodDef? curMethod // current method of scope
  NameExpr expr        // original expression being resolved
  Location location    // location of original expression
  Expr? target         // target base or null
  Str name             // slot name to resolve
  Bool isVar           // are we resolving simple variable
  Expr[] args          // arguments or null if simple variable
  CType? base          // resolveBase()
  CType? baseIt        // resolveBase()
  CSlot? found         // find()
  Bool foundOnIt       // was find() resolved against it
  Expr? result         // resolveToExpr()

}