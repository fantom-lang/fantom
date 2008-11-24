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
  ** Type check the arguments for the specified method call.
  ** Insert any conversions needed.
  **
  override Void checkCall(CallExpr call)
  {
    // try to match one of the overloaded methods
    JavaMethod? m := call.method
    while (m != null)
    {
      if (matchCall(call, m)) return
      m = m.next
    }

    // if no match this is a argument type error
    s := StrBuf()
    s.add("Invalid args ").add(call.method.name).add("(")
    call.args.each |Expr arg, Int i| { if (i > 0) s.add(", "); s.add(arg.ctype) }
    s.add(")")
    err(s.toStr, call.location)
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

    // if this is a call to a constructor, then we need to create
    // an implicit target for the Java runtime to perform the new
    // opcode to ensure it is on the stack before the arguments (if
    // not already on static type, then let CheckErrors do error
    // reporting)
    if (m.isCtor && call.target.id === ExprId.staticTarget)
    {
      loc := call.location
      newMethod := m.parent->newMethod
      call.target = CallExpr.makeWithMethod(loc, null, newMethod) { synthetic=true }
    }

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

     // use normal Fan coercion behavior
    return super.coerce(expr, expected, onErr)
  }

  **
  ** Coerce a fan expression to a Java primitive (other
  ** than the ones we support natively)
  **
  Expr coerceToPrimitive(Expr expr, CType expected, |,| onErr)
  {
    actual := expr.ctype

    // sys::Int (long) -> int, short, byte
    if (actual.isInt)
    {
      if (expected === primitives.intType ||
          expected === primitives.charType ||
          expected === primitives.shortType ||
          expected === primitives.byteType)
        return TypeCheckExpr.coerce(expr, expected)
    }

    // sys::Float (double) -> float
    if (actual.isFloat)
    {
      if (expected === primitives.floatType)
        return TypeCheckExpr.coerce(expr, expected)
    }

    // no coercion - type error
    onErr()
    return expr
  }

  **
  ** Coerce a Java primitive to a Fan type.
  **
  Expr coerceFromPrimitive(Expr expr, CType expected, |,| onErr)
  {
    actual := expr.ctype

    // int, short, byte -> sys::Int (long)
    if (expected.isInt)
    {
      if (actual === primitives.intType ||
          actual === primitives.charType ||
          actual === primitives.shortType ||
          actual === primitives.byteType)
        return TypeCheckExpr.coerce(expr, expected)
    }

    // float -> sys::Float (float)
    if (expected.isFloat)
    {
      if (actual === primitives.floatType)
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
    loc := expr.location
    actual := (JavaType)expr.ctype
    actualOf := actual.arrayOf

    // if expected is list type
    if (expected.toNonNullable is ListType)
    {
      expectedOf := ((ListType)expected.toNonNullable).v
      if (actualOf.fits(expectedOf))
      {
        // List.make(of, Object[])
        ofExpr := LiteralExpr(loc, ExprId.typeLiteral, ns.typeType, expectedOf)
        return CallExpr.makeWithMethod(loc, null, listMakeFromArray, [ofExpr, expr])
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