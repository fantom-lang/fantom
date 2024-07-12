//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsExpr
**
class JsExpr : JsNode
{
  new make(CompileEsPlugin plugin, Expr expr) : super(plugin, expr)
  {
  }

  override Expr? node() { super.node }
  virtual Expr expr() { this.node }

  internal Bool isLocalDefStmt := false

  override Void write()
  {
    switch (expr.id)
    {
      case ExprId.nullLiteral:     writeNullLiteral(expr)
      case ExprId.trueLiteral:     writeBoolLiteral(expr)
      case ExprId.falseLiteral:    writeBoolLiteral(expr)
      case ExprId.intLiteral:      writeIntLiteral(expr)
      case ExprId.floatLiteral:    writeFloatLiteral(expr)
      case ExprId.decimalLiteral:  writeDecimalLiteral(expr)
      case ExprId.strLiteral:      writeStrLiteral(expr)
      case ExprId.durationLiteral: writeDurationLiteral(expr)
      case ExprId.uriLiteral:      writeUriLiteral(expr)
      case ExprId.typeLiteral:     writeTypeLiteral(expr)
      case ExprId.slotLiteral:     writeSlotLiteral(expr)
      case ExprId.rangeLiteral:    writeRangeLiteral(expr)
      case ExprId.listLiteral:     writeListLiteral(expr)
      case ExprId.mapLiteral:      writeMapLiteral(expr)

      case ExprId.boolNot:         writeUnaryExpr(expr)
      case ExprId.cmpNull:         writeUnaryExpr(expr)
      case ExprId.cmpNotNull:      writeUnaryExpr(expr)

      case ExprId.elvis:           writeElvisExpr(expr)
      case ExprId.assign:          writeBinaryExpr(expr)
      case ExprId.same:            writeBinaryExpr(expr)
      case ExprId.notSame:         writeBinaryExpr(expr)
      case ExprId.ternary:         writeTernaryExpr(expr)

      case ExprId.boolOr:          writeCondExpr(expr)
      case ExprId.boolAnd:         writeCondExpr(expr)

      case ExprId.isExpr:          writeTypeCheckExpr(expr)
      case ExprId.isnotExpr:       writeTypeCheckExpr(expr)
      case ExprId.asExpr:          writeTypeCheckExpr(expr)
      case ExprId.coerce:          writeTypeCheckExpr(expr)

      case ExprId.call:            JsCallExpr(plugin, expr).write
      case ExprId.construction:    JsCallExpr(plugin, expr).write
      case ExprId.shortcut:        JsShortcutExpr(plugin, expr).write
      case ExprId.field:           writeFieldExpr(expr)
      case ExprId.closure:         writeClosure(expr)

      case ExprId.localVar:        writeLocalVarExpr(expr)
      case ExprId.thisExpr:        writeThisExpr
      case ExprId.superExpr:       writeSuperExpr(expr)
      case ExprId.itExpr:          writeItExpr(expr)
      case ExprId.staticTarget:    writeStaticTargetExpr(expr)
      case ExprId.throwExpr:       writeThrowExpr(expr)

      case ExprId.unknownVar:      writeUnknownVarExpr(expr)

      default:
        Err().trace
        expr.print(AstWriter()); Env.cur.out.printLine()
        throw err("Unknown ExprId: ${expr.id} ${expr.typeof}", expr.loc)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Literals
//////////////////////////////////////////////////////////////////////////

  private Void writeNullLiteral(LiteralExpr x)
  {
    js.w("null", loc)
  }

  private Void writeBoolLiteral(LiteralExpr x)
  {
    js.w(x.val ? "true" : "false", loc)
  }

  private Void writeIntLiteral(LiteralExpr x)
  {
    js.w(x.val, loc)
  }

  private Void writeFloatLiteral(LiteralExpr x)
  {
    js.w("sys.Float.make(${x.val})", loc)
  }

  private Void writeDecimalLiteral(LiteralExpr x)
  {
    js.w("sys.Decimal.make(${x.val})", loc)
  }

  private Void writeStrLiteral(LiteralExpr x)
  {
    Str val := x.val
    esc := val.toCode('\"', true)[1..-2] // remove outer quotes
    js.w("\"${esc}\"", loc)
  }

  private Void writeDurationLiteral(LiteralExpr x)
  {
    js.w("sys.Duration.fromStr(\"${x.val.toStr}\")", loc)
  }

  private Void writeUriLiteral(LiteralExpr x)
  {
    val := x.val.toStr.toCode('\"', true)
    js.w("sys.Uri.fromStr(${val})", loc)
  }

  private Void writeTypeLiteral(LiteralExpr x)
  {
    writeType(x.val)
  }

  protected Void writeType(CType t, Loc? loc := this.loc)
  {
    if (t.isList || t.isMap || t.isFunc)
    {
      js.w("sys.Type.find(\"${t.signature}\")", loc)
    }
    else
    {
      js.w("${qnameToJs(t)}.type\$", loc)
      if (t.isNullable) js.w(".toNullable()", loc)
    }
  }

  private Void writeSlotLiteral(SlotLiteralExpr x)
  {
    writeType(x.parent)
    js.w(".slot(\"${x.name}\")", loc)
  }

  private Void writeRangeLiteral(RangeLiteralExpr x)
  {
    js.w("sys.Range.make(", loc)
    writeExpr(x.start)
    js.w(", ")
    writeExpr(x.end)
    if (x.exclusive) js.w(", true", loc)
    js.w(")")
  }

  private Void writeListLiteral(ListLiteralExpr x)
  {
    // inferredType := x.ctype
    // explicitType := null
    // if (x.explicitType != null)
    //   explicitType = x.explicitType
    of := ((CType)(x.explicitType ?: x.ctype)).deref->v

    js.w("sys.List.make(", loc)
    writeType(of)
    if (x.vals.size > 0)
    {
      js.w(", [")
      x.vals.each |v, i|
      {
        if (i > 0) js.w(", ")
        writeExpr(v)
      }
      js.w("]")
    }
    js.w(")")
  }

  private Void writeMapLiteral(MapLiteralExpr x)
  {
    js.w("sys.Map.__fromLiteral([", loc)
    x.keys.each |k, i| { if (i > 0) js.w(","); writeExpr(k) }
    js.w("], [")
    x.vals.each |v, i| { if (i > 0) js.w(","); writeExpr(v) }
    js.w("]")

    t := (MapType)(x.explicitType ?: x.ctype)
    js.w(", sys.Type.find(\"${t.k.signature}\")")
    js.w(", sys.Type.find(\"${t.v.signature}\")")
    js.w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Elvis
//////////////////////////////////////////////////////////////////////////

  private Void writeElvisExpr(BinaryExpr be)
  {
    var := uniqName
    old := plugin.thisName
    plugin.thisName = "this\$"

    js.w("((this\$) => { let ${var} = ", loc)
    writeExpr(be.lhs)
    js.w("; if (${var} != null) return ${var}; ", loc)
    if (be.rhs isnot ThrowExpr) js.w("return ", loc)
    writeExpr(be.rhs)
    js.w("; })(${old})", loc)
    plugin.thisName = old
  }

//////////////////////////////////////////////////////////////////////////
// Ternary
//////////////////////////////////////////////////////////////////////////

  private Void writeTernaryExpr(TernaryExpr te)
  {
    var := uniqName
    old := plugin.thisName
    plugin.thisName = "this\$"
    js.w("((this\$) => { ", loc)
    js.w("if ("); writeExpr(te.condition); js.w(") ")
    if (te.trueExpr isnot ThrowExpr) js.w("return ", loc)
    writeExpr(te.trueExpr); js.w("; ")
    if (te.falseExpr isnot ThrowExpr) js.w("return ", loc)
    writeExpr(te.falseExpr); js.w("; ")
    js.w("})(${old})", loc)
    plugin.thisName = old
  }

//////////////////////////////////////////////////////////////////////////
// Unary
//////////////////////////////////////////////////////////////////////////

  private Void writeUnaryExpr(UnaryExpr x)
  {
    switch (x.id)
    {
      case ExprId.cmpNull:    writeExpr(x.operand); js.w(" == null", loc)
      case ExprId.cmpNotNull: writeExpr(x.operand); js.w(" != null", loc)
      default:
        js.w(x.opToken.symbol, loc)
        if (x.operand is BinaryExpr) js.w("(")
        writeExpr(x.operand)
        if (x.operand is BinaryExpr) js.w(")")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Binary
//////////////////////////////////////////////////////////////////////////

  private Void writeBinaryExpr(BinaryExpr x)
  {
    symbol   := x.opToken.symbol
    lhs      := JsExpr(plugin, x.lhs)
    rhs      := JsExpr(plugin, x.rhs)
    leave    := x.leave
    isAssign := x.assignTarget != null

    if (isAssign && lhs.expr is FieldExpr)
    {
      fe := (FieldExpr)lhs.expr
      if (leave)
      {
        // code like this seems to trigger this path:
        // foo = bar = 1
        var := uniqName
        old := plugin.thisName
        plugin.thisName = "this\$"
        js.w("((this\$) => { ", loc)
        js.w("let ${var} = ", loc); rhs.write; js.w("; ")

        // hack: use UnknownVarExpr so we can write this synthetic var
        lhs.writeSetter(JsExpr(plugin, UnknownVarExpr(loc, null, var))); js.w(";")
        js.w(" return ${var}; })(${old})", loc)

        plugin.thisName = old
      }
      else { lhs.writeSetter(rhs) }
    }
    else
    {
      if (isAssign && !isLocalDefStmt) js.w("(")
      lhs.write
      js.w(" ${symbol} ", loc)
      rhs.write
      if (isAssign && !isLocalDefStmt) js.w(")")
    }
  }

  private Void writeUnknownVarExpr(UnknownVarExpr expr)
  {
    js.w(expr.name)
  }

//////////////////////////////////////////////////////////////////////////
// Conditions
//////////////////////////////////////////////////////////////////////////

  private Void writeCondExpr(CondExpr ce)
  {
    symbol   := ce.opToken.symbol
    operands := ce.operands

    js.w("(")
    operands.each |op, i|
    {
      if (i > 0 && i < operands.size) js.w(" ${symbol} ", loc)
      writeExpr(op)
    }
    js.w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Type Check
//////////////////////////////////////////////////////////////////////////

  private Void writeTypeCheckExpr(TypeCheckExpr x)
  {
    op := x.id == ExprId.coerce ? "coerce" : x.opStr
    if (op == "isnot")
    {
      js.w("!", loc)
      op = "is"
    }
    js.w("sys.ObjUtil.${op}(", loc)
    writeExpr(x.target)
    js.w(", ")
    writeType(x.check)
    js.w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Field
//////////////////////////////////////////////////////////////////////////

  private JsExpr? setArg := null

  Void writeSetter(JsExpr rhs)
  {
    try
    {
      this.setArg = rhs
      this.write
    }
    finally this.setArg = null
  }

  private Void writeFieldExpr(FieldExpr fe)
  {
    if (fe.target is SuperExpr) writeSuperField(fe)
    else writeNormField(fe)
  }

  private Void writeSuperField(FieldExpr fe)
  {
    name := methodToJs(fe.field.name)

    // TODO: do we need anything special here for setArg != null ?
    // possibly if we change to getter/setter design
    // if (setArg != null) throw Err("TODO: setArg = ${setArg} name=${name}")

    writeExpr(fe.target)
    js.w(".${name}.call(${plugin.thisName}", loc)
    if (setArg != null)
    {
      js.w(", ")
      writeSetArg
    }
    js.w(")")
  }

  private Void writeNormField(FieldExpr fe)
  {
    old         := plugin.thisName
    name        := methodToJs(fe.field.name)
    parent      := fe.field.parent
    useAccessor := fe.useAccessor
    isSet       := this.setArg != null

    // use accessor if referring to an enum
    if (fe.field.isEnum) useAccessor = true
    // use the accessor for static fields unless we are in the static initializer;
    // in which case we need to access the private fields directly to initialize them.
    else if (fe.field.isStatic) useAccessor = !plugin.curMethod.isStaticInit

    // force use of the accessor methods if we are accessing the
    // field outside its type since we declare all fields as private
    // in the generated js code
    //
    // else if the field is declared on this type and we are doing a set,
    // but the field has a private setter, then we don't use the accessor
    if (parent.qname != plugin.curType.qname) useAccessor = true
    else if (isSet && (fe.field.setter?.isPrivate ?: false)) useAccessor = false

    writeTarget := |->| {
      if (fe.target == null) js.w(qnameToJs(parent), fe.loc)
      else JsExpr(plugin, fe.target).write
    }

    if (fe.isSafe)
    {
      v := uniqName
      plugin.thisName = "this\$"
      js.w("((this\$) => { let ${v}=", loc)
      writeTarget()
      js.w("; return (${v}==null) ? null : ${v}", loc)
      plugin.thisName = old
    }
    else
    {
      writeTarget()
      if (name == "\$this") return // skip $this ref for closures
    }
    js.w(".")
    if (useAccessor)
    {
      if (setArg==null) js.w("${name}()", fe.loc)
      else
      {
        if (fe.field.isConst) name = "__${name}"
        js.w("${name}(")
        writeSetArg()
        js.w(")")
      }
    }
    else
    {
      js.w("${fieldToJs(fe.field.name)}", fe.loc)
      if (setArg != null)
      {
        js.w(" = ")
        writeSetArg()
      }
    }

    if (fe.isSafe) js.w("; })(${old})", loc)
  }

  private Void writeSetArg()
  {
    arg := this.setArg
    this.setArg = null
    arg.write
    this.setArg = arg
  }

//////////////////////////////////////////////////////////////////////////
// Closure
//////////////////////////////////////////////////////////////////////////

  private Void writeClosure(ClosureExpr ce)
  {
    plugin.closureSupport.writeClosure(ce)
  }

//////////////////////////////////////////////////////////////////////////
// Throw
//////////////////////////////////////////////////////////////////////////

  private Void writeThrowExpr(ThrowExpr te)
  {
    js.w("throw ", loc)
    writeExpr(te.exception)
  }

//////////////////////////////////////////////////////////////////////////
// This
//////////////////////////////////////////////////////////////////////////

  private Void writeThisExpr() { js.w(plugin.thisName, loc) }

//////////////////////////////////////////////////////////////////////////
// Super
//////////////////////////////////////////////////////////////////////////

  private Void writeSuperExpr(SuperExpr se)
  {
    t := se.explicitType ?: se.ctype
    js.w("${qnameToJs(t)}.prototype", loc)
  }

//////////////////////////////////////////////////////////////////////////
// It
//////////////////////////////////////////////////////////////////////////

  private Void writeItExpr(ItExpr ie) { js.w("it", loc) }

//////////////////////////////////////////////////////////////////////////
// StaticTarget
//////////////////////////////////////////////////////////////////////////

  private Void writeStaticTargetExpr(StaticTargetExpr st)
  {
    js.w(qnameToJs(st.ctype), loc)
  }

//////////////////////////////////////////////////////////////////////////
// LocalVar
//////////////////////////////////////////////////////////////////////////

  private Void writeLocalVarExpr(LocalVarExpr x)
  {
    js.w(nameToJs(x.var.name), loc)
  }
}

**************************************************************************
** JsCallExpr
**************************************************************************

internal class JsCallExpr : JsExpr
{
  new make(CompileEsPlugin plugin, CallExpr ce) : super(plugin, ce)
  {
    this.ce = ce
    this.name = methodToJs(ce.method.name)

    if (ce.method != null)
    {
      this.parent   = ce.method.parent
      this.isCtor   = ce.method.isCtor
      this.isObj    = ce.method.parent.qname == "sys::Obj"
      this.isFunc   = ce.method.parent.qname == "sys::Func"
      this.isPrim   = isPrimitive(ce.method.parent)
      this.isStatic = ce.method.isStatic
    }

    if (ce.target != null)
    {
      // resolveType := |CType ctype->CType| {
      //   t := ctype is TypeRef ? ctype->t : ctype
      //   if (t is NullableType) t = t->root
      //   return t
      // }
      this.targetType = ce.target.ctype == null ? this.parent : ce.target.ctype
      resolved := resolveType(ce.target.ctype)
      funcType := c.ns.resolveType("sys::Func")
      isClos = resolved.fits(funcType)
    }

    // force these methods to route thru ObjUtil if not a super.xxx expr
    if ((name == "equals" || name == "compare") && (ce.target isnot SuperExpr)) isObj = true
  }

  CallExpr ce { private set }
  Str name                            // js method name
  Bool isObj        := false          // is target sys::Obj
  Bool isFunc       := false          // is target sys::Func
  Bool isPrim       := false          // is target a primitive type (Int,Bool,etc.)
  Bool isCtor       := false          // is this a ctor call
  Bool isStatic     := false          // is this a static method
  Bool isClos       := false          // is this a Func/Closure call
  CType? parent     := null           // method parent type
  CType? targetType := null           // call target type
  Str? safeVar      := null           // var that target expr is held in for safe-nav

  override Void write()
  {
    // skip mock methods used to insert implicit runtime checks
    if (ce.method is MockMethod) return

    // skip instance inits
    if (ce.method.name.startsWith("instance\$init\$")) return

    if (ce.isSafe)
    {
      // wrap if safe-nav
      safeVar := uniqName
      old := plugin.thisName
      plugin.thisName = "this\$"
      js.w("((this\$) => { let ${safeVar} = ", loc)
      if (ce.target == null) js.w(plugin.thisName, loc)
      else writeExpr(ce.target)
      js.w("; if (${safeVar} == null) return null; return ", loc)
      writeCall
      js.w("; })(${old})", loc)
      plugin.thisName = old
    }
    else
    {
      writeCall
    }
  }

  protected Void writeCall()
  {
    if (isObj)
    {
      js.w("sys.ObjUtil.${name}(", loc)
      if (isStatic) writeArgs
      else
      {
        writeTarget
        writeArgs(true)
      }
      js.w(")")
    }
    else if (isPrim || isFunc)
    {
      js.w("${qnameToJs(targetType)}.${name}(", loc)
      if (isStatic) writeArgs
      else
      {
        writeTarget
        writeArgs(true)
      }
      js.w(")")
    }
    else if (ce.isCtorChain)
    {
      js.w("${qnameToJs(targetType)}.${name}\$(${plugin.thisName}", loc)
      writeArgs(true)
      js.w(")")
    }
    else if (ce.target is SuperExpr)
    {
      writeSuper
    }
    else
    {
      writeTarget
      // if native closure, we invoke the func directly (don't do Func.call())
      if (isClos) js.w("(")
      else
      {
        if ((targetType?.isForeign ?: false) && isCtor && name == "<init>")
          js.w(".javaInit(", loc)
        else
          js.w(".${name}(", loc)
      }
      writeArgs
      js.w(")")
    }
  }

  protected Void writeSuper()
  {
    writeExpr(ce.target)
    js.w(".${name}.call(${plugin.thisName}", loc)
    writeArgs(true)
    js.w(")")
  }

  protected Void writeTarget()
  {
    if (isStatic || isCtor) js.w(qnameToJs(parent))
    else if (safeVar != null) js.w(safeVar)
    else if (ce.target == null) js.w(plugin.thisName)
    else writeExpr(ce.target)
  }

  protected Void writeArgs(Bool hasFirstArg := false)
  {
    if (ce.isDynamic)
    {
      if (hasFirstArg) js.w(",")
      js.w("\"${ce.name}\", sys.List.make(sys.Obj.type\$.toNullable(), [", loc)
      hasFirstArg = false
    }

    ce.args.each |arg, i|
    {
      if (hasFirstArg || i > 0) js.w(", ")
      writeExpr(arg)
    }

    if (ce.args.last is ClosureExpr && typedFuncs.contains(name))
    {
      ClosureExpr ce := ce.args.last
      js.w(", ")
      writeType(ce.doCall.returnType)
    }

    if (ce.isDynamic) js.w("])")
  }
  static const Str[] typedFuncs := ["map", "mapNotNull", "flatMap", "groupBy", "mapToList"]
}

**************************************************************************
** JsShortcutExpr
**************************************************************************

internal class JsShortcutExpr : JsCallExpr
{
  new make(CompileEsPlugin plugin, ShortcutExpr se) : super(plugin, se)
  {
    this.se = se
    this.isIndexedAssign = se is IndexedAssignExpr
    this.isPostfixLeave  = se.isPostfixLeave

    switch (se.opToken.symbol)
    {
      case "!=": this.name = "compareNE"
      case "<":  this.name = "compareLT"
      case "<=": this.name = "compareLE"
      case ">=": this.name = "compareGE"
      case ">":  this.name = "compareGT"
    }

    if (se.isAssign)     assignTarget = findAssignTarget(se.target)
    if (isIndexedAssign) assignIndex  = findIndexedAssign(se.target).args[0]
  }

  ShortcutExpr se { private set }
  // Bool isAssign        := false    // does this expr assign
  Bool isIndexedAssign := false    // is indexed assign
  Bool isPostfixLeave  := false    // is postfix expr
  // Bool leave           := false    // leave result of expr on "stack"
  Bool fieldSet        := false    // transiently used for field sets
  Expr? assignTarget   := null     // target of assignment
  Expr? assignIndex    := null     // indexed assign: index

  private Expr findAssignTarget(Expr expr)
  {
    if (expr is LocalVarExpr || expr is FieldExpr) return expr
    t := Type.of(expr).field("target", false)
    if (t != null) return findAssignTarget(t.get(expr))
    throw err("No base Expr found", loc)
  }

  private ShortcutExpr findIndexedAssign(Expr expr)
  {
    if (expr is ShortcutExpr) return expr
    t := Type.of(expr).field("target", false)
    if (t != null) return findIndexedAssign(t.get(expr))
    throw err("No base Expr found", loc)
  }

  override Void write()
  {
    if (fieldSet)
    {
      return super.write
    }
    if (isIndexedAssign)
    {
      return doWriteIndexedAssign
    }
    if (se.isPostfixLeave)
    {
      var := uniqName
      old := plugin.thisName
      plugin.thisName = "this\$"
      js.w("((this\$) => { let ${var} = ", loc)
      writeExpr(assignTarget); js.w(";")
      doWrite
      js.w("; return ${var}; })(${old})", loc)
      plugin.thisName = old
    }
    else doWrite
  }

  private Void doWrite()
  {
    if (se.isAssign)
    {
      if (assignTarget is FieldExpr)
      {
        fieldSet = true
        fe := (FieldExpr)assignTarget
        JsExpr(plugin, fe).writeSetter(this)
        fieldSet = false
        return
      }
      else
      {
        writeExpr(assignTarget)
        js.w(" = ", loc)
      }
    }
    super.write
  }

  private Void doWriteIndexedAssign()
  {
    newVal := uniqName
    oldVal := uniqName
    ref    := uniqName
    index  := uniqName
    old    := plugin.thisName
    retVal := isPostfixLeave ? oldVal : newVal
    plugin.thisName = "this\$"
    js.w("((this\$) => { ", loc)
    js.w("let ${ref} = ", loc); writeExpr(assignTarget); js.w("; ")
    js.w("let ${index} = ", loc); writeExpr(assignIndex); js.w("; ")
    js.w("let ${newVal} = ", loc); super.write; js.w("; ")
    if (isPostfixLeave) js.w("let ${oldVal} = ${ref}.get(${index}); ", loc)
    js.w("${ref}.set(${index},${newVal}); ", loc)
    js.w(" return ${retVal}; })(${old})", loc)
    plugin.thisName = old
  }
}