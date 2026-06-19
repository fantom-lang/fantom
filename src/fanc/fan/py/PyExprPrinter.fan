//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Feb 2026  Trevor Adelman  Creation
//

using compiler

**
** PyExprPrinter generates Python expressions from Fantom AST nodes.
**
** Key Patterns:
**   - Primitives (Int, Str, Bool, Float) use static dispatch: sys.Int.plus(x, y)
**   - List/Map use instance dispatch: list.each(f) (NOT primitives)
**   - Closures wrap in Func.make_closure() for Fantom Func API (bind, params, etc.)
**   - Safe navigation (?.) uses lambda wrapper: ((lambda _safe_: ... if _safe_ is not None else None)(target))
**   - ObjUtil handles cross-type operations: equals, compare, typeof, is_, as_
**
** Dispatch Priority in call():
**   1. Safe navigation check (?.method())
**   2. cvar wrapper detection (closure variable wrappers)
**   3. Dynamic call (-> operator) via ObjUtil.trap()
**   4. Func.call() / Func.callList() -> direct invocation
**   5. ObjUtil methods (equals, compare, typeof, etc.)
**   6. Primitive type static dispatch (Int, Str, etc.)
**   7. Private method static dispatch (non-virtual)
**   8. Normal instance/static method call
**
** See design.md in this directory for full documentation.
**
class PyExprPrinter : PyPrinter
{
  new make(PyPrinter parent) : super.make(parent.m.out)
  {
    this.m = parent.m
  }

  ** Print an expression
  Void expr(Expr e)
  {
    switch (e.id)
    {
      case ExprId.nullLiteral:     nullLiteral
      case ExprId.trueLiteral:     trueLiteral
      case ExprId.falseLiteral:    falseLiteral
      case ExprId.intLiteral:      intLiteral(e)
      case ExprId.floatLiteral:    floatLiteral(e)
      case ExprId.strLiteral:      strLiteral(e)
      case ExprId.listLiteral:     listLiteral(e)
      case ExprId.mapLiteral:      mapLiteral(e)
      case ExprId.rangeLiteral:    rangeLiteral(e)
      case ExprId.durationLiteral: durationLiteral(e)
      case ExprId.decimalLiteral:  decimalLiteral(e)
      case ExprId.uriLiteral:      uriLiteral(e)
      case ExprId.localVar:        localVar(e)
      case ExprId.thisExpr:        thisExpr
      case ExprId.superExpr:       superExpr(e)
      case ExprId.call:            call(e)
      case ExprId.construction:    construction(e)
      case ExprId.field:           field(e)
      case ExprId.assign:          assign(e)
      case ExprId.same:            same(e)
      case ExprId.notSame:         notSame(e)
      case ExprId.boolNot:         boolNot(e)
      case ExprId.boolOr:          boolOr(e)
      case ExprId.boolAnd:         boolAnd(e)
      case ExprId.cmpNull:         cmpNull(e)
      case ExprId.cmpNotNull:      cmpNotNull(e)
      case ExprId.isExpr:          isExpr(e)
      case ExprId.isnotExpr:       isnotExpr(e)
      case ExprId.asExpr:          asExpr(e)
      case ExprId.coerce:          coerce(e)
      case ExprId.ternary:         ternary(e)
      case ExprId.elvis:           elvis(e)
      case ExprId.shortcut:        shortcut(e)
      case ExprId.closure:         closure(e)
      case ExprId.staticTarget:    staticTarget(e)
      case ExprId.typeLiteral:     typeLiteral(e)
      case ExprId.slotLiteral:     slotLiteral(e)
      case ExprId.itExpr:          itExpr(e)
      case ExprId.throwExpr:       throwExpr(e)
      case ExprId.unknownVar:      unknownVar(e)
      default:
        throw UnsupportedErr("Unhandled expr type: $e.id")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  private Void nullLiteral() { none }

  private Void trueLiteral() { true_ }

  private Void falseLiteral() { false_ }

  private Void intLiteral(LiteralExpr e) { w(e.val) }

  private Void floatLiteral(LiteralExpr e) { w(e.val) }

  private Void strLiteral(LiteralExpr e) { str(e.val) }

  private Void listLiteral(ListLiteralExpr e)
  {
    // Cast to ListType to get element type directly (no try/catch, no dynamic dispatch)
    lt := (ListType)((CType)(e.explicitType ?: e.ctype)).deref
    sysPrefix()
    w("List.from_literal([")
    e.vals.each |val, i|
    {
      if (i > 0) w(", ")
      expr(val)
    }
    w("], ")
    str(lt.v.signature)
    w(")")
  }

  private Void mapLiteral(MapLiteralExpr e)
  {
    // Cast to MapType to get key/value types directly (no try/catch, no dynamic dispatch)
    mt := (MapType)(e.explicitType ?: e.ctype)
    sysPrefix()
    w("Map.from_literal([")
    e.keys.each |key, i|
    {
      if (i > 0) w(", ")
      expr(key)
    }
    w("], [")
    e.vals.each |val, i|
    {
      if (i > 0) w(", ")
      expr(val)
    }
    w("], ")
    str(mt.k.signature)
    w(", ")
    str(mt.v.signature)
    w(")")
  }

  private Void rangeLiteral(RangeLiteralExpr e)
  {
    // Generate Range.make(start, end, exclusive)
    sysPrefix()
    w("Range.make(")
    expr(e.start)
    w(", ")
    expr(e.end)
    if (e.exclusive)
      w(", True")
    w(")")
  }

  private Void durationLiteral(LiteralExpr e)
  {
    // Duration literal - value is in nanoseconds
    dur := e.val as Duration
    sysPrefix()
    if (dur != null)
      w("Duration.make(").w(dur.ticks).w(")")
    else
      w("Duration.make(0)")
  }

  private Void decimalLiteral(LiteralExpr e)
  {
    // Decimal literal (5d suffix) - emit as Decimal.make("value")
    // Matches JS transpiler pattern: sys.Decimal.make(value)
    // Use string constructor to preserve precision for large values
    val := e.val.toStr
    sysPrefix()
    w("Decimal.make(\"").w(val).w("\")")
  }

  private Void uriLiteral(LiteralExpr e)
  {
    // URI literal `http://example.com` -> Uri.from_str("http://example.com")
    uri := e.val as Uri
    sysPrefix()
    if (uri != null)
      w("Uri.from_str(").str(uri.toStr).w(")")
    else
      w("Uri.from_str(").str(e.val.toStr).w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Variables
//////////////////////////////////////////////////////////////////////////

  private Void localVar(LocalVarExpr e) { w(escapeName(e.var.name)) }

  private Void thisExpr() { w("self") }

  private Void superExpr(SuperExpr e) { w("super()") }

  private Void itExpr(Expr e)
  {
    // "it" is the implicit closure parameter - output as "it"
    w("it")
  }

  ** Unresolved variable reference -- output target.name if target present (matches ES compiler)
  private Void unknownVar(Expr e)
  {
    uv := e as UnknownVarExpr
    if (uv.target != null) { expr(uv.target); w(".") }
    w(escapeName(uv.name))
  }

  private Void throwExpr(Expr e)
  {
    // throw as an expression (used in elvis, ternary, etc.)
    // Python's `raise` is a statement, so we use a helper function
    // ObjUtil.throw_(err) raises the exception and never returns
    te := e as ThrowExpr
    w("ObjUtil.throw_(")
    expr(te.exception)
    w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Calls
//////////////////////////////////////////////////////////////////////////

  private Void call(CallExpr e)
  {
    methodName := e.method.name

    // Dispatch priority chain (see class doc)
    if (e.isSafe && e.target != null)                                                     { callSafe(e); return }
    if (e.isDynamic)                                                                      { callDynamic(e); return }
    // All sys::Func methods handled here: call/callList -> direct invocation,
    // enterCtor/exitCtor/checkInCtor -> no-op (compiler-injected const protection)
    if (e.method.parent.qname == "sys::Func")
    {
      if (methodName == "call" || methodName == "callList")                               { callFunc(e); return }
      if (methodName == "enterCtor" || methodName == "exitCtor" || methodName == "checkInCtor")
                                                                                          { w("None"); return }
    }
    if (e.target != null && isObjUtilMethod(e.method))                                    { objUtilCall(e); return }
    if (e.target != null && isPrimitiveType(e.target.ctype) && e.target.id != ExprId.staticTarget)
                                                                                          { primitiveCall(e); return }
    if (e.method.isPrivate && !e.method.isStatic && !e.method.isCtor)                     { callPrivate(e); return }

    // Normal instance/static method call -- resolve target prefix
    callNormal(e)
  }

  ** Safe navigation: ((lambda _safe_: None if _safe_ is None else <body>)(target))
  private Void callSafe(CallExpr e)
  {
    w("((lambda _safe_: None if _safe_ is None else ")
    safeCallBody(e)
    w(")(")
    expr(e.target)
    w("))")
  }

  ** Dynamic call (-> operator): ObjUtil.trap(target, name, args)
  ** targetWriter overrides how the target is written (used by safeCallBody for _safe_)
  private Void callDynamic(CallExpr e, |->|? targetWriter := null)
  {
    w("ObjUtil.trap(")
    if (targetWriter != null) targetWriter()
    else if (e.target != null) expr(e.target)
    else w("self")
    w(", ").str(e.name)
    if (e.args.isEmpty)
    {
      w(", None)")
    }
    else
    {
      w(", [")
      writeArgs(e.args)
      w("])")
    }
  }

  ** Func.call/callList -> direct Python invocation
  private Void callFunc(CallExpr e)
  {
    if (e.target != null) expr(e.target)
    w("(")
    if (e.method.name == "callList" && !e.args.isEmpty)
    {
      w("*")
      expr(e.args.first)
    }
    else
    {
      writeArgs(e.args)
    }
    w(")")
  }

  ** Private method -> static dispatch: ClassName.method(self/target, args)
  private Void callPrivate(CallExpr e)
  {
    w(PyUtil.escapeTypeName(e.method.parent.name)).w(".").w(escapeName(e.method.name)).w("(")
    if (e.target != null)
      expr(e.target)
    else if (!m.inStaticContext)
      w("self")
    if ((e.target != null || !m.inStaticContext) && !e.args.isEmpty) w(", ")
    writeArgs(e.args)
    w(")")
  }

  ** Normal method call -- resolve target prefix then emit name(args)
  private Void callNormal(CallExpr e)
  {
    if (e.target != null)
    {
      expr(e.target)
      w(".")
    }
    else if (e.method.isStatic)
    {
      writeTypeRef(e.method.parent.pod.name, PyUtil.escapeTypeName(e.method.parent.name))
      w(".")
    }
    else if (m.inStaticContext)
    {
      w(PyUtil.escapeTypeName(e.method.parent.name)).w(".")
    }
    else if (e.method.isPrivate && !e.method.isCtor)
    {
      // Duplicate private check (reached when private method not caught above)
      callPrivate(e)
      return
    }
    else
    {
      w("self.")
    }
    w(escapeName(e.method.name))
    w("(")
    writeArgs(e.args)
    w(")")
  }

  ** Check if method should be routed through ObjUtil
  ** These are Obj/Num methods that may be called on primitives coerced to Obj or Num
  private Bool isObjUtilMethod(CMethod m)
  {
    // All sys::Obj methods route through ObjUtil (matches ES compiler)
    if (m.parent.isObj) return true

    // Force equals/compare through ObjUtil for NaN-aware semantics
    // even when resolved to a specific type (matches ES compiler)
    name := m.name
    if (name == "equals" || name == "compare") return true

    // Num methods on Num-typed values (Python has no Num.py for static dispatch)
    if (m.parent.isNum)
      return name == "toFloat" || name == "toInt" || name == "toDecimal" || name == "toLocale"

    // Decimal.toLocale on Decimal-typed values
    if (m.parent.isDecimal) return name == "toLocale"

    return false
  }

  ** Output ObjUtil method call: x.method() -> ObjUtil.method(x)
  ** targetWriter overrides how the target is written (used by safeCallBody for _safe_)
  private Void objUtilCall(CallExpr e, |->|? targetWriter := null)
  {
    pyName := escapeName(e.method.name)

    w("ObjUtil.").w(pyName).w("(")
    if (targetWriter != null) targetWriter()
    else expr(e.target)
    if (!e.args.isEmpty)
    {
      e.args.each |arg|
      {
        w(", ")
        expr(arg)
      }
    }
    w(")")
  }

  ** Map of Fantom primitive type qnames to their Python wrapper class names.
  ** Primitives use static dispatch: x.method() -> sys.Type.method(x)
  ** List and Map are NOT primitives -- they use normal instance dispatch.
  ** Matches ES compiler pmap: Bool, Decimal, Float, Int, Str
  private static const Str:Str primitiveMap :=
  [
    "sys::Bool":    "Bool",
    "sys::Int":     "Int",
    "sys::Float":   "Float",
    "sys::Decimal": "Float",  // Decimal uses Float methods in Python
    "sys::Str":     "Str",
  ]

  ** Check if type is a primitive that needs static method calls
  private Bool isPrimitiveType(CType? t)
  {
    if (t == null) return false
    return primitiveMap.containsKey(t.toNonNullable.signature)
  }

  ** Write "sys." prefix when current pod is NOT the sys pod.
  ** This is the standard pattern for qualifying sys pod types from non-sys code.
  private Void sysPrefix()
  {
    if (m.curType?.pod?.name != "sys")
      w("sys.")
  }

  ** Hand-written sys types that use Python @property for instance fields.
  ** These types use property assignment (self.x = v) not method-call setters (self.x(v)).
  ** Derived from: grep -l "@property" fan/src/sys/py/fan/*.py
  private static const Str[] handWrittenSysTypes :=
  [
    "sys::Depend",  // @property (version, isPlus, etc.)
    "sys::Endian",  // @property
    "sys::List",    // read-write @property (capacity)
    "sys::Locale",  // @property
    "sys::Map",     // read-write @property (def_, ordered, caseInsensitive)
    "sys::StrBuf",  // read-only @property (charset)
    "sys::Type",    // read-only @property (root, v, k, params, ret)
  ]

  ** Check if type is a hand-written sys type that uses Python @property
  private Bool isHandWrittenSysType(Str qname) { handWrittenSysTypes.contains(qname) }


  ** Get Python wrapper class name for primitive type
  private Str primitiveClassName(CType t)
  {
    return primitiveMap.get(t.toNonNullable.signature, t.name)
  }

  ** Write a pod-qualified type reference.
  ** Handles same-pod (dynamic import), sys-to-non-sys (sys. prefix),
  ** cross-pod (dynamic import), and same-pod-sys (bare name).
  private Void writeTypeRef(Str targetPod, Str typeName)
  {
    curPod := m.curType?.pod?.name
    if (curPod != null && curPod != "sys" && curPod == targetPod)
    {
      // Same pod, non-sys - use dynamic import to avoid circular imports
      podPath := PyUtil.podImport(targetPod)
      w("__import__('${podPath}.${typeName}', fromlist=['${typeName}']).${typeName}")
    }
    else if (targetPod == "sys" && curPod != "sys")
    {
      // Sys pod type from non-sys pod - use sys. prefix
      w("sys.").w(typeName)
    }
    else if (targetPod != "sys" && curPod != null && curPod != targetPod)
    {
      // Cross-pod reference (non-sys to non-sys) - use dynamic import
      podPath := PyUtil.podImport(targetPod)
      w("__import__('${podPath}.${typeName}', fromlist=['${typeName}']).${typeName}")
    }
    else
    {
      // Same pod (sys) or already imported directly
      w(typeName)
    }
  }

  ** Write comma-separated argument expressions
  private Void writeArgs(Expr[] args)
  {
    args.each |arg, i|
    {
      if (i > 0) w(", ")
      expr(arg)
    }
  }

  ** Output primitive type static method call: x.method() -> sys.Type.method(x)
  ** targetWriter overrides how the target is written (used by safeCallBody for _safe_)
  private Void primitiveCall(CallExpr e, |->|? targetWriter := null)
  {
    className := primitiveClassName(e.target.ctype)
    methodName := escapeName(e.method.name)

    sysPrefix()
    w(className).w(".").w(methodName).w("(")
    if (targetWriter != null) targetWriter()
    else expr(e.target)
    if (!e.args.isEmpty)
    {
      e.args.each |arg|
      {
        w(", ")
        expr(arg)
      }
    }
    w(")")
  }

  ** Generate the body of a safe call using _safe_ as the target variable.
  ** Delegates to the same dispatch methods as call() but writes _safe_ instead of expr(e.target).
  private Void safeCallBody(CallExpr e)
  {
    safeTarget := |->| { w("_safe_") }

    if (e.isDynamic)                                                                         { callDynamic(e, safeTarget); return }
    if (e.target != null && isPrimitiveType(e.target.ctype) && e.target.id != ExprId.staticTarget)
                                                                                             { primitiveCall(e, safeTarget); return }
    if (e.target != null && isObjUtilMethod(e.method))                                       { objUtilCall(e, safeTarget); return }

    // Regular instance method call: _safe_.method(args)
    w("_safe_.").w(escapeName(e.method.name)).w("(")
    writeArgs(e.args)
    w(")")
  }

  ** Generate the body of a safe field access using _safe_ as the target variable
  ** This is called from within a lambda wrapper: ((lambda _safe_: None if _safe_ is None else <body>)(target))
  private Void safeFieldBody(FieldExpr e)
  {
    fieldName := e.field.name

    // useAccessor=false means direct storage access (&field syntax)
    // In Python, backing fields use _fieldName pattern
    if (!e.useAccessor && !e.field.isStatic)
      w("_safe_._").w(escapeName(fieldName))
    else
    {
      w("_safe_.").w(escapeName(fieldName))
      // Instance fields on transpiled types need () for accessor method
      if (!e.field.isStatic)
      {
        parentSig := e.field.parent.qname
        if (!isHandWrittenSysType(parentSig))
          w("()")
      }
    }
  }

  private Void construction(CallExpr e)
  {
    // Constructor call - always use factory pattern: ClassName.make(args)
    writeTypeRef(e.method.parent.pod.name, PyUtil.escapeTypeName(e.method.parent.name))

    // Always call the factory method: .make() or .fromStr() etc.
    factoryName := e.method.name == "<ctor>" ? "make" : e.method.name
    w(".").w(escapeName(factoryName))

    w("(")
    writeArgs(e.args)
    w(")")
  }

  ** Check if a field expression is accessing .val on a Wrap$ wrapper variable
  ** If so, return the original variable name; null otherwise
  ** Works for both outer scope (wrapper name -> original name via map) and
  ** inner closure scope (variable already has original name from capture)
  private Str? isWrapValAccess(FieldExpr e)
  {
    // Must be accessing field named "val" on a synthetic Wrap$ type
    if (e.field.name != "val") return null
    parentType := e.field.parent
    if (!parentType.isSynthetic || !parentType.name.startsWith("Wrap\$")) return null

    // Target must be a local variable
    if (e.target == null || e.target.id != ExprId.localVar) return null
    localTarget := e.target as LocalVarExpr
    varName := localTarget.var.name

    // Check if this is a known wrapper variable (outer scope: wrapper_name -> original_name)
    origName := m.getNonlocalOriginal(varName)
    if (origName != null) return origName

    // Inside closures, the variable already has the original name (from captured field)
    // If the field parent is Wrap$ and field is val, strip the field access regardless
    return varName
  }

  private Void field(FieldExpr e)
  {
    fieldName := e.field.name

    // Intercept Wrap$.val field access -- output the original variable name
    // instead of wrapper._val (we use nonlocal instead of cvar wrappers)
    origName := isWrapValAccess(e)
    if (origName != null)
    {
      w(escapeName(origName))
      return
    }

    // Handle safe navigation operator (?.): short-circuit to null if target is null
    // Pattern: ((lambda _safe_: None if _safe_ is None else _safe_.field)(<target>))
    if (e.isSafe && e.target != null)
    {
      w("((lambda _safe_: None if _safe_ is None else ")
      safeFieldBody(e)
      w(")(")
      expr(e.target)
      w("))")
      return
    }

    // Primitive field access uses static dispatch, same as method calls
    // e.g., str.size -> sys.Str.size(str) because Python str has no .size property
    if (e.target != null && isPrimitiveType(e.target.ctype))
    {
      className := primitiveClassName(e.target.ctype)
      sysPrefix()
      w(className).w(".").w(escapeName(fieldName)).w("(")
      expr(e.target)
      w(")")
      return
    }

    // Check for $this field (outer this capture in closures)
    if (fieldName == "\$this")
    {
      // Inside closure, $this refers to outer self
      // Multi-statement closures use _self, inline lambdas use _outer
      if (m.inClosureWithOuter)
        w("_outer")
      else
        w("_self")
      return
    }

    // Check for captured local variable: pattern varName$N
    // Fantom creates synthetic fields like js$0, expected$2 for captured locals
    if (fieldName.contains("\$"))
    {
      idx := fieldName.index("\$")
      if (idx != null && idx < fieldName.size - 1)
      {
        suffix := fieldName[idx+1..-1]
        // Check if suffix is all digits
        if (!suffix.isEmpty && suffix.all |c| { c.isDigit })
        {
          // This is a captured local variable - output just the base name
          // If we are in a closure, we use the base name to capture from outer scope
          baseName := fieldName[0..<idx]
          w(escapeName(baseName))
          return
        }
      }
    }

    if (e.target != null)
    {
      expr(e.target)
      w(".")
    }
    else if (e.field.isStatic)
    {
      // Static field without explicit target - need class prefix
      writeTypeRef(e.field.parent.pod.name, PyUtil.escapeTypeName(e.field.parent.name))
      w(".")
    }

    // useAccessor=false means direct storage access (&field syntax)
    // In Python, backing fields use _fieldName pattern
    // Only add underscore prefix for instance fields, not static accessors
    if (!e.useAccessor && !e.field.isStatic)
      w("_").w(escapeName(e.field.name))
    else
    {
      w(escapeName(e.field.name))
      // Static fields always need () - they're class methods
      // Instance fields on hand-written sys types use @property (no parens)
      // Instance fields on transpiled types use accessor methods (need parens)
      if (e.field.isStatic)
      {
        w("()")
      }
      else
      {
        // For instance fields, check if parent type is a hand-written sys type
        // Hand-written types use @property, transpiled types use accessor methods
        parentSig := e.field.parent.qname
        if (!isHandWrittenSysType(parentSig))
          w("()")
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Assignment
//////////////////////////////////////////////////////////////////////////

  private Void assign(BinaryExpr e)
  {
    // Special handling for field assignment
    if (e.lhs.id == ExprId.field)
    {
      fieldExpr := e.lhs as FieldExpr

      // Intercept Wrap$.val assignment -- assign to the original variable
      // instead of wrapper._val (we use nonlocal instead of cvar wrappers)
      origName := isWrapValAccess(fieldExpr)
      if (origName != null)
      {
        if (e.leave)
        {
          // Assignment used as expression: (var := value)
          w("(")
          w(escapeName(origName))
          w(" := ")
          expr(e.rhs)
          w(")")
        }
        else
        {
          w(escapeName(origName))
          w(" = ")
          expr(e.rhs)
        }
        return
      }

      // When leave=true, the assignment result is used as an expression value.
      // Python doesn't support `=` in expression context, so we use a helper.
      // This mirrors the JS transpiler's IIFE pattern for field assignments.
      if (e.leave)
      {
        w("ObjUtil.setattr_return(")
        if (fieldExpr.target != null)
          expr(fieldExpr.target)
        else
          w("self")
        w(", \"")
        // Use _fieldName for backing storage (non-accessor) or fieldName for accessor
        if (!fieldExpr.useAccessor)
          w("_")
        w(escapeName(fieldExpr.field.name))
        w("\", ")
        expr(e.rhs)
        w(")")
        return
      }

      // Check if we should use accessor (count = 5) vs direct storage (&count = 5)
      if (fieldExpr.useAccessor)
      {
        // Determine whether to use method call syntax or property assignment:
        // - Hand-written sys types (Map, Type, etc.) use @property -> property assignment
        // - Transpiled types use def field(self, _val_=None): -> method call syntax
        parentSig := fieldExpr.field.parent.qname
        useMethodCall := !isHandWrittenSysType(parentSig)

        if (useMethodCall)
        {
          // Use method call syntax: target.fieldName(value)
          if (fieldExpr.target != null)
          {
            expr(fieldExpr.target)
            w(".")
          }
          w(escapeName(fieldExpr.field.name))
          w("(")
          expr(e.rhs)
          w(")")
        }
        else
        {
          // Use Python property assignment: self.fieldName = value
          // This works with @property decorated getters/setters on hand-written types
          if (fieldExpr.target != null)
          {
            expr(fieldExpr.target)
            w(".")
          }
          w(escapeName(fieldExpr.field.name))
          w(" = ")
          expr(e.rhs)
        }
      }
      else
      {
        // Direct storage access: self._count = value or ClassName._count for static
        if (fieldExpr.target != null)
        {
          expr(fieldExpr.target)
          w(".")
        }
        else if (fieldExpr.field.isStatic)
        {
          // Static field without explicit target - need class prefix
          w(PyUtil.escapeTypeName(fieldExpr.field.parent.name)).w(".")
        }
        w("_").w(escapeName(fieldExpr.field.name))
        w(" = ")
        expr(e.rhs)
      }
    }
    else
    {
      // Local var assignment - use walrus operator to make it an expression
      // This allows assignment inside function calls, conditions, etc.
      w("(")
      expr(e.lhs)
      w(" := ")
      expr(e.rhs)
      w(")")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Comparison
//////////////////////////////////////////////////////////////////////////

  private Void same(BinaryExpr e)
  {
    // Use ObjUtil.same() for consistent identity semantics
    // Python's 'is' operator is unreliable with interned literals
    w("ObjUtil.same(")
    expr(e.lhs)
    w(", ")
    expr(e.rhs)
    w(")")
  }

  private Void notSame(BinaryExpr e)
  {
    // Use ObjUtil.same() for consistent identity semantics
    w("(not ObjUtil.same(")
    expr(e.lhs)
    w(", ")
    expr(e.rhs)
    w("))")
  }

  private Void cmpNull(UnaryExpr e)
  {
    expr(e.operand)
    w(" is None")
  }

  private Void cmpNotNull(UnaryExpr e)
  {
    expr(e.operand)
    w(" is not None")
  }

//////////////////////////////////////////////////////////////////////////
// Boolean Operators
//////////////////////////////////////////////////////////////////////////

  private Void boolNot(UnaryExpr e)
  {
    w("not ")
    expr(e.operand)
  }

  private Void boolOr(CondExpr e)
  {
    w("(")
    e.operands.each |op, i|
    {
      if (i > 0) w(" or ")
      expr(op)
    }
    w(")")
  }

  private Void boolAnd(CondExpr e)
  {
    w("(")
    e.operands.each |op, i|
    {
      if (i > 0) w(" and ")
      expr(op)
    }
    w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Type Checks
//////////////////////////////////////////////////////////////////////////

  private Void isExpr(TypeCheckExpr e)
  {
    w("ObjUtil.is_(")
    expr(e.target)
    w(", ")
    typeRef(e.check)
    w(")")
  }

  private Void isnotExpr(TypeCheckExpr e)
  {
    w("(not ObjUtil.is_(")
    expr(e.target)
    w(", ")
    typeRef(e.check)
    w("))")
  }

  private Void asExpr(TypeCheckExpr e)
  {
    w("ObjUtil.as_(")
    expr(e.target)
    w(", ")
    typeRef(e.check)
    w(")")
  }

  private Void coerce(TypeCheckExpr e)
  {
    w("ObjUtil.coerce(")
    expr(e.target)
    w(", ")
    typeRef(e.check)
    w(")")
  }

  private Void typeRef(CType t)
  {
    // Sanitize Java FFI types so they're valid Python strings
    // (they'll fail at runtime if actually used, like JS transpiler)
    sig := PyUtil.sanitizeJavaFfi(t.signature)
    str(sig)
  }

//////////////////////////////////////////////////////////////////////////
// Ternary / Elvis
//////////////////////////////////////////////////////////////////////////

  private Void ternary(TernaryExpr e)
  {
    w("(")
    // Handle assignments in ternary using walrus operator
    ternaryBranch(e.trueExpr)
    w(" if ")
    expr(e.condition)
    w(" else ")
    ternaryBranch(e.falseExpr)
    w(")")
  }

  ** Output ternary branch, converting assignments to walrus operator
  private Void ternaryBranch(Expr e)
  {
    // Unwrap coerce if present
    inner := unwrapCoerce(e)

    // If it's an assignment, convert x = val to (x := val)
    if (inner.id == ExprId.assign)
    {
      assign := inner as BinaryExpr
      // For field assignments, fall back to regular expr (can't use walrus)
      if (assign.lhs.id == ExprId.field)
      {
        expr(e)
        return
      }
      // Use walrus operator for local var assignment
      w("(")
      expr(assign.lhs)
      w(" := ")
      expr(assign.rhs)
      w(")")
    }
    else
    {
      expr(e)
    }
  }

  private Void elvis(BinaryExpr e)
  {
    // a ?: b -> (lambda v: v if v is not None else b)(a)
    w("((lambda _v: _v if _v is not None else ")
    expr(e.rhs)
    w(")(")
    expr(e.lhs)
    w("))")
  }

//////////////////////////////////////////////////////////////////////////
// Shortcuts (operators)
//////////////////////////////////////////////////////////////////////////

  private Void shortcut(ShortcutExpr e)
  {
    // First, try operator maps for binary operators
    binaryOp := PyUtil.binaryOperators.get(e.method.qname)
    if (binaryOp != null)
    {
      doShortcutBinaryOp(e, binaryOp)
      return
    }

    // Try unary operators
    unaryOp := PyUtil.unaryOperators.get(e.method.qname)
    if (unaryOp != null)
    {
      w(unaryOp)
      expr(e.target)
      return
    }

    // Fall back to switch for special cases
    op := e.op
    switch (op)
    {
      case ShortcutOp.eq:
        // Use ObjUtil for NaN-aware comparison (NaN == NaN should be true)
        // This matches JS transpiler behavior which uses ObjUtil.compareNE/compareEQ
        if (e.opToken == Token.notEq)
          comparison(e, "compare_ne")
        else
          comparison(e, "equals")
        return
      case ShortcutOp.cmp:
        // Check the opToken for comparison type
        switch (e.opToken)
        {
          case Token.lt:   comparison(e, "compare_lt")
          case Token.ltEq: comparison(e, "compare_le")
          case Token.gt:   comparison(e, "compare_gt")
          case Token.gtEq: comparison(e, "compare_ge")
          default:         comparison(e, "compare")  // <=>
        }
      case ShortcutOp.negate:    w("(-"); expr(e.target); w(")")
      case ShortcutOp.increment: increment(e)
      case ShortcutOp.decrement: decrement(e)
      case ShortcutOp.get:       indexGet(e)
      case ShortcutOp.set:       indexSet(e)
      // Fallback for arithmetic ops if not in map
      case ShortcutOp.plus:      doShortcutBinaryOp(e, "+")
      case ShortcutOp.minus:     doShortcutBinaryOp(e, "-")
      case ShortcutOp.mult:      doShortcutBinaryOp(e, "*")
      case ShortcutOp.div:       divOp(e)  // Use ObjUtil.div for Fantom semantics (truncated)
      case ShortcutOp.mod:       modOp(e)  // Use ObjUtil.mod for Fantom semantics (truncated)
      default:                   throw UnsupportedErr("Unhandled shortcut operator: $op")
    }
  }

  private Void doShortcutBinaryOp(ShortcutExpr e, Str op)
  {
    // String + non-string: route to Str.plus for proper type conversion
    if (op == "+" && !e.isAssign && isStringPlusNonString(e))
    {
      stringPlusNonString(e)
      return
    }

    // Compound assignment (x *= 3 -> x = x * 3)
    if (e.isAssign)
    {
      compoundAssign(e, op)
      return
    }

    // Simple binary op
    w("(")
    expr(e.target)
    w(" ").w(op).w(" ")
    expr(e.args.first)
    w(")")
  }

  ** Compound assignment dispatch: handles local vars, fields, Wrap$.val, and index access
  private Void compoundAssign(ShortcutExpr e, Str op)
  {
    target := unwrapCoerce(e.target)

    if (target.id == ExprId.localVar)
    {
      localExpr := target as LocalVarExpr
      varName := escapeName(localExpr.var.name)
      // String += null needs Str.plus
      if (isStringPlusNullAssign(e))
      {
        w("(").w(varName).w(" := ")
        sysPrefix()
        w("Str.plus(").w(varName).w(", ")
        expr(e.args.first)
        w("))")
      }
      else
      {
        w("(").w(varName).w(" := (").w(varName).w(" ").w(op).w(" ")
        expr(e.args.first)
        w("))")
      }
    }
    else if (target.id == ExprId.field)
    {
      fieldExpr := target as FieldExpr
      // Wrap$.val -> treat as local variable
      origName := isWrapValAccess(fieldExpr)
      if (origName != null)
      {
        varName := escapeName(origName)
        w("(").w(varName).w(" := (").w(varName).w(" ").w(op).w(" ")
        expr(e.args.first)
        w("))")
      }
      else
      {
        // Normal field: target._field = target._field op value
        escapedName := escapeName(fieldExpr.field.name)
        if (fieldExpr.target != null) { expr(fieldExpr.target); w(".") }
        w("_").w(escapedName).w(" = ")
        if (fieldExpr.target != null) { expr(fieldExpr.target); w(".") }
        w("_").w(escapedName).w(" ").w(op).w(" ")
        expr(e.args.first)
      }
    }
    else if (target.id == ExprId.shortcut)
    {
      shortcutTarget := target as ShortcutExpr
      if (shortcutTarget.op == ShortcutOp.get)
        indexCompoundAssign(shortcutTarget, op, e.args.first)
      else
      {
        w("("); expr(e.target); w(" ").w(op).w(" "); expr(e.args.first); w(")")
      }
    }
    else
    {
      // Fallback
      w("("); expr(e.target); w(" ").w(op).w(" "); expr(e.args.first); w(")")
    }
  }

  ** Check if this is a string + non-string pattern that needs Str.plus()
  ** In Fantom, string + anything converts the other operand to string
  ** Also handles nullable strings (Str?) which might be null at runtime
  private Bool isStringPlusNonString(ShortcutExpr e)
  {
    // If neither is a string, no special handling needed
    targetIsStr := e.target?.ctype?.toNonNullable?.isStr ?: false
    argIsStr := e.args.first?.ctype?.toNonNullable?.isStr ?: false

    if (!targetIsStr && !argIsStr) return false

    // If one is string and other is NOT string, use Str.plus for conversion
    if (targetIsStr && !argIsStr) return true
    if (argIsStr && !targetIsStr) return true

    // Both are strings - but check if either is nullable (might be null at runtime)
    // Python can't do "str" + None, so we need Str.plus for null handling
    targetIsNullable := e.target?.ctype?.isNullable ?: false
    argIsNullable := e.args.first?.ctype?.isNullable ?: false

    if (targetIsNullable || argIsNullable) return true

    // Both are non-null strings - use native Python concatenation
    return false
  }

  ** Check if this is a string += null compound assignment pattern
  private Bool isStringPlusNullAssign(ShortcutExpr e)
  {
    // Check if RHS is null
    if (e.args.first?.id != ExprId.nullLiteral) return false

    // Check if target is string type
    return e.target?.ctype?.toNonNullable?.isStr ?: false
  }

  ** Handle string + non-string concatenation using sys.Str.plus()
  private Void stringPlusNonString(ShortcutExpr e)
  {
    sysPrefix()
    w("Str.plus(")
    expr(e.target)
    w(", ")
    expr(e.args.first)
    w(")")
  }

  ** Handle indexed compound assignment: x[i] += val -> x[i] = x[i] + val
  private Void indexCompoundAssign(ShortcutExpr indexExpr, Str op, Expr value)
  {
    // Generate: container[index] = container[index] op value
    // We need to evaluate container and index only once in case they have side effects
    // For simplicity, generate: target[index] = target[index] op value

    expr(indexExpr.target)
    w("[")
    expr(indexExpr.args.first)
    w("] = ")
    expr(indexExpr.target)
    w("[")
    expr(indexExpr.args.first)
    w("] ").w(op).w(" ")
    expr(value)
  }

  private Void comparison(ShortcutExpr e, Str method)
  {
    w("ObjUtil.").w(method).w("(")
    expr(e.target)
    w(", ")
    expr(e.args.first)
    w(")")
  }

  private Void divOp(ShortcutExpr e)
  {
    // Float division uses Python / directly (no truncation issue)
    if (e.target?.ctype?.toNonNullable?.isFloat ?: false)
    {
      doShortcutBinaryOp(e, "/")
      return
    }
    // Int division uses ObjUtil.div for truncated division semantics
    // (Python // is floor division, Fantom uses truncated toward zero)
    objUtilOp(e, "div")
  }

  private Void modOp(ShortcutExpr e)
  {
    // Use ObjUtil.mod for Fantom-style modulo semantics
    // (truncated division vs Python's floor division)
    objUtilOp(e, "mod")
  }

  ** Emit ObjUtil.{method}(target, arg) with compound assignment support
  private Void objUtilOp(ShortcutExpr e, Str method)
  {
    // Compound assignment to local var: x /= y -> (x := ObjUtil.div(x, y))
    if (e.isAssign)
    {
      target := unwrapCoerce(e.target)
      if (target.id == ExprId.localVar)
      {
        localExpr := target as LocalVarExpr
        varName := escapeName(localExpr.var.name)
        w("(").w(varName).w(" := ObjUtil.").w(method).w("(").w(varName).w(", ")
        expr(e.args.first)
        w("))")
        return
      }
    }
    // Simple call or non-local compound assignment fallback
    w("ObjUtil.").w(method).w("(")
    expr(e.target)
    w(", ")
    expr(e.args.first)
    w(")")
  }

  ** Unwrap coerce expressions to get the underlying expression
  private Expr unwrapCoerce(Expr e)
  {
    if (e.id == ExprId.coerce)
    {
      te := e as TypeCheckExpr
      return unwrapCoerce(te.target)
    }
    return e
  }

//////////////////////////////////////////////////////////////////////////
// Increment / Decrement
//////////////////////////////////////////////////////////////////////////

  // Python has no ++ or -- operators. We generate different code depending on target:
  //   - Local vars: walrus operator (x := x + 1) for pre, tuple trick for post
  //   - Fields: ObjUtil.inc_field(obj, "_name") / ObjUtil.inc_field_post(...)
  //   - Index: ObjUtil.inc_index(container, key) / ObjUtil.inc_index_post(...)
  //
  // Post-increment/decrement returns the OLD value (before modification).
  // Pre-increment/decrement returns the NEW value (after modification).

  private Void increment(ShortcutExpr e) { incDec(e, "+", "inc") }

  private Void decrement(ShortcutExpr e) { incDec(e, "-", "dec") }

  ** Unified increment/decrement: op is "+" or "-", prefix is "inc" or "dec"
  ** Pre (++x/--x) returns new value, post (x++/x--) returns old value
  private Void incDec(ShortcutExpr e, Str op, Str prefix)
  {
    target := unwrapCoerce(e.target)
    isPost := e.isPostfixLeave

    if (target.id == ExprId.field)
    {
      fieldExpr := target as FieldExpr

      // Check for Wrap$.val -- treat as local variable
      origName := isWrapValAccess(fieldExpr)
      if (origName != null)
      {
        varName := escapeName(origName)
        if (isPost)
        {
          w("((_old_").w(varName).w(" := ").w(varName).w(", ")
          w(varName).w(" := ").w(varName).w(" ").w(op).w(" 1, ")
          w("_old_").w(varName).w(")[2])")
        }
        else
        {
          w("(").w(varName).w(" := ").w(varName).w(" ").w(op).w(" 1)")
        }
        return
      }

      // Normal field access - use ObjUtil helper
      method := isPost ? "${prefix}_field_post" : "${prefix}_field"
      w("ObjUtil.").w(method).w("(")
      if (fieldExpr.target != null)
        expr(fieldExpr.target)
      else
        w("self")
      w(", \"_").w(escapeName(fieldExpr.field.name)).w("\")")
    }
    else if (target.id == ExprId.shortcut)
    {
      // Index access (list[i]++/--) - use ObjUtil helper
      shortcutExpr := target as ShortcutExpr
      if (shortcutExpr.op == ShortcutOp.get)
      {
        method := isPost ? "${prefix}_index_post" : "${prefix}_index"
        w("ObjUtil.").w(method).w("(")
        expr(shortcutExpr.target)
        w(", ")
        expr(shortcutExpr.args.first)
        w(")")
      }
      else
      {
        w("(")
        expr(e.target)
        w(" ").w(op).w(" 1)")
      }
    }
    else if (target.id == ExprId.localVar)
    {
      localExpr := target as LocalVarExpr
      varName := escapeName(localExpr.var.name)
      if (isPost)
      {
        // Post: return old value via tuple trick: ((_old := x, x := x +/- 1, _old)[2])
        w("((_old_").w(varName).w(" := ").w(varName).w(", ")
        w(varName).w(" := ").w(varName).w(" ").w(op).w(" 1, ")
        w("_old_").w(varName).w(")[2])")
      }
      else
      {
        w("(").w(varName).w(" := ").w(varName).w(" ").w(op).w(" 1)")
      }
    }
    else
    {
      // Fallback - just apply op (won't assign but won't error)
      w("(")
      expr(e.target)
      w(" ").w(op).w(" 1)")
    }
  }

  private Void indexGet(ShortcutExpr e)
  {
    // Check target type for special handling
    targetType := e.target?.ctype?.toNonNullable
    arg := e.args.first
    argType := arg.ctype?.toNonNullable

    // String indexing: str[i] returns Int codepoint, str[range] returns substring
    if (targetType?.isStr ?: false)
    {
      if (argType?.isRange ?: false)
      {
        // str[range] -> sys.Str.get_range(str, range)
        sysPrefix()
        w("Str.get_range(")
        expr(e.target)
        w(", ")
        expr(arg)
        w(")")
      }
      else
      {
        // str[i] -> sys.Str.get(str, i) returns Int codepoint
        sysPrefix()
        w("Str.get(")
        expr(e.target)
        w(", ")
        expr(arg)
        w(")")
      }
      return
    }

    // Check if index is a Range - need to use sys.List.get_range() instead
    if (argType?.isRange ?: false)
    {
      // list[range] -> sys.List.get_range(list, range)
      sysPrefix()
      w("List.get_range(")
      expr(e.target)
      w(", ")
      expr(arg)
      w(")")
    }
    else
    {
      expr(e.target)
      w("[")
      expr(arg)
      w("]")
    }
  }

  private Void indexSet(ShortcutExpr e)
  {
    expr(e.target)
    w("[")
    expr(e.args.first)
    w("] = ")
    expr(e.args[1])
  }

//////////////////////////////////////////////////////////////////////////
// Static Targets and Type Literals
//////////////////////////////////////////////////////////////////////////

  private Void staticTarget(StaticTargetExpr e)
  {
    writeTypeRef(e.ctype.pod.name, PyUtil.escapeTypeName(e.ctype.name))
  }

  private Void typeLiteral(LiteralExpr e)
  {
    // Type literal like Bool# - create a Type instance
    t := e.val as CType
    if (t != null)
    {
      sig := PyUtil.sanitizeJavaFfi(t.signature)
      sysPrefix()
      w("Type.find(").str(sig).w(")")
    }
    else
    {
      w("None")
    }
  }

  private Void slotLiteral(SlotLiteralExpr e)
  {
    // Slot literal like Int#plus - create Method.find() or Field.find()
    // Use original Fantom name (not snake_case) - Type.slot() handles the conversion
    parentSig := e.parent.signature
    slotName := e.name  // Keep original Fantom camelCase name

    // Determine if it's a method or field
    if (e.slot != null && e.slot is CField)
    {
      sysPrefix()
      w("Field.find(").str("${parentSig}.${slotName}").w(")")
    }
    else
    {
      // Default to Method
      sysPrefix()
      w("Method.find(").str("${parentSig}.${slotName}").w(")")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  private Void closure(ClosureExpr e)
  {
    // Check if this closure was already registered during scan phase
    closureId := m.findClosureId(e)
    if (closureId != null)
    {
      // Already emitted as def, just output reference
      w("_closure_${closureId}")
      return
    }

    // Try various fields for closure body
    Block? codeBlock := null
    if (e.doCall != null && e.doCall.code != null)
      codeBlock = e.doCall.code
    else if (e.call != null && e.call.code != null)
      codeBlock = e.call.code
    else if (e.code != null)
      codeBlock = e.code

    if (codeBlock != null)
    {
      stmts := codeBlock.stmts

      // Single-statement closures can use inline lambda
      // Filter out local var decls, synthetic/void return statements
      realStmts := stmts.findAll |s|
      {
        if (s.id == StmtId.returnStmt)
        {
          ret := s as ReturnStmt
          return ret.expr != null
        }
        if (s.id == StmtId.localDef) return false
        return true
      }

      // Check if simple single-expression body (can use lambda)
      // Assignments cannot be in lambdas - they're statements, not expressions
      if (realStmts.size == 1)
      {
        stmt := realStmts.first
        if (stmt.id == StmtId.returnStmt)
        {
          ret := stmt as ReturnStmt
          // Skip if return contains assignment or index set
          if (ret.expr != null && !isAssignmentExpr(ret.expr))
          {
            closureLambda(e) |->| { expr(ret.expr) }
            return
          }
        }
        // Handle throw statement - convert to ObjUtil.throw_() for lambda
        if (stmt.id == StmtId.throwStmt)
        {
          throwStmt := stmt as ThrowStmt
          closureLambda(e) |->|
          {
            w("ObjUtil.throw_(")
            expr(throwStmt.exception)
            w(")")
          }
          return
        }
        if (stmt.id == StmtId.expr)
        {
          exprStmt := stmt as ExprStmt
          // Assignments can't be in lambda body (unless we convert them)
          if (!isAssignmentExpr(exprStmt.expr))
          {
            closureLambda(e) |->| { expr(exprStmt.expr) }
            return
          }
          // Check if it's an index set: map[key] = value
          // Can convert to: map.__setitem__(key, value) for lambda
          if (exprStmt.expr.id == ExprId.shortcut)
          {
            se := exprStmt.expr as ShortcutExpr
            if (se.op == ShortcutOp.set && se.args.size == 2)
            {
              closureLambda(e) |->|
              {
                expr(se.target)
                w(".__setitem__(")
                expr(se.args.first)  // key
                w(", ")
                expr(se.args[1])     // value
                w(")")
              }
              return
            }
          }
        }
      }
    }

    // Fallback - wrap with Func.make_closure() even when body not handled
    // This ensures ALL closures have bind(), params(), etc. (consistent with JS transpiler)
    closureLambda(e) |->| { none }
  }

  ** Generate lambda with outer self capture if needed
  ** Uses Func.make_closure() for proper Fantom Func methods (bind, params, etc.)
  private Void closureLambda(ClosureExpr e, |->| body)
  {
    // Check if closure captures outer this (has $this field)
    needsOuter := e.cls?.fieldDefs?.any |f| { f.name == "\$this" } ?: false

    // Get type info from signature
    sig := e.signature as FuncType

    // Determine immutability from compiler analysis
    immutCase := m.closureImmutability(e)

    // Generate Func.make_closure(spec, lambda)
    sysPrefix()
    w("Func.make_closure({")

    // Returns type
    retType := sig?.returns?.signature ?: "sys::Void"
    w("\"returns\": ").str(retType).w(", ")

    // Immutability case from compiler analysis
    w("\"immutable\": ").str(immutCase).w(", ")

    // Params (sanitize Java FFI type signatures)
    w("\"params\": [")
    if (e.doCall?.params != null)
    {
      e.doCall.params.each |p, i|
      {
        if (i > 0) w(", ")
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
    w("]}, ")

    // Lambda body
    if (needsOuter)
    {
      w("(lambda ")
      closureParams(e)
      w(", _outer=self: ")
      m.inClosureWithOuter = true
      body()
      m.inClosureWithOuter = false
      w(")")
    }
    else
    {
      w("(lambda ")
      closureParams(e)
      w(": ")
      body()
      w(")")
    }

    w(")")  // Close Func.make_closure()
  }

  ** Check if expression is an assignment (can't be in lambda body)
  ** Note: Increment/decrement CAN be in lambdas because they transpile to
  ** ObjUtil.incField()/decField() which are function calls returning values
  private Bool isAssignmentExpr(Expr e)
  {
    // Direct assignment
    if (e.id == ExprId.assign) return true

    // Index set (list[i] = x)
    if (e.id == ExprId.shortcut)
    {
      se := e as ShortcutExpr
      if (se.op == ShortcutOp.set) return true
      // Compound assignment (x += 5), but NOT increment/decrement
      // Increment/decrement transpile to ObjUtil.incField() which returns a value
      if (se.isAssign && se.op != ShortcutOp.increment && se.op != ShortcutOp.decrement)
        return true
    }

    // Check wrapped in coerce
    if (e.id == ExprId.coerce)
    {
      tc := e as TypeCheckExpr
      return isAssignmentExpr(tc.target)
    }

    return false
  }

  private Void closureParams(ClosureExpr e)
  {
    // Get the signature - this is the EXPECTED type (what the target method wants)
    // which may have fewer params than declared in source code (Fantom allows coercion)
    sig := e.signature as FuncType
    expectedParamCount := sig?.params?.size ?: 0

    // Use doCall.params for parameter names, but LIMIT to expected count
    // This handles cases where closure declares extra params that get coerced away
    // ALL params get =None default because Python (unlike JS) requires all args
    // JS: f(a,b) called as f() gives a=undefined, b=undefined
    // Python: f(a,b) called as f() raises TypeError
    if (e.doCall?.params != null && !e.doCall.params.isEmpty)
    {
      // Only output up to expectedParamCount params (or all if signature unavailable)
      maxParams := expectedParamCount > 0 ? expectedParamCount : e.doCall.params.size
      actualCount := e.doCall.params.size.min(maxParams)

      actualCount.times |i|
      {
        if (i > 0) w(", ")
        w(escapeName(e.doCall.params[i].name)).w("=None")
      }

      // If no params were output but we need at least one for lambda syntax
      // Use _=None so it doesn't require an argument
      if (actualCount == 0 && expectedParamCount == 0)
        w("_=None")
    }
    // Fallback to signature for it-blocks with implicit it
    else
    {
      if (sig != null && !sig.params.isEmpty)
      {
        // Check if this is an it-block (uses implicit it)
        if (e.isItBlock)
        {
          w("it=None")
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
          }
        }
      }
      else
      {
        w("_=None")  // Lambda needs placeholder but shouldn't require arg
      }
    }
  }
}
