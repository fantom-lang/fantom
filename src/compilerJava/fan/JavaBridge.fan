//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaBridge is the compiler plugin for bringing Java
** classes into the Fan type system.
**
@compilerBridge="java"
class JavaBridge : CBridge
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a JavaBridge for current environment
  **
  new make(Compiler c)
    : super(c)
  {
    this.cp = ClassPath.makeForCurrent
  }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Map a FFI "podName" to a Java package.
  **
  override CPod resolvePod(Str name, Location? loc)
  {
    // the empty package is used to represent primitives
    if (name == "") return primitives

    // look for package name in classpatch
    classes := cp.classes[name]
    if (classes == null)
      throw CompilerErr("Java package '$name' not found", loc)

    // map package to JavaPod
    return JavaPod(this, name, classes)
  }

//////////////////////////////////////////////////////////////////////////
// AST
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve a construction call to a Java constructor.
  **
  override CallExpr resolveConstruction(CallExpr call)
  {
    // if this is an interop array like IntArray/int[] use make
    // factory otherwise look for Java constructor called <init>
    JavaType base := call.target.ctype
    if (base.isInteropArray)
      call.method = base.method("make")
    else
      call.method = base.method("<init>")

    // do normal call resolution to deal with overloading
    call = resolveCall(call)

    // we need to create an implicit target for the Java runtime
    // to perform the new opcode to ensure it is on the stack
    // before the args (we don't do this for interop Array classes)
    if (!base.isInteropArray)
    {
      loc := call.location
      call.target = CallExpr.makeWithMethod(loc, null, base.newMethod) { synthetic=true }
    }

    return call
  }

  **
  ** Resolve a method call: try to find the best match
  ** and apply any coercions needed.
  **
  override CallExpr resolveCall(CallExpr call)
  {
    // try to match one of the overloaded methods
    JavaMethod? m := call.method
    while (m != null)
    {
      if (matchCall(call, m)) return call
      m = m.next
    }

    // if no match this is a argument type error
    s := StrBuf()
    s.add("Invalid args ").add(call.name).add("(")
    call.args.each |Expr arg, Int i| { if (i > 0) s.add(", "); s.add(arg.ctype) }
    s.add(")")
    throw err(s.toStr, call.location)
  }

  **
  ** Check if the call matches the specified overload method.
  **
  Bool matchCall(CallExpr call, JavaMethod m)
  {
    // first check if have matching numbers of args and params
    args := call.args
    if (m.params.size != args.size) return false

    // check if each argument is ok or can be coerced
    isErr := false
    newArgs := args.dup
    m.params.each |JavaParam p, Int i|
    {
      // ensure arg fits parameter type (or auto-cast)
      newArgs[i] = coerce(args[i], p.paramType) |,| { isErr = true }
    }
    if (isErr) return false

    // if we have a match, then update the call args with coercions
    // and update the return type with the specified method we matched
    call.args   = newArgs
    call.method = m
    call.ctype  = m.returnType
    return true
  }

  **
  ** Coerce expression to expected type.  If not a type match
  ** then run the onErr function.
  **
  override Expr coerce(Expr expr, CType expected, |,| onErr)
  {
    // handle easy case
    actual := expr.ctype
    if (actual == expected) return expr

    // handle Fan to Java primitives
    if (expected.pod == primitives)
      return coerceToPrimitive(expr, expected, onErr)

    // handle Java primitives to Fan
    if (actual.pod == primitives)
      return coerceFromPrimitive(expr, expected, onErr)

    // handle Java array to Fan list
    if (actual.name[0] == '[')
      return coerceFromArray(expr, expected, onErr)

    // handle Fan list to Java array
    if (expected.name[0] == '[')
      return coerceToArray(expr, expected, onErr)

     // use normal Fan coercion behavior
    return super.coerce(expr, expected, onErr)
  }

  **
  ** Coerce a fan expression to a Java primitive (other
  ** than the ones we support natively)
  **
  Expr coerceToPrimitive(Expr expr, JavaType expected, |,| onErr)
  {
    actual := expr.ctype

    // sys::Int (long) -> int, short, byte
    if (actual.isInt && expected.isPrimitiveIntLike)
      return TypeCheckExpr.coerce(expr, expected)

    // sys::Float (double) -> float
    if (actual.isFloat && expected.isPrimitiveFloat)
      return TypeCheckExpr.coerce(expr, expected)

    // no coercion - type error
    onErr()
    return expr
  }

  **
  ** Coerce a Java primitive to a Fan type.
  **
  Expr coerceFromPrimitive(Expr expr, CType expected, |,| onErr)
  {
    actual := (JavaType)expr.ctype

    // int, short, byte -> sys::Int (long)
    if (actual.isPrimitiveIntLike)
    {
      if (expected.isInt || expected.isObj)
        return TypeCheckExpr.coerce(expr, expected)
    }

    // float -> sys::Float (float)
    if (actual.isPrimitiveFloat)
    {
      if (expected.isFloat || expected.isObj)
        return TypeCheckExpr.coerce(expr, expected)
    }

    // no coercion - type error
    onErr()
    return expr
  }

  **
  ** Coerce a Java array to a Fan list.
  **
  Expr coerceFromArray(Expr expr, CType expected, |,| onErr)
  {
    actual := (JavaType)expr.ctype
    actualOf := actual.arrayOf

    // if expected is Obj
    if (expected.isObj) return arrayToList(expr, actualOf)

    // if expected is list type
    if (expected.toNonNullable is ListType)
    {
      expectedOf := ((ListType)expected.toNonNullable).v
      if (actualOf.fits(expectedOf)) return arrayToList(expr, expectedOf)
    }

    // no coercion available
    onErr()
    return expr
  }

  **
  ** Generate List.make(of, expr) where expr is Object[]
  **
  private Expr arrayToList(Expr expr, CType of)
  {
    loc := expr.location
    ofExpr := LiteralExpr(loc, ExprId.typeLiteral, ns.typeType, of)
    return CallExpr.makeWithMethod(loc, null, listMakeFromArray, [ofExpr, expr])
  }

  **
  ** Coerce a Fan list to Java array.
  **
  Expr coerceToArray(Expr expr, CType expected, |,| onErr)
  {
    loc := expr.location
    expectedOf := ((JavaType)expected).arrayOf
    actual := expr.ctype

    // if actual is list type
    if (actual.toNonNullable is ListType)
    {
      actualOf := ((ListType)actual.toNonNullable).v
      if (actualOf.fits(expectedOf))
      {
        // (Foo[])list.asArray()
        asArray := CallExpr.makeWithMethod(loc, expr, listAsArray)
        return TypeCheckExpr.coerce(asArray, expected)
      }
    }

    // no coercion available
    onErr()
    return expr
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  **
  ** Get a CMethod representation for 'List.make(Type, Object[])'
  **
  once CMethod listMakeFromArray()
  {
    return JavaMethod
    {
      parent = ns.listType
      name = "make"
      flags = FConst.Public | FConst.Static
      returnType = ns.listType
      params =
      [
        JavaParam("of", ns.typeType),
        JavaParam("array", objectArrayType)
      ]
    }
  }

  **
  ** Get a CMethod representation for 'Object[] List.asArray()'
  **
  once CMethod listAsArray()
  {
    return JavaMethod
    {
      parent = ns.listType
      name = "asArray"
      flags = FConst.Public
      returnType = objectArrayType
      params = JavaParam[,]
    }
  }

  **
  ** Get a CType representation for 'java.lang.Object[]'
  **
  once JavaType objectArrayType()
  {
    return ns.resolveType("[java]java.lang::[Object")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly JavaPrimitives primitives := JavaPrimitives(this)
  readonly ClassPath cp

}