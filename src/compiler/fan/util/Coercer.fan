//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 25  Brian Frank  Pull out from CheckErrors
//

**
** Coercer handles all the logic for type casts
**
class Coercer : CompilerSupport
{
  **
  ** Constructor
  **
  new make(Compiler c) : super(c) {}

  **
  ** Ensure the specified expression is boxed to an object reference.
  **
  Expr box(Expr expr)
  {
    if (expr.ctype.isVal)
      return TypeCheckExpr.coerce(expr, expr.ctype.toNullable)
    else
      return expr
  }

  **
  ** Run the standard coerce method and ensure the result is boxed.
  **
  Expr coerceBoxed(Expr expr, CType expected, |->| onErr)
  {
    return box(coerce(expr, expected, onErr))
  }

  **
  ** Return if `coerce` would not report a compiler error.
  **
  Bool canCoerce(Expr expr, CType expected)
  {
    ok := true
    coerce(expr, expected) |->| { ok = false }
    return ok
  }

  **
  ** Coerce the target expression to the specified type.  If
  ** the expression is not type compatible run the onErr function.
  **
  Expr coerce(Expr expr, CType expected, |->| onErr)
  {
    // route to bridge for FFI coercion if either side if foreign
    if (expected.isForeign) return expected.bridge.coerce(expr, expected, onErr)
    if (expr.ctype.isForeign) return expr.ctype.bridge.coerce(expr, expected, onErr)

    // normal Fantom coercion behavior
    return doCoerce(expr, expected, onErr)
  }

  **
  ** Coerce the target expression to the specified type.  If
  ** the expression is not type compatible run the onErr function.
  ** Default Fantom behavior (no FFI checks).
  **
  Expr doCoerce(Expr expr, CType expected, |->| onErr)
  {
    // sanity check that expression has been typed
    CType actual := expr.ctype
    if ((Obj?)actual == null) throw NullErr("null ctype: ${expr}")

    // if the same type this is easy
    if (actual == expected)
    {
      // unless the expr is a method call with covariant override
      call := expr.asCall
      if (call != null && call.method.isCovariant)
        return coerceInheritedReturns(call, expected)

      return expr
    }

    // if actual type is nothing, then its of no matter
    if (actual.isNothing) return expr

    // we can never use a void expression
    if (actual.isVoid || expected.isVoid)
    {
      onErr()
      return expr
    }

    // if expr is always nullable (null literal, safe invoke, as),
    // then verify expected type is nullable
    if (expr.isAlwaysNullable)
    {
      if (!expected.isNullable) { onErr(); return expr }

      // null literals don't need cast to nullable types,
      // otherwise // fall-thru to apply coercion
      if (expr.id === ExprId.nullLiteral) return expr
    }

    // if the expression fits to type, that is ok
    if (actual.fits(expected))
    {
      // if we have any nullable/value difference we need a coercion
      if (forceCoerce(actual, expected))
        return TypeCheckExpr.coerce(expr, expected)
      else
        return expr
    }

    // if we can auto-cast to make the expr fit then do it - we
    // have to treat function auto-casting a little specially here
    if (actual.isFunc && expected.isFunc)
    {
      if (isFuncAutoCoerce(actual, expected))
        return TypeCheckExpr.coerce(expr, expected)
    }
    else
    {
      if (expected.fits(actual))
        return TypeCheckExpr.coerce(expr, expected)
    }

    // we have an error condition
    onErr()
    return expr
  }

  private Expr coerceInheritedReturns(CallExpr call, CType expected)
  {
    // check force coersion that Java transpiler might require
    // for a covariant overridden method with parameterized collection
    if (forceParameterizedCollectionCoerce(call.method.inheritedReturns, expected))
      return TypeCheckExpr.coerce(call, expected)
    else
      return call
  }

  private Bool isFuncAutoCoerce(CType actualType, CType expectedType)
  {
    // check if both are function types
    if (!actualType.isFunc || !expectedType.isFunc) return false
    actual   := actualType.toNonNullable as FuncType
    expected := expectedType.toNonNullable as FuncType

    // auto-cast to or from unparameterized 'sys::Func'
    if (actual == null || expected == null) return true

    // if actual function requires more parameters than
    // we are expecting, then this cannot be a match
    if (actual.arity > expected.arity) return false

    // check return type
    if (!isFuncAutoCoerceMatch(actual.returns, expected.returns))
      return false

    // check that each parameter is auto-castable
    return actual.params.all |CType actualParam, Int i->Bool|
    {
      expectedParam := expected.params[i]
      return isFuncAutoCoerceMatch(actualParam, expectedParam)
    }

    return true
  }

  private Bool isFuncAutoCoerceMatch(CType actual, CType expected)
  {
    if (actual.fits(expected)) return true
    if (expected.fits(actual)) return true
    if (isFuncAutoCoerce(actual, expected)) return true
    return false
  }

  **
  ** Force a coercion even *after* we have determined that 'from.fits(to)'
  **
  private Bool forceCoerce(CType from, CType to)
  {
    // if either side is a value type and we got past
    // the ctype equals check then we definitely need a coercion
    if (from.isVal || to.isVal) return true

    // configurable handling for parameterized collection types
    if (forceParameterizedCollectionCoerce(from, to))
      return true

    // if going from Obj? -> Obj we need a nullable coercion
    if (!to.isNullable) return from.isNullable

    return false
  }

  **
  ** Configurable handling for parameterized collection types
  **
  private Bool forceParameterizedCollectionCoerce(CType from, CType to)
  {
    needParameterizedCollectionCoerce(from) && needParameterizedCollectionCoerce(to)
  }

}

