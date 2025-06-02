//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split from JavaPrinter
//

using compiler

**
** Java transpiler printer for expressions
**
internal class JavaExprPrinter : JavaPrinter, ExprPrinter
{
  new make(JavaPrinter parent) : super(parent) {}

  override JavaPrinterState m() { super.m }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  override This nullLiteral(LiteralExpr x) { w("null") }

  override This trueLiteral(LiteralExpr x) { w("true") }

  override This falseLiteral(LiteralExpr x) { w("false") }

  override This intLiteral(LiteralExpr x) { w(x.val).w("L") }

  override This floatLiteral(LiteralExpr x) { w(x.val).w("D") }

  override This decimalLiteral(LiteralExpr x) { w("new java.math.BigDecimal(").str(x.val).w(")") }

  override This strLiteral(LiteralExpr x) { str(x.val) }

  override This uriLiteral(LiteralExpr x) { w("fan.sys.Uri.fromStr(").str(x.val).w(")") }

  override This durationLiteral(LiteralExpr x)
  {
    dur := (Duration)x.val
    return w("fan.sys.Duration.make(").w(dur.ticks).w("L)")
  }

  override This typeLiteral(LiteralExpr x)
  {
    doTypeLiteral(x.val)
  }

  private This doTypeLiteral(CType t)
  {
    if (t.pod.name == "sys")
    {
      if (t.isParameterized)
        qnType.w(".find(").str(t.signature).w(")")
      else
        qnSys.w(".").w(t.name).w("Type")
    }
    else
    {
      typeSig(t).w(".typeof\$()")
    }
    if (t.isNullable) w(".toNullable()")
    return this
  }

  override This slotLiteral(SlotLiteralExpr x)
  {
    find := x.slot is CField ? "field" : "method"
    doTypeLiteral(x.parent).w(".").w(find).w("(").str(x.name).w(")")
    return this
  }

  override This rangeLiteral(RangeLiteralExpr x)
  {
    return w("fan.sys.Range.")
          .w(x.exclusive ? "makeExclusive" : "makeInclusive")
          .w("(").expr(x.start).w(", ").expr(x.end).w(")")
  }

  override This listLiteral(ListLiteralExpr x)
  {
    type := (ListType)x.ctype
    qnList.w(".make(").doTypeLiteral(type.v).w(", ").w(x.vals.size).w(")")
    x.vals.each |item|
    {
      w(".add(").expr(item).w(")")
    }
    return this
  }

  override This mapLiteral(MapLiteralExpr x)
  {
    type := (MapType)x.ctype
    qnMap.w(".makeKV(").doTypeLiteral(type.k).w(", ").doTypeLiteral(type.v).w(")")
    x.keys.each |key, i|
    {
      val := x.vals[i]
      w(".set(").expr(key).w(", ").expr(val).w(")")
    }
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Compare / Type Checks
//////////////////////////////////////////////////////////////////////////

  override This notExpr(UnaryExpr x) { unaryExpr("!", x.operand) }

  override This compareNullExpr(UnaryExpr x) { oparen.expr(x.operand).w(" == null").cparen }

  override This compareNotNullExpr(UnaryExpr x) { oparen.expr(x.operand).w(" != null").cparen }

  override This sameExpr(BinaryExpr x) { binaryExpr(x.lhs, "==", x.rhs) }

  override This notSameExpr(BinaryExpr x) { binaryExpr(x.lhs, "!=", x.rhs) }

  override This orExpr(CondExpr x) { condExpr("||", x.operands) }

  override This andExpr(CondExpr x) { condExpr("&&", x.operands) }

  override This isExpr(TypeCheckExpr x)
  {
    check := x.check
    if (check.isParameterized)
      qnOpUtil.w(".is(").expr(x.target).w(", ").doTypeLiteral(check).w(")")
    else
      oparen.expr(x.target).w(" instanceof ").typeSigNullable(x.check, false).cparen
    return this
  }

  override This isnotExpr(TypeCheckExpr x)
  {
    w("!(").isExpr(x).w(")")
  }

  override This asExpr(TypeCheckExpr x)
  {
    qnOpUtil.w(".as(").typeSigNullable(x.check, false).w(".class, ").expr(x.target).w(")")
  }

  override This coerceExpr(TypeCheckExpr x)
  {
    // Java will not cast between parameterized List/Map
    oparen.w("(").typeSig(x.check, false).w(")(").expr(x.target).w(")").cparen
  }

//////////////////////////////////////////////////////////////////////////
// Local Vars
//////////////////////////////////////////////////////////////////////////

  override This localExpr(LocalVarExpr x) { varName(x.name) }

  override This thisExpr(LocalVarExpr x) { w(selfVar ?: "this") }

  override This superExpr(LocalVarExpr x) { w("super") }

  override This itExpr(LocalVarExpr x) { w(x.name) }

//////////////////////////////////////////////////////////////////////////
// Misc Expr
//////////////////////////////////////////////////////////////////////////

  override This ternaryExpr(TernaryExpr x)
  {
    oparen.expr(x.condition).w(" ? ").expr(x.trueExpr).w(" : ").expr(x.falseExpr).cparen
  }

  override This throwExpr(ThrowExpr x)
  {
    w("throw ").expr(x.exception)
  }

  override This assignExpr(BinaryExpr x)
  {
    if (x.lhs.id === ExprId.field) return fieldAssign(x.lhs, x.rhs)
    return oparen.expr(x.lhs).w(" = ").expr(x.rhs).cparen
  }

//////////////////////////////////////////////////////////////////////////
// Call / Null Safe
//////////////////////////////////////////////////////////////////////////

  override This compareExpr(Expr lhs, Token op, Expr rhs)
  {
    qnOpUtil.w(".")
    switch (op)
    {
      case Token.eq:    w("compareEQ")
      case Token.notEq: w("compareNE")
      case Token.lt:    w("compareLT")
      case Token.ltEq:  w("compareLE")
      case Token.gt:    w("compareGT")
      case Token.gtEq:  w("compareGE")
      case Token.cmp:   w("compare")
      default:          throw Err(op.toStr)
    }
    w("(").expr(lhs).w(", ").expr(rhs).w(")")
    return this
  }

  override Str? unaryOperator(Str qname)
  {
    JavaUtil.unaryOperators.get(qname)
  }

  override Str? binaryOperator(Str qname)
  {
    JavaUtil.binaryOperators.get(qname)
  }

  override This callMethodExpr(CallExpr x)
  {
    m := x.method
    if (m.parent.isForeign)
    {
      // JAVA FFI constructor is Foo.<new>.<init>(...)
      if (x.method.name == "<new>") return this
      if (x.method.name == "<init>")
        return w("new ").typeSig(x.method.parent).w("(").args(x.args).w(")")
    }

    // if using Func.call always need a cast
    if (x.leave && m.parent.isFunc && m.name == "call" &&
        !m.returns.isVoid && !m.returns.isGenericParameter)
      w("(").typeSig(m.returns).w(")")

    return call(x.targetx, x.method, x.args)
  }

  private This call(Expr target, CMethod method, Expr[] args)
  {
    methodName := JavaUtil.methodName(method)

    // special handling for Obj.compare => fan.sys.FanObj.compare, etc
    if (useFanValCall(target, method))
    {
      if (method.parent.isObj) qnFanObj
      else qnFanVal(target.ctype)
      w(".").w(methodName).w("(")
      if (!method.isStatic) expr(target).args(args, true)
      else this.args(args)
      w(")")
      return this
    }

    // in Java static interface methods must be called on interface itself
    if (method.parent.isMixin && method.isStatic)
      target = StaticTargetExpr(target.loc, method.parent)

    return expr(target).w(".").w(methodName).w("(").args(args).w(")")
  }

  private Bool useFanValCall(Expr target, CMethod method)
  {
    targetType := target.ctype
    if (targetType == null) return false
    if (targetType.isMixin && method.parent.isObj) return true
    if (!JavaUtil.isJavaNative(targetType)) return false
    if (method.name == "trap")
    {
      // don't use FanObj.trap for super.trap
      if (target.id === ExprId.superExpr) return false
    }
    return true
  }

  This args(Expr[] args, Bool forceComma := false)
  {
    args.each |arg, i|
    {
      if (i > 0 || forceComma) w(", ")
      expr(arg)
    }
    return this
  }

  override This trapExpr(CallExpr x)
  {
    qnFanObj.w(".trap(").expr(x.target).w(", ").str(x.name)
    if (!x.args.isEmpty)
    {
      w(", ").qnList.w(".makeObj(new Object[] {").args(x.args).w("})")
    }
    return w(")")
  }

  override This safeCallExpr(CallExpr x)
  {
    target := x.target
    itExpr := SafeLocalVar(x.loc, x.target.ctype)

    // we add cast in (Cast)target to (it$)->(Cast)call(...)
    TypeCheckExpr? cast := null
    if (x.target.id === ExprId.coerce)
    {
      cast = (TypeCheckExpr)target
      //target = cast.target
    }

    // NOTE: this only works if closure only uses effectively final locals
    return safe(target, x.ctype) |me|
    {
      if (cast != null) w("(").typeSig(cast.check).w(")")
      me.call(itExpr, x.method, x.args)
    }
  }

  ** Common code for "?.method()" and "?.field"
  ** NOTE: this requires a Java closure, so only works for effectively final locals
  private This safe(Expr target, CType returns, |This| restViaItArg)
  {
    if (returns.isThis) returns = target.ctype

    qnOpUtil.w(".<").typeSig(target.ctype)
    if ((returns.isVal && !returns.isNullable) || returns.isVoid)
    {
      // value types use safeVoid, safeBool(), safeInt(), or safeFloat()
      w(">safe${returns.name}(")
    }
    else
    {
      // Ojects use safe()
      w(",").typeSig(returns).w(">safe(")
    }
    expr(target).w(", (it\$)->")
    restViaItArg(this)
    w(")")
    return this
  }

  override This elvisExpr(BinaryExpr x)
  {
    // NOTE: this only works if closure only uses effectively final locals
    qnOpUtil.w(".<").typeSig(x.ctype).w(">elvis(")
      .expr(x.lhs)
      .w(", ()->")
    if (x.rhs.id === ExprId.throwExpr)
      w("{ ").expr(x.rhs).w("; }")
    else
      expr(x.rhs)
    return w(")")
  }

  override This ctorExpr(CallExpr x)
  {
    callMethodExpr(x)
  }

  override This staticTargetExpr(StaticTargetExpr x)
  {
    typeSig(x.ctype)
  }

  override This shortcutAssignExpr(ShortcutExpr x)
  {
    // get the variable
    var := x.target

    // if var is a coercion set that aside and get real variable
    TypeCheckExpr? coerce := null
    if (var.id == ExprId.coerce)
    {
      coerce = (TypeCheckExpr)var
      var = coerce.target
    }

    // now we have three variables: local, field, or indexed
    switch (var.id)
    {
      case ExprId.localVar: return shortcutAssignLocal(x)
      case ExprId.field:    return shortcutAssignField(x, var)
      case ExprId.shortcut: return shortcutAssignIndexed(x, var)
      default:              throw Err("$var.id | $x [$x.loc.toLocStr]")
    }
  }

  private This shortcutAssignLocal(ShortcutExpr x)
  {
    if (useJavaNumOp(x) || x.method.qname == "sys::Str.plus")
    {
      // Java operator support Int/Float or Str +=
      lhs := x.target
      rhs := x.args.first
      if (rhs == null)
      {
        op := JavaUtil.unaryOperators.getChecked(x.method.qname)
        return oparen.w(op).expr(lhs).cparen
      }
      else
      {
        op := JavaUtil.binaryOperators.getChecked(x.method.qname)
        return expr(lhs).sp.w(op).w("=").sp.expr(rhs)
      }
    }
    else
    {
      // treat as normal call
      return callMethodExpr(x)
    }
  }

  private This shortcutAssignField(ShortcutExpr x, FieldExpr fe)
  {
    // NOTE: this assumes idempotent field access
    loc := fe.loc
    getAndCall := CallExpr(loc, fe, x.method, x.args)
    getAndCall.synthetic = true // don't route thru unary/binary operators
    fieldAssign(fe, getAndCall)
    return this
  }

  private This shortcutAssignIndexed(IndexedAssignExpr x, ShortcutExpr indexing)
  {
    // NOTE: this assumes idempotent indexing access and key expression
    // given expression like coll[key] += arg
    loc     := x.loc
    coll    := indexing.target   // collection
    key     := indexing.args[0]  // index key
    getAndCall := CallExpr(loc, indexing, x.method, x.args)
    getAndCall.synthetic = true  // don't route thru unary/binary operators
    expr(coll).w(".set(").expr(key).w(", ").expr(getAndCall).w(")")
    return this
  }

  override This postfixLeaveExpr(ShortcutExpr x)
  {
    // only support Int/Float
    if (!useJavaNumOp(x))
    {
      warn("Postfix leave unsupported: $x", x.loc)
      return shortcutAssignLocal(x)
    }

    // incremnet or decrement
    name := x.method.name
    oparen.expr(x.target).cparen
    if (name == "increment") w("++")
    else if (name == "decrement") w("--")
    else throw Err("Postfix $x.method.qname")
    return this
  }

  private Bool useJavaNumOp(ShortcutExpr x)
  {
    isJavaNumVal(x.method.parent) && x.target.id === ExprId.localVar
  }

  private Bool isJavaNumVal(CType t) { t.isInt || t.isFloat }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override This fieldExpr(FieldExpr x)
  {
    f := x.field
    if (x.isSafe)
    {
      return safe(x.target, f.type) |me|
      {
        itExpr := SafeLocalVar(x.loc, x.target.ctype)
        me.w("(").typeSig(f.type).w(")").getField(itExpr, x)
      }
    }
    else
    {
      return getField(x.target, x)
    }
  }

  private This getField(Expr? target, FieldExpr x)
  {
    // special handling for ie fan.sys.FanBool.xxx
    field := x.field
    targetType := target?.ctype
    if (targetType != null && JavaUtil.isJavaNative(targetType))
    {
      qnFanVal(targetType).w(".").fieldName(field)
      return this
    }

    // in Java static interface methods must be called on interface itself
    if (field.parent.isMixin && field.isStatic)
      target = StaticTargetExpr(x.loc, field.parent)

    if (target != null) expr(target).w(".")
    fieldName(field)
    if (useFieldCall(x)) w("()")

    return this
  }

  private Bool useFieldCall(FieldExpr x)
  {
    if (curMethod.isGetter || curMethod.isSetter) return x.target.id === ExprId.superExpr
    if (x.field.isSynthetic) return false
    if (x.field.parent.pod.name == "sys" && !x.useAccessor) return false
    return true
  }

  private This fieldAssign(FieldExpr x, Expr rhs)
  {
    // if we are in the static init of a mixin, then our fields
    // are declared on an inner class named Fields
    field := x.field
    if (curMethod.isStaticInit && curMethod.parent.isMixin)
    {
      fieldName(field).w(" = ").expr(rhs)
      return this
    }

    if (x.target != null) expr(x.target).w(".")
    fieldName(field)
    if (closure != null && field.isConst && field.parent != closure)
      w("\$init(this, ").expr(rhs).w(")")
    else if (assignViaSetter(x))
      w("(").expr(rhs).w(")")
    else
      w(" = ").expr(rhs)
    return this
  }

  private Bool assignViaSetter(FieldExpr x)
  {
    if (x.useAccessor) return true
    if (x.field.parent.isSynthetic) return false
    if (curType == x.field.parent) return false
    return true
  }

  override This closureExpr(ClosureExpr x)
  {
    callMethodExpr(x.substitute)
  }

}

**************************************************************************
** SafeLocalVar
**************************************************************************

class SafeLocalVar : ItExpr
{
  new make(Loc loc, CType type) : super(loc, type) {}
  override Str name() { "it\$" }
}

