//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsExpr
**
abstract class JsExpr : JsNode
{
  new make(JsCompilerSupport s) : super(s) {}

  static JsExpr makeFor(JsCompilerSupport s, Expr expr)
  {
    switch (expr.id)
    {
      case ExprId.nullLiteral:     return JsNullLiteralExpr(s)
      case ExprId.trueLiteral:     return JsBoolLiteralExpr(s, true)
      case ExprId.falseLiteral:    return JsBoolLiteralExpr(s, false)
      case ExprId.intLiteral:      return JsIntLiteralExpr(s, expr)
      case ExprId.floatLiteral:    return JsFloatLiteralExpr(s, expr)
      case ExprId.decimalLiteral:  return JsDecimalLiteralExpr(s, expr)
      case ExprId.strLiteral:      return JsStrLiteralExpr(s, expr)
      case ExprId.durationLiteral: return JsDurationLiteralExpr(s, expr)
      case ExprId.uriLiteral:      return JsUriLiteralExpr(s, expr)
      case ExprId.typeLiteral:     return JsTypeLiteralExpr(s, expr)
      case ExprId.slotLiteral:     return JsSlotLiteralExpr(s, expr)
      case ExprId.rangeLiteral:    return JsRangeLiteralExpr(s, expr)
      case ExprId.listLiteral:     return JsListLiteralExpr(s, expr)
      case ExprId.mapLiteral:      return JsMapLiteralExpr(s, expr)

      case ExprId.boolNot:         return JsUnaryExpr(s, expr)
      case ExprId.cmpNull:         return JsUnaryExpr(s, expr)
      case ExprId.cmpNotNull:      return JsUnaryExpr(s, expr)

      case ExprId.elvis:           return JsElvisExpr(s, expr)
      case ExprId.assign:          return JsBinaryExpr(s, expr)
      case ExprId.same:            return JsBinaryExpr(s, expr)
      case ExprId.notSame:         return JsBinaryExpr(s, expr)
      case ExprId.ternary:         return JsTernaryExpr(s, expr)

      case ExprId.boolOr:          return JsCondExpr(s, expr)
      case ExprId.boolAnd:         return JsCondExpr(s, expr)

      case ExprId.isExpr:          return JsTypeCheckExpr(s, expr)
      case ExprId.isnotExpr:       return JsTypeCheckExpr(s, expr)
      case ExprId.asExpr:          return JsTypeCheckExpr(s, expr)
      case ExprId.coerce:          return JsTypeCheckExpr(s, expr)

      case ExprId.call:            return JsCallExpr(s, expr)
      case ExprId.construction:    return JsCallExpr(s, expr)
      case ExprId.shortcut:        return JsShortcutExpr(s, expr)
      case ExprId.field:           return JsFieldExpr(s, expr)
      case ExprId.closure:         return JsClosureExpr(s, expr)

      case ExprId.localVar:        return JsLocalVarExpr(s, expr)
      case ExprId.thisExpr:        return JsThisExpr(s)
      case ExprId.superExpr:       return JsSuperExpr(s, expr)
      case ExprId.itExpr:          return JsItExpr(s)
      case ExprId.staticTarget:    return JsStaticTargetExpr(s, expr)
      case ExprId.throwExpr:       return JsThrowExpr(s, expr)

      // Not implemented
      //case ExprId.unknownVar
      //case ExprId.storage
      //case ExprId.curry
      //case ExprId.complexLiteral

      default: throw s.err("Unknown ExprId: $expr.id", expr.loc)
    }
  }
}

**************************************************************************
** JsThisExpr
**************************************************************************

class JsThisExpr : JsExpr
{
  new make(JsCompilerSupport s) : super(s) {}
  override Void write(JsWriter out) { out.w(support.thisName) }
}

**************************************************************************
** JsSuperExpr
**************************************************************************

class JsSuperExpr : JsExpr
{
  new make(JsCompilerSupport s, SuperExpr se) : super(s)
  {
    if (se.explicitType != null)
      explicitType = JsTypeRef(s, se.explicitType)
  }
  override Void write(JsWriter out) {} // handled in JsCallExpr
  JsTypeRef? explicitType
}

**************************************************************************
** JsItExpr
**************************************************************************

class JsItExpr : JsExpr
{
  new make(JsCompilerSupport s) : super(s) {}
  override Void write(JsWriter out) { out.w("it" ) }
}

**************************************************************************
** JsLocalVarExpr
**************************************************************************

class JsLocalVarExpr : JsExpr
{
  new make(JsCompilerSupport s, LocalVarExpr le) : super(s)
  {
    name = vnameToJs(le.var.name)
  }
  override Void write(JsWriter out)
  {
    out.w(name)
  }
  Str name
}

**************************************************************************
** JsStaticTargetExpr
**************************************************************************

class JsStaticTargetExpr : JsExpr
{
  new make(JsCompilerSupport s, StaticTargetExpr le) : super(s)
  {
    target = JsTypeRef(s, le.ctype)
  }
  override Void write(JsWriter out)
  {
    out.w(target.qname)
  }
  JsTypeRef target
}

**************************************************************************
** JsNullLiteralExpr
**************************************************************************

class JsNullLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s) : super(s) {}
  override Void write(JsWriter out) { out.w("null" ) }
}

**************************************************************************
** JsBoolLiteralExpr
**************************************************************************

class JsBoolLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, Bool val) : super(s)
  {
    this.val = val
  }
  override Void write(JsWriter out)
  {
    out.w(val ? "true" : "false")
  }
  Bool val
}

**************************************************************************
** JsIntLiteralExpr
**************************************************************************

class JsIntLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
  }
  override Void write(JsWriter out)
  {
    out.w(val)
  }
  Int val
}

**************************************************************************
** JsFloatLiteralExpr
**************************************************************************

class JsFloatLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Float.make($val)")
  }
  Float val
}

**************************************************************************
** JsDecimalLiteralExpr
**************************************************************************

class JsDecimalLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Decimal.make($val)")
  }
  Decimal val
}

**************************************************************************
** JsStrLiteralExpr
**************************************************************************

class JsStrLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
    this.esc = val.toCode('\"', true)[1..-2]  // remove outer quotes
  }
  override Void write(JsWriter out)
  {
    out.w("\"$esc\"")
  }
  Str val
  Str esc
}

**************************************************************************
** JsDurationLiteralExpr
**************************************************************************

class JsDurationLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Duration.fromStr(\"$val.toStr\")")
  }
  Duration val
}

**************************************************************************
** JsUriLiteralExpr
**************************************************************************

class JsUriLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = x.val
    this.str = val.toStr.toCode('\"', true)
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Uri.fromStr(")
    out.w(val.toStr.toCode('\"', true))
    out.w(")")
  }
  Obj val
  Str str
}

**************************************************************************
** JsTypeLiteralExpr
**************************************************************************

class JsTypeLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, LiteralExpr x) : super(s)
  {
    this.val = JsTypeRef(s, x.val)
  }
  override Void write(JsWriter out)
  {
    writeType(val, out)
  }
  static Void writeType(JsTypeRef t, JsWriter out)
  {
    if (t.isList || t.isMap || t.isFunc)
    {
      out.w("fan.sys.Type.find(\"$t.sig\")")
    }
    else
    {
      out.w("${t.qname}.\$type")
      if (t.isNullable) out.w(".toNullable()")
    }
  }
  JsTypeRef val
}

**************************************************************************
** JsSlotLiteralExpr
**************************************************************************

class JsSlotLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, SlotLiteralExpr x) : super(s)
  {
    this.parent = JsTypeRef(s, x.parent)
    this.name   = x.name
  }
  override Void write(JsWriter out)
  {
    JsTypeLiteralExpr.writeType(parent, out)
    out.w(".slot(\"$name\")")
  }
  JsTypeRef parent  // slot parent type
  Str name          // slot name
}

**************************************************************************
** JsRangeLiteralExpr
**************************************************************************

class JsRangeLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, RangeLiteralExpr x) : super(s)
  {
    start = JsExpr.makeFor(s, x.start)
    end   = JsExpr.makeFor(s, x.end)
    exclusive = x.exclusive
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Range.make(")
    start.write(out)
    out.w(",")
    end.write(out)
    if (exclusive) out.w(",true")
    out.w(")")
  }
  JsExpr start
  JsExpr end
  Bool exclusive
}

**************************************************************************
** JsListLiteralExpr
**************************************************************************

class JsListLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, ListLiteralExpr x) : super(s)
  {
    this.inferredType = JsTypeRef(s, x.ctype)
    if (x.explicitType != null)
      this.explicitType = JsTypeRef(s, x.explicitType)

    this.vals = x.vals.map |v->JsExpr| { JsExpr.makeFor(s, v) }
  }
  override Void write(JsWriter out)
  {
    of := (explicitType ?: inferredType).v
    out.w("fan.sys.List.make(")
    JsTypeLiteralExpr.writeType(of, out)
    if (vals.size > 0)
    {
      out.w(", [")
      vals.each |v,i|
      {
        if (i > 0) out.w(",")
        v.write(out)
      }
      out.w("]")
    }
    out.w(")")
  }
  JsTypeRef inferredType
  JsTypeRef? explicitType
  JsExpr[] vals
}

**************************************************************************
** JsMapLiteralExpr
**************************************************************************

class JsMapLiteralExpr : JsExpr
{
  new make(JsCompilerSupport s, MapLiteralExpr me) : super(s)
  {
    this.inferredType = JsTypeRef(s, me.ctype)
    if (me.explicitType != null)
      this.explicitType = JsTypeRef(s, me.explicitType)

    this.keys = me.keys.map |k->JsExpr| { JsExpr.makeFor(s, k) }
    this.vals = me.vals.map |v->JsExpr| { JsExpr.makeFor(s, v) }
  }
  override Void write(JsWriter out)
  {
    out.w("fan.sys.Map.fromLiteral([")
    keys.each |k,i| { if (i > 0) out.w(","); k.write(out) }
    out.w("],[")
    vals.each |v,i| { if (i > 0) out.w(","); v.write(out) }
    out.w("]")
    t := explicitType ?: inferredType
    out.w(",fan.sys.Type.find(\"").w(t.k.sig).w("\")")
    out.w(",fan.sys.Type.find(\"").w(t.v.sig).w("\")")
    out.w(")")
  }
  JsTypeRef inferredType
  JsTypeRef? explicitType
  JsExpr[] keys
  JsExpr[] vals
}

**************************************************************************
** JsUnaryExpr
**************************************************************************

class JsUnaryExpr : JsExpr
{
  new make(JsCompilerSupport s, UnaryExpr x) : super(s)
  {
    this.id      = x.id
    this.symbol  = x.opToken.symbol
    this.operand = JsExpr.makeFor(s, x.operand)
  }
  override Void write(JsWriter out)
  {
    switch (id)
    {
      case ExprId.cmpNull:    operand.write(out); out.w(" == null")
      case ExprId.cmpNotNull: operand.write(out); out.w(" != null")
      default:                out.w(symbol); operand.write(out)
    }
  }
  ExprId id
  Str symbol
  JsExpr operand
}

**************************************************************************
** JsBinaryExpr
**************************************************************************

class JsBinaryExpr : JsExpr
{
  new make(JsCompilerSupport s, BinaryExpr x) : super(s)
  {
    this.symbol = x.opToken.symbol
    this.lhs    = JsExpr.makeFor(s, x.lhs)
    this.rhs    = JsExpr.makeFor(s, x.rhs)
  }
  override Void write(JsWriter out)
  {
    if (lhs is JsFieldExpr && lhs->useAccessor == true)
    {
      lhs->isSet = true
      lhs.write(out)
      out.w("\$(")
      rhs.write(out)
      out.w(")")
    }
    else
    {
      lhs.write(out)
      out.w(" $symbol ")
      rhs.write(out)
    }
  }
  Str symbol
  JsExpr lhs
  JsExpr rhs
}

**************************************************************************
** JsTernaryExpr
**************************************************************************

class JsTernaryExpr : JsExpr
{
  new make(JsCompilerSupport s, TernaryExpr te) : super(s)
  {
    this.condition = JsExpr.makeFor(s, te.condition)
    this.trueExpr  = JsExpr.makeFor(s, te.trueExpr)
    this.falseExpr = JsExpr.makeFor(s, te.falseExpr)
  }
  override Void write(JsWriter out)
  {
    var := support.unique
    old := support.thisName
    support.thisName = "\$this"
    out.w("(function(\$this) { ")
    out.w("if ("); condition.write(out); out.w(") ")
    if (trueExpr isnot JsThrowExpr) out.w("return ")
    trueExpr.write(out); out.w("; ")
    if (falseExpr isnot JsThrowExpr) out.w("return ")
    falseExpr.write(out); out.w("; ")
    out.w("})($old)")
    support.thisName = old
  }
  JsExpr condition
  JsExpr trueExpr
  JsExpr falseExpr
}

**************************************************************************
** JsElvisExpr
**************************************************************************

class JsElvisExpr : JsExpr
{
  new make(JsCompilerSupport s, BinaryExpr be) : super(s)
  {
    this.lhs = JsExpr.makeFor(s, be.lhs)
    this.rhs = JsExpr.makeFor(s, be.rhs)
  }
  override Void write(JsWriter out)
  {
    var := support.unique
    old := support.thisName
    support.thisName = "\$this"
    out.w("(function(\$this) { var $var = ")
    lhs.write(out)
    out.w("; if ($var != null) return $var; ")
    if (rhs isnot JsThrowExpr) out.w("return ")
    rhs.write(out)
    out.w("; })($old)")
    support.thisName = old
  }
  JsExpr lhs
  JsExpr rhs
}

**************************************************************************
** JsCondExpr
**************************************************************************

class JsCondExpr : JsExpr
{
  new make(JsCompilerSupport s, CondExpr ce) : super(s)
  {
    this.symbol   = ce.opToken.symbol
    this.operands = ce.operands.map |op->JsExpr| { JsExpr.makeFor(s, op) }
  }
  override Void write(JsWriter out)
  {
    out.w("(")
    operands.each |op,i|
    {
      if (i>0 && i<operands.size) out.w(" $symbol ")
      op.write(out)
    }
    out.w(")")
  }
  Str symbol
  JsExpr[] operands
}

**************************************************************************
** JsTypeCheckExpr
**************************************************************************

class JsTypeCheckExpr : JsExpr
{
  new make(JsCompilerSupport s, TypeCheckExpr te) : super(s)
  {
    this.op     = te.id == ExprId.coerce ? "coerce" : te.opStr
    this.target = JsExpr.makeFor(s, te.target)
    this.check  = JsTypeRef(s, te.check)
  }
  override Void write(JsWriter out)
  {
    m := op
    if (m == "isnot")
    {
      out.w("!")
      m = "is"
    }
    out.w("fan.sys.ObjUtil.$m(")
    target.write(out)
    out.w(",")
    JsTypeLiteralExpr.writeType(check, out)
    out.w(")")
  }
  Str op
  JsExpr target
  JsTypeRef check
}

**************************************************************************
** JsCallExpr
**************************************************************************

class JsCallExpr : JsExpr
{
  new make(JsCompilerSupport s, CallExpr ce) : super(s)
  {
    this.name   = vnameToJs(ce.method.name)
    this.args   = ce.args.map |a->JsExpr| { JsExpr.makeFor(s, a) }
    this.isSafe = ce.isSafe
    this.isMock = ce.method is MockMethod
    this.isCtorChain = ce.isCtorChain
    this.isDynamic = ce.isDynamic
    if (isDynamic) this.dynamicName = ce.name

    if (ce.method != null)
    {
      this.parent = JsTypeRef(s, ce.method.parent)
      this.isCtor = ce.method.isCtor
      this.isObj  = ce.method.parent.qname == "sys::Obj"
      this.isPrim = isPrimitive(ce.method.parent)
      this.isStatic = ce.method.isStatic
    }

    if (ce.target != null)
    {
      this.target = JsExpr.makeFor(s, ce.target)
      this.targetType = ce.target.ctype == null ? parent : JsTypeRef(s, ce.target.ctype)
    }

    // force these methods to route thru ObjUtil
    if (name == "equals" || name == "compare") isObj = true

    // use isMock as hook to skip instance inits
    if (name.startsWith("instance\$init\$")) isMock = true
  }

  override Void write(JsWriter out)
  {
    // skip mock methods used to insert implicit runtime checks
    if (isMock) return

    if (isSafe)
    {
      // wrap if safe-nav
      safeVar = support.unique
      old := support.thisName
      support.thisName = "\$this"
      out.w("(function(\$this) { var $safeVar = ")
      if (target == null) out.w(support.thisName)
      else target.write(out)
      out.w("; if ($safeVar == null) return null; return ")
      writeCall(out)
      out.w("; })($old)")
      support.thisName = old
    }
    else
    {
      // normal call
      writeCall(out)
    }
  }

  Void writeCall(JsWriter out)
  {
    if (isObj) writeObj(out)
    else if (isPrim) writePrimitive(out)
    else if (isCtorChain) writeCtorChain(out)
    else if (target is JsSuperExpr) writeSuper(out)
    else
    {
      writeTarget(out)
      out.w(".$name(")
      writeArgs(out)
      out.w(")")
    }
  }

  Void writeObj(JsWriter out)
  {
    out.w("fan.sys.ObjUtil.$name(")
    if (isStatic) writeArgs(out)
    else
    {
      writeTarget(out)
      writeArgs(out, true)
    }
    out.w(")")
  }

  Void writePrimitive(JsWriter out)
  {
    out.w("${targetType.qname}.$name(")
    if (isStatic) writeArgs(out)
    else
    {
      writeTarget(out)
      writeArgs(out, true)
    }
    out.w(")")
  }

  Void writeCtorChain(JsWriter out)
  {
    out.w("${targetType.qname}.${name}\$($support.thisName")
    writeArgs(out, true)
    out.w(")")
  }

  Void writeSuper(JsWriter out)
  {
    JsTypeRef t := target->explicitType ?: targetType
    out.w("${t.qname}.prototype.${name}.call($support.thisName")
    writeArgs(out, true)
    out.w(")")
  }

  Void writeTarget(JsWriter out)
  {

    if (isStatic || isCtor) parent.write(out)
    else if (safeVar != null) out.w(safeVar)
    else if (target == null) out.w(support.thisName)
    else target.write(out)
  }

  Void writeArgs(JsWriter out, Bool hasFirstArg := false)
  {
    if (isDynamic)
    {
      if (hasFirstArg) out.w(",")
      out.w("\"$dynamicName\",fan.sys.List.make(fan.sys.Obj.\$type.toNullable(),[")
      hasFirstArg = false
    }

    args.each |arg,i|
    {
      if (hasFirstArg || i > 0) out.w(",")
      arg.write(out)
    }

    if (isDynamic) out.w("])")
  }

  JsExpr? target         // call target
  JsTypeRef? targetType  // call target type
  JsTypeRef? parent      // method parent type
  Str name               // method name
  JsExpr[] args          // args to pass to method
  Bool isObj             // is target sys::Obj
  Bool isPrim            // is target a primitive type (Int,Bool,etc)
  Bool isSafe            // if ?. operator
  Str? safeVar           // var target expr is held in for safe-nav
  Bool isMock            // mock methods used to insert implicit runtime checks
  Bool isCtor            // is this a ctor call
  Bool isCtorChain       // is this a ctor chain call
  Bool isStatic          // is this a static method
  Bool isDynamic         // is this a -> call
  Str? dynamicName       // name of -> call

}

**************************************************************************
** JsShortcutExpr
**************************************************************************

class JsShortcutExpr : JsCallExpr
{
  new make(JsCompilerSupport s, ShortcutExpr se) : super(s, se)
  {
    this.symbol    = se.opToken.symbol
    this.isAssign  = se.isAssign
    this.isIndexedAssign = se is IndexedAssignExpr
    this.isPostfixLeave  = se.isPostfixLeave

    switch (symbol)
    {
      case "!=": name = "compareNE"
      case "<":  name = "compareLT"
      case "<=": name = "compareLE"
      case ">=": name = "compareGE"
      case ">":  name = "compareGT"
    }

    if (isAssign)        assignTarget = findAssignTarget(target, se.loc)
    if (isIndexedAssign) assignIndex  = findIndexedAssign(target, se.loc).args[0]
  }

  private JsExpr findAssignTarget(JsExpr expr, Loc loc)
  {
    if (expr is JsLocalVarExpr || expr is JsFieldExpr) return expr
    t := Type.of(expr).field("target", false)
    if (t != null) return findAssignTarget(t.get(expr), loc)
    throw support.err("No base Expr found", loc)
  }

  private JsShortcutExpr findIndexedAssign(JsExpr expr, Loc loc)
  {
    if (expr is JsShortcutExpr) return expr
    t := Type.of(expr).field("target", false)
    if (t != null) return findIndexedAssign(t.get(expr), loc)
    throw support.err("No base Expr found", loc)
  }

  override Void write(JsWriter out)
  {
    if (isIndexedAssign)
    {
      doWriteIndexedAssign(out)
      return
    }
    if (isPostfixLeave)
    {
      var := support.unique
      old := support.thisName
      support.thisName = "\$this"
      out.w("(function(\$this) { var $var = ")
      assignTarget.write(out)
      out.w("; ")
      doWrite(out)
      out.w("; return $var; })($old)")
      support.thisName = old
    }
    else doWrite(out)
  }

  Void doWrite(JsWriter out)
  {
    if (isAssign)
    {
      assignTarget.write(out)
      out.w(" = ")
    }
    super.write(out)
  }

  Void doWriteIndexedAssign(JsWriter out)
  {
    newVal := support.unique
    oldVal := support.unique
    ref    := support.unique
    index  := support.unique
    old    := support.thisName
    support.thisName = "\$this"
    out.w("(function(\$this) {")
    out.w(" var $ref = ");    assignTarget.write(out); out.w(";")
    out.w(" var $index = ");  assignIndex.write(out);  out.w(";")
    out.w(" var $newVal = "); super.write(out);        out.w(";")
    if (isPostfixLeave) out.w(" var $oldVal = ${ref}.get($index);");
    out.w(" ${ref}.set($index,$newVal);")
    out.w(" return ").w(isPostfixLeave ? oldVal : newVal).w(";")
    out.w(" })($old)")
    support.thisName = old
  }

  Str symbol            // the shortcut token symbol
  Bool isAssign         // does this expr assign
  Bool isIndexedAssign  // is indexed assign
  Bool isPostfixLeave   // is postfix expr
  JsExpr? assignTarget  // target of assignment
  JsExpr? assignIndex   // indexed assign: index
}

**************************************************************************
** JsFieldExpr
**************************************************************************

class JsFieldExpr : JsExpr
{
  new make(JsCompilerSupport s, FieldExpr fe) : super(s)
  {
    if (fe.target != null) this.target = JsExpr.makeFor(s, fe.target)
    this.parent = JsTypeRef(s, fe.field.parent)
    this.name   = vnameToJs(fe.name)
    this.useAccessor = fe.useAccessor
  }
  override Void write(JsWriter out)
  {
    if (target == null) parent.write(out)
    else target.write(out)
    if (name == "\$this") return // skip $this ref for closures
    out.w(".")
    if (useAccessor)
    {
      out.w("$name")
      if (!isSet) out.w("()")
    }
    else out.w("m_$name")
  }
  JsExpr? target       // field target
  JsTypeRef parent     // field parent type
  Str name             // field name
  Bool useAccessor     // false if access using '*' storage operator
  Bool isSet := false  // transiently use for setters
}

**************************************************************************
** JsClosureExpr
**************************************************************************

class JsClosureExpr : JsExpr
{
  new make(JsCompilerSupport s, ClosureExpr ce) : super(s)
  {
    this.func = JsMethod(s, ce.doCall)
  }
  override Void write(JsWriter out)
  {
    sig := func.sig(func.params)
    out.w("fan.sys.Func.make(").nl
    out.indent

    // params
    out.w("fan.sys.List.make(fan.sys.Param.\$type, [")
    func.params.each |p,i|
    {
      if(i > 0) out.w(",")
      out.w("new fan.sys.Param(\"$p.name\",\"$p.paramType.sig\",$p.hasDef)")
    }
    out.w("]),").nl

    // return
    JsTypeLiteralExpr.writeType(func.ret, out)
    out.w(",").nl

    // func
    out.w("function$sig").nl
    out.w("{").nl
    out.indent
    old := support.thisName
    support.thisName = "\$this"
    func.code?.write(out)
    support.thisName = old
    out.unindent
    out.w("})")
    out.unindent
  }
  JsMethod? func  // the func for this closure
}

**************************************************************************
** JsThrowExpr
**************************************************************************

class JsThrowExpr : JsExpr
{
  new make(JsCompilerSupport s, ThrowExpr te) : super(s)
  {
    this.exception = JsExpr.makeFor(s, te.exception)
  }
  override Void write(JsWriter out)
  {
    out.w("throw ")
    exception.write(out)
  }
  JsExpr exception  // the exception to throw
}

