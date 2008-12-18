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
// Call Resolution
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve a construction call to a Java constructor.
  **
  override Expr resolveConstruction(CallExpr call)
  {
    // if this is an interop array like IntArray/int[] use make
    // factory otherwise look for Java constructor called <init>
    JavaType base := call.target.ctype
    if (base.isInteropArray)
      call.method = base.method("make")
    else
      call.method = base.method("<init>")

    // call resolution to deal with overloading
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
  ** Resolve a construction chain call where a Fan constructor
  ** calls the super-class constructor.  Type check the arguments
  ** and insert any conversions needed.
  **
  override Expr resolveConstructorChain(CallExpr call)
  {
    // we don't allow chaining to a this ctor for Java FFI
    if (call.target.id !== ExprId.superExpr)
      throw err("Must use super constructor call in Java FFI", call.location)

    // route to a superclass constructor
    JavaType base := call.target.ctype.deref
    call.method = base.method("<init>")

    // call resolution to deal with overloading
    return resolveCall(call)
  }

  **
  ** Resolve a method call: try to find the best match
  ** and apply any coercions needed.
  **
  override CallExpr resolveCall(CallExpr call)
  {
    // try to match against all the overloaded methods
    matches := CallMatch[,]
    CMethod? m := call.method
    while (m != null)
    {
      match := matchCall(call, m)
      if (match != null) matches.add(match)
      m = m is JavaMethod ? ((JavaMethod)m).next : null
    }

    // if we have exactly one match use then use that one
    if (matches.size == 1) return matches[0].apply(call)

    // if we have multiple matches; resolve to
    // most specific match according to JLS rules
    // TODO: this does not correct resolve when using Fan implicit casting
    if (matches.size > 1)
    {
      best := resolveMostSpecific(matches)
      if (best != null) return best.apply(call)
    }

    // zero or multiple ambiguous matches is a compiler error
    s := StrBuf()
    s.add(matches.isEmpty ? "Invalid args " : "Ambiguous call ")
    s.add(call.name).add("(")
    s.add(call.args.join(", ") |Expr arg->Str| { return arg.toTypeStr })
    s.add(")")
    throw err(s.toStr, call.location)
  }

  **
  ** Check if the call matches the specified overload method.
  ** If so return method and coerced args otherwise return null.
  **
  internal CallMatch? matchCall(CallExpr call, CMethod m)
  {
    // first check if have matching numbers of args and params
    args := call.args
    if (m.params.size < args.size) return null

    // check if each argument is ok or can be coerced
    isErr := false
    newArgs := args.dup
    m.params.each |CParam p, Int i|
    {
      if (i >= args.size)
      {
        // param has a default value, then that is ok
        if (!p.hasDefault) isErr = true
      }
      else
      {
        // ensure arg fits parameter type (or auto-cast)
        newArgs[i] = coerce(args[i], p.paramType) |,| { isErr = true }
      }
    }
    if (isErr) return null
    return CallMatch { method = m; args = newArgs }
  }

  **
  ** Given a list of overloaed methods find the most specific method
  ** according to Java Language Specification 15.11.2.2.  The "informal
  ** intuition" rule is that a method is more specific than another
  ** if the first could be could be passed onto the second one.
  **
  internal static CallMatch? resolveMostSpecific(CallMatch[] matches)
  {
    CallMatch? best := matches[0]
    for (i:=1; i<matches.size; ++i)
    {
      x := matches[i]
      if (isMoreSpecific(best, x)) { continue }
      if (isMoreSpecific(x, best)) { best = x; continue }
      return null
    }
    return best
  }

  **
  ** Is 'a' more specific than 'b' such that 'a' could be used
  ** passed to 'b' without a compile time error.
  **
  internal static Bool isMoreSpecific(CallMatch a, CallMatch b)
  {
    return a.method.params.all |CParam ap, Int i->Bool|
    {
      bp := b.method.params[i]
      return ap.paramType.fits(bp.paramType)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  **
  ** Called during Inherit step when a Fan slot overrides a FFI slot.
  ** Log and throw compiler error if there is a problem.
  **
  override Void checkOverride(TypeDef t, CSlot base, SlotDef def)
  {
    // we don't allow Fan to override Java methods with multiple
    // overloaded versions since the Fan type system can't actually
    // override all the overloaded versions
    jslot := base as JavaSlot
    if (jslot?.next != null)
      throw err("Cannot override Java overloaded method: '$jslot.name'", def.location)

    // route to method override checking
    if (base is JavaMethod && def is MethodDef)
      checkMethodOverride(t, base, def)
  }

  **
  ** Called on method/method overrides in the checkOverride callback.
  **
  private Void checkMethodOverride(TypeDef t, JavaMethod base, MethodDef def)
  {
    // bail early if we know things aren't going to work out
    if (base.params.size != def.params.size) return

    // if the return type is primitive or Java array and the
    // Fan declaration matches how it is inferred into the Fan
    // type system, then just change the return type - the compiler
    // will impliclty do all the return coercions
    if (isOverrideInferredType(base.returnType, def.returnType))
    {
      def.ret = def.inheritedRet = base.returnType
    }

    // if any of the parameters is a primitive or Java array
    // and the Fan declaration matches how it is inferred into
    // the Fan type type, then change the parameter type to
    // the Java override type and make the Fan type a local
    // variable:
    //   Java:   void foo(int a) { ... }
    //   Fan:    Void foo(Int a) { ... }
    //   Result: Void foo(int a_$J) { Int a := a_$J; ... }
    //
    base.params.eachr |CParam bp, Int i|
    {
      dp := def.paramDefs[i]
      if (!isOverrideInferredType(bp.paramType, dp.paramType)) return

      // add local variable: Int bar := bar_$J
      local := LocalDefStmt(def.location)
      local.name  = dp.name
      local.ctype = dp.paramType
      local.init  = UnknownVarExpr(def.location, null, dp.name + "_\$J")
      def.code.stmts.insert(0, local)

      // rename parameter Int bar -> int bar_$J
      dp.name = dp.name + "_\$J"
      dp.paramType = bp.paramType
    }
  }

  **
  ** When overriding a Java method check if the base type is
  ** is a Java primitive or array and the override definition is
  ** matches how the Java type is inferred in the Fan type system.
  ** If we have a match return true and we'll swizzle things in
  ** checkMethodOverride.
  **
  static private Bool isOverrideInferredType(CType base, CType def)
  {
    // check if base class slot is a JavaType
    java := base.toNonNullable as JavaType
    def = def.toNonNullable
    if (java != null)
    {
      // we allow primitives and arrays if the override type matches inferred
      if (java.isPrimitive || java.isArray)
        return java.inferredAs == def
    }
    return false
  }

//////////////////////////////////////////////////////////////////////////
// CheckErrors
//////////////////////////////////////////////////////////////////////////

  **
  ** Called during CheckErrors step for a type which extends
  ** a FFI class or implements any FFI mixins.
  **
  override Void checkType(TypeDef def)
  {
    // can't subclass a primitive array like ByteArray/byte[]
    if (def.base.deref is JavaType && def.base.deref->isInteropArray)
    {
      err("Cannot subclass from Java interop array: $def.base", def.location)
      return
    }

    // we don't allow deep inheritance of Java classes because
    // the Fan constructor and Java constructor model don't match
    // up past one level of inheritance
    // NOTE: that that when we remove this restriction we need to
    // test how field initialization works because instance$init
    // is almost certain to break with the current emit design
    javaBase := def.base
    while (javaBase != null && !javaBase.isForeign) javaBase = javaBase.base
    if (javaBase != null && javaBase !== def.base)
    {
      err("Cannot subclass Java class more than one level: $javaBase", def.location)
      return
    }

    // ensure that when we map Fan constructors to Java
    // constructors that we don't have duplicate signatures
    ctors := def.ctorDefs
    ctors.each |MethodDef a, Int i|
    {
      ctors.each |MethodDef b, Int j|
      {
        if (i > j && areParamsSame(a, b))
          err("Duplicate Java FFI constructor signatures: '$b.name' and '$a.name'", a.location)
      }
    }
  }

  **
  ** Do the two methods have the exact same parameter types.
  **
  static Bool areParamsSame(CMethod a, CMethod b)
  {
    if (a.params.size != b.params.size) return false
    for (i:=0; i<a.params.size; ++i)
    {
      if (a.params[i].paramType != b.params[i].paramType)
        return false
    }
    return true
  }

//////////////////////////////////////////////////////////////////////////
// Coercion
//////////////////////////////////////////////////////////////////////////

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
    actual := (JavaType)expr.ctype.toNonNullable

    // if expected is array type
    if (expected is JavaType && ((JavaType)expected).isArray)
      if (actual.arrayOf.fits(((JavaType)expected).arrayOf)) return expr

    // if expected is Obj
    if (expected.isObj) return arrayToList(expr, actual.inferredArrayOf)

    // if expected is list type
    if (expected.toNonNullable is ListType)
    {
      expectedOf := ((ListType)expected.toNonNullable).v
      if (actual.inferredArrayOf.fits(expectedOf)) return arrayToList(expr, expectedOf)
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
    expectedOf := ((JavaType)expected.toNonNullable).inferredArrayOf
    actual := expr.ctype

    // if actual is list type
    if (actual.toNonNullable is ListType)
    {
      actualOf := ((ListType)actual.toNonNullable).v
      if (actualOf.fits(expectedOf))
      {
        // (Foo[])list.asArray(cls)
        clsLiteral := CallExpr.makeWithMethod(loc, null, JavaType.classLiteral(this, expectedOf))
        asArray := CallExpr.makeWithMethod(loc, expr, listAsArray, [clsLiteral])
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
      params = [JavaParam("cls", classType)]
    }
  }

  **
  ** Get a CType representation for 'java.lang.Class'
  **
  once JavaType classType()
  {
    return ns.resolveType("[java]java.lang::Class")
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

**************************************************************************
** CallMatch
**************************************************************************

internal class CallMatch
{
  CallExpr apply(CallExpr call)
  {
    call.args   = args
    call.method = method
    call.ctype  = method.returnType
    return call
  }

  override Str toStr() { return method.signature }

  CMethod method    // matched method
  Expr[] args       // coerced arguments
}