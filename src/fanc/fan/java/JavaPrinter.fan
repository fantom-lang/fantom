//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using compiler

**
** Java transpiler pretty print
**
internal class JavaPrinter : CodePrinter
{
  new make(OutStream out) : super(out) {}

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  Void type(TypeDef t)
  {
    curType = t
    wrappers.clear

    prelude(t)
    typeHeader(t)
    w(" {").nl
    indent
    typeOf(t)
    enumOrdinals(t)
    slots(t)
    syntheticClasses(t)
    unindent
    w("}").nl

    curType = null
    wrappers.clear
  }

  Void prelude(TypeDef t)
  {
    // NOTE: we use non-qualified names for the following imported types
    // because we expect they would never be used in typical Fantom code;
    // but the Java code will not compile if there is a duplicate class

    w("// Transpiled $Date.today").nl
    nl
    w("package fan.").w(t.pod.name).eos
    nl
    w("import fan.sys.FanObj").eos
    w("import fan.sys.FanBool").eos
    w("import fan.sys.FanInt").eos
    w("import fan.sys.FanFloat").eos
    w("import fan.sys.FanStr").eos
    w("import fan.sys.List").eos
    w("import fan.sys.Map").eos
    w("import fan.sys.Type").eos
    w("import fan.sys.Sys").eos
    w("import fanx.util.OpUtil").eos
    nl
  }

  Void typeHeader(TypeDef t)
  {
    // scope
    if (t.isPublic) w("public ")

    // interface vs class
    w(t.isMixin ? "interface" : "class").sp.typeName(t)

    // extends
    extends(t)
  }

  This extends(TypeDef t)
  {
    w(" extends ")
    if (t.base.isObj) qnFanObj
    else if (t.isClosure) w(JavaUtil.closureBase(t))
    else typeSig(t.base)
    return this
  }

  Void typeOf(TypeDef t)
  {
    if (t.isSynthetic) return

    w("/** Reflect type of this object */").nl
    w("public ").qnType.w(" typeof() { return typeof\$(); }").nl
    nl
    w("/** Type literal for $t.qname */").nl
    w("public static ").qnType.w(" typeof\$() {").nl
    w("  if (typeof\$cache == null)").nl
    w("    typeof\$cache = ").qnType.w(".find(").str(t.qname).w(");").nl
    w("  return typeof\$cache;").nl
    w("}").nl
    w("private static ").qnType.w(" typeof\$cache;").nl
  }

  Void enumOrdinals(TypeDef t)
  {
    if (!t.isEnum) return

    nl
    t.enumDefs.each |e|
    {
      name := e.name.upper
      if (t.slot(name) != null) throw Err("Enum name conflict: $t.qname $name")
      w("public static final int ").w(name).w(" = ").w(e.ordinal).eos
    }
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  Void slots(TypeDef t)
  {
    ctors    := MethodDef[,]
    methods  := MethodDef[,]
    consts   := FieldDef[,]
    storages := FieldDef[,]

    t.slotDefs.each |x|
    {
      if (x is MethodDef)
      {
        m := (MethodDef)x
        if (m.isCtor || m.isInstanceInit)
          ctors.add(m)
        else
          methods.add(m)
      }
      else
      {
        f := (FieldDef)x
        if (f.isConst) consts.add(f)
        if (f.isStorage) storages.add(f)
      }
    }

    ctors.each    |x| { nl.method(x) }
    consts.each   |x| { nl.constGetter(x) }
    methods.each  |x| { nl.method(x) }
    storages.each |x| { fieldStorage(x) }
  }

  Void constGetter(FieldDef x)
  {
    slotScope(x)
    if (x.isStatic) w("static ")
    typeSig(x.fieldType).sp.fieldName(x)
    w("() { return ").fieldName(x).w("; }").nl
  }

  Void fieldStorage(FieldDef x)
  {
    if (!x.isSynthetic) w("private ")
    if (x.isStatic) w("static ")
    typeSig(x.fieldType).sp.fieldName(x).eos
    return this
  }

  Void method(MethodDef x)
  {
    this.curMethod = x

    if (x.isStaticInit)
      w("static ").block(x.code).nl.nl
    else if (x.isCtor)
      ctor(x)
    else
      stdMethod(x)

    this.curMethod = null
    this.selfVar   = null
  }

  Void ctor(MethodDef x)
  {
    // type of constructor
    selfType := x.parent

    // variable to use for this in implementation
    this.selfVar = "it"

    // flags
    slotScope(x)
    w("static ")

    // static Self name(...)
    typeSig(selfType).sp.methodName(x)
    params(x)

    // if static ctor its just a static method
    if (x.isStatic)
    {
      sp.block(x.code).nl
      return
    }

    // static factory side
    implName := JavaUtil.ctorImplName(x)
    w(" { ").nl
    indent
    typeSig(selfType).w(" it = new ").typeSig(selfType).w("();").nl
    w(implName).w("(it")
    x.params.each |p| { w(", ").varName(p.name) }
    w(");").nl
    w("return it;").nl
    unindent
    w("}").nl.nl

    // instance implementation side
    w("protected static void ").w(implName).w("(")
    typeSig(selfType).sp.w(selfVar)
    x.params.each |p| { w(", ").param(p) }
    w(") {").nl
    indent
    if (x.ctorChain != null)
    {
      chain     := x.ctorChain
      chainType := chain.target.id == ExprId.superExpr ? selfType.base : selfType
      chainName := JavaUtil.ctorImplName(chain.method)
      typeSig(chainType).w(".").w(chainName).w("(it").args(x.ctorChain.args, true).w(")").eos
    }
    x.code.stmts.each |s| { stmt(s) }
    unindent
    w("}").nl
  }

  Void stdMethod(MethodDef x)
  {
    // flags
    slotScope(x)
    if (x.isStatic) w("static ")

    // Returns name(...)
    typeSig(x.returns).sp.methodName(x)
    params(x)

    // body
    if (x.isAbstract) return eos
    sp.block(x.code).nl

    // generate a java main for all main(Str[] args) methods
    if (x.name == "main") javaMain(x)
  }

  Void samMethod(MethodDef x, FuncType funcType, CType[] funcParams)
  {
    // comment
    w("/** Function interface convenience for $x.name */").nl

    // flags
    slotScope(x)
    if (x.isStatic) w("static ")

    // Returns name(...)
    typeSig(x.returns).sp.methodName(x)

    // function name is based on method name
    samName := x.name.capitalize + funcParams.size
    samSig := samName
    samGenerics := StrBuf()
    funcParams.each |p|
    {
      if (p.isGenericParameter) samGenerics.join(p.name, ",")
    }
    if (!samGenerics.isEmpty) samSig = "$samName<$samGenerics>"

    // params
    w("(")
    needComma := false
    x.params.eachRange(0..-2) |p|
    {
      if (needComma) w(", "); else needComma = true
      param(p)
    }
    if (needComma) w(", ")
    w(samSig).sp.varName(x.params.last.name).w(") {").nl

    // generate unique names for call that don't conflict with method params
    callNames := Str[,]
    funcParams.each |p, i|
    {
      name := 'a'.plus(i).toChar
      if (x.params.any { it.name == name }) name = "_$name"
      callNames.add(name)
    }

    // body creates Func.SamX:
    //   return foo(p, q, new Func.Sam2() {
    //     public Object call(Object a, Object b) { c.call((P)p, (Q)q) }
    //   });
    indent
    isVoid := funcType.returns.isVoid
    if (!isVoid) w("return ")
    if (x.isStatic) typeSig(x.parent).w("."); else w("this.")
    methodName(x).w("(")
    needComma = false
    x.params.eachRange(0..-2) |p|
    {
      if (needComma) w(", "); else needComma = true
      param(p)
    }
    if (needComma) w(", ")
    w("new Func.Sam").w(funcParams.size).w("() {").nl
      indent
      w("public final Object call(")
      callNames.each |n, i| { if (i > 0) w(", "); w("Object ").w(n) }
      w(") {").nl
        indent
        if (!isVoid) w("return ")
        w(x.params.last.name).w(".call(")
        callNames.each |n, i| { if (i > 0) w(", "); w("(").typeSig(funcParams[i]).w(")").w(n) }
        w(");")
        if (isVoid) w(" return null;")
        nl
        unindent
      w("}").nl
      unindent
    w("});").nl
    unindent
    w("}").nl
    nl

    // single abstract method interface itself
    w("/** Function interface for $x.name */").nl
    w("public static interface ").w(samSig).w(" {").nl
    indent
    w("public abstract ").typeSig(funcType.returns).sp.w("call(")
    funcParams.each |p, i|
    {
      if (i > 0) w(", ")
      typeSig(p).sp.varName(funcType.names[i])
    }
    w(");").nl
    unindent
    w("}").nl
  }

  This params(MethodDef x)
  {
    w("(")
    x.params.each |p, i|
    {
      if (i > 0) w(", ")
      param(p)
    }
    return w(")")
  }

  Void param(ParamDef p)
  {
    typeSig(p.type).sp.varName(p.name)
  }

  Bool isJavaMain(MethodDef x)
  {
    x.name == "main" && x.params.size == 1 && x.params[0].type.isList
  }

  Void javaMain(MethodDef x)
  {
    nl
    w("/** Java main */").nl
    w("public static void main(String[] args) {").nl
    indent
    if (!x.isStatic) w("make().")
    w("main(").qnList.w(".make(").qnSys.w(".StrType, args));").nl
    unindent
    w("}").nl
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  override This exprStmt(ExprStmt x)
  {
    expr(x.expr).eos
  }

  override This localDefStmt(LocalDefStmt x)
  {
    doLocalDefStmt(x).eos
  }

  private This doLocalDefStmt(LocalDefStmt x)
  {
    typeSig(x.ctype).sp.varName(x.name)
    if (x.init != null) w(" = ").expr(x.initVal)
    return this
  }

  override This ifStmt(IfStmt x)
  {
    w("if (").expr(x.condition).w(") ")
    block(x.trueBlock)
    if (x.falseBlock != null) w(" else ").block(x.falseBlock)
    return nl
  }

  override This returnStmt(ReturnStmt x)
  {
    if (curMethod.isStaticInit) return this

    w("return")
    if (x.expr != null) sp.expr(x.expr)
    return eos
  }

  override This throwStmt(ThrowStmt x)
  {
    w("throw ").expr(x.exception).eos
  }

  override This tryStmt(TryStmt x)
  {
    w("try").sp
    block(x.block).nl
    x.catches.each |c|
    {
      // remove first stmt which redeclares local var
      first := c.block.stmts.removeAt(0)
      if (first.id != StmtId.localDef) throw Err("try block $x.loc.toLocStr")

      w("catch (").typeSig(c.errType).w(" ").varName(c.errVariable).w(")").sp
      block(c.block).nl
    }
    if (x.finallyBlock != null)
    {
      w("finally").sp
      block(x.finallyBlock).nl
    }
    return this
  }

  override This forStmt(ForStmt x)
  {
    w("for (")
    if (x.init != null)
    {
      // can only be expr or local
      switch (x.init.id)
      {
        case StmtId.expr:      expr(((ExprStmt)x.init).expr)
        case StmtId.localDef:  doLocalDefStmt(x.init)
        default:               throw Err(x.init.toStr)
      }
    }
    w("; ")
    expr(x.condition)
    w("; ")
    if (x.update != null) expr(x.update)
    w(")").sp
    block(x.block)
    return nl
  }

  override This whileStmt(WhileStmt x)
  {
    w("while (").expr(x.condition).w(") ").block(x.block).nl
  }

  override This breakStmt(BreakStmt x)
  {
    w("break").eos
  }

  override This continueStmt(ContinueStmt x)
  {
    w("continue").eos
  }

  override This block(Block x)
  {
    if (x.isEmpty) return w("{}")
    w("{").nl
    indent
    x.stmts.each |s| { stmt(s) }
    unindent
    w("}")
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Switch
//////////////////////////////////////////////////////////////////////////

  override This switchStmt(SwitchStmt x)
  {
    if (isJavaSwitch(x))
      javaSwitch(x)
    else
      ifElseSwitch(x)
    return this
  }

  private Bool isJavaSwitch(SwitchStmt x)
  {
    x.cases.all |c|
    {
      c.cases.all |e| { isJavaSwitchCase(e) }
    }
  }

  private Void javaSwitch(SwitchStmt x)
  {
    w("switch(").switchCondition(x.condition).w(") {").nl
    indent
    x.cases.each |c|
    {
      c.cases.each |caseExpr|
      {
        w("case ").caseCondition(caseExpr).w(": ").nl
      }
      switchBlock(c.block)
    }
    if (x.defaultBlock != null)
    {
      w("default:").nl
      switchBlock(x.defaultBlock)
    }
    unindent
    w("}").nl
    return this
  }

  private Void ifElseSwitch(SwitchStmt x)
  {
    condVar := curMethod.transpileTempVar
    cond := x.condition
    typeSig(cond.ctype).sp.w(condVar).w(" = ").expr(cond).eos
    x.cases.each |c, i|
    {
      if (i > 0) w("else ")
      w(" if (")
      c.cases.each |caseExpr, j|
      {
        if  (j > 0) w(" || ")
        qnOpUtil.w(".compareEQ(").w(condVar).w(", ").expr(caseExpr).w(")")
      }
      w(")")
      if (c.block == null) w(" {}").nl
      else block(c.block)
      nl
    }
    if (x.defaultBlock != null)
    {
      w("else ").block(x.defaultBlock).nl
    }
  }

  private This switchCondition(Expr x)
  {
    if (x.ctype.isInt)
    {
      if (x.ctype.isNullable) return w("((Long)").expr(x).w(").intValue()")
      w("(int)")
    }
    else if (x.ctype.isEnum)
    {
      return w("(int)").expr(x).w(".ordinal()")
    }
    return expr(x)
  }

  private Bool isJavaSwitchCase(Expr x)
  {
    if (x.id === ExprId.intLiteral) return true
    if (x.id === ExprId.strLiteral) return true
    if (x.id === ExprId.field) return ((FieldExpr)x).field.isEnum
    return false
  }

  private This caseCondition(Expr x)
  {
    if (x.id === ExprId.intLiteral) return w(((LiteralExpr)x).val)
    if (x.id === ExprId.strLiteral) return str(((LiteralExpr)x).val)
    if (x.id === ExprId.field)
    {
      f := ((FieldExpr)x).field
      return typeSig(f.parent).w(".").w(f.name.upper)
    }
    throw Err("TODO: $x.id $x")
  }

  private This switchBlock(Block? b)
  {
    if (b == null) return this
    indent
    b.stmts.each |s| { stmt(s) }
    if (!b.isExit) w("break").eos
    unindent
    return this
  }

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
    oparen.w("(").typeSig(x.check).w(")(").expr(x.target).w(")").cparen
  }

//////////////////////////////////////////////////////////////////////////
// Local Vars
//////////////////////////////////////////////////////////////////////////

  override This localExpr(LocalVarExpr x) { varName(x.name) }

  override This thisExpr(LocalVarExpr x) { w(selfVar ?: "this") }

  override This superExpr(LocalVarExpr x) { w("super") }

  override This itExpr(LocalVarExpr x) { w("it") }

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

//////////////////////////////////////////////////////////////////////////
// Assign
//////////////////////////////////////////////////////////////////////////

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
    call(x.targetx, x.method, x.args)
  }

  private This call(Expr target, CMethod method, Expr[] args)
  {
    targetType := target.ctype
    methodName := JavaUtil.methodName(method)

    // special handling for Obj.compare => fan.sys.FanObj.compare, etc
    if (targetType != null && JavaUtil.isJavaNative(targetType))
    {
      qnFanVal(targetType).w(".").w(methodName).w("(")
      if (!method.isStatic) expr(target).args(args, true)
      else this.args(args)
      w(")")
      return this
    }

    return expr(target).w(".").w(methodName).w("(").args(args).w(")")
  }

  private This args(Expr[] args, Bool forceComma := false)
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
    // NOTE: this only works if closure only uses effectively final locals
    safe(x.target, x.ctype) |me|
    {
      me.call(ItExpr(x.loc, x.target.ctype), x.method, x.args)
    }
  }

  ** Common code for "?.method()" and "?.field"
  ** NOTE: this requires a Java closure, so only works for effectively final locals
  private This safe(Expr target, CType returns, |This| restViaItArg)
  {
    qnOpUtil.w(".<").typeSig(target.ctype)
    if (returns.isVal)
    {
      // value types use safeBool(), safeInt(), or safeFloat()
      w(">safe${returns.name}(")
    }
    else
    {
      // Ojects use safe()
      w(",").typeSig(returns).w(">safe(")
    }
    expr(target).w(", (it)->")
    restViaItArg(this)
    w(")")
    return this
  }

  override This elvisExpr(BinaryExpr x)
  {
    // NOTE: this only works if closure only uses effectively final locals
    qnOpUtil.w(".<").typeSig(x.ctype).w(">elvis(")
      .expr(x.lhs)
      .w(", ()->").expr(x.rhs)
      .w(")")
  }

  override This ctorExpr(CallExpr x)
  {
    expr(x.target).w(".").methodName(x.method).w("(").args(x.args).w(")")
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
    // only support Int/Float or Str +=
    if (!isJavaNumVal(x.method.parent) && x.method.qname != "sys::Str.plus")
      throw Err("Shortcut not supported: $x.method.qname [$x.loc.toLocStr]")

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

  private This shortcutAssignField(ShortcutExpr x, FieldExpr fe)
  {
    // NOTE: this assumes idempotent field access
    loc := fe.loc
    getAndCall := CallExpr(loc, fe, x.method, x.args)
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
    expr(coll).w(".set(").expr(key).w(", ").expr(getAndCall).w(")")
    return this
  }

  override This postfixLeaveExpr(ShortcutExpr x)
  {
    // only support Int/Float
    if (!isJavaNumVal(x.method.parent))
      throw Err("Postfix not supported: $x.method.qname")

    // incremnet or decrement
    name := x.method.name
    oparen.expr(x.target).cparen
    if (name == "increment") w("++")
    else if (name == "decrment") w("--")
    else throw Err("Postfix $x.method.qname")
    return this
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
      return safe(x.target, f.fieldType) |me|
      {
        me.w("(").typeSig(f.fieldType).w(")").getField(x)
      }
    }
    else
    {
      return getField(x)
    }
  }

  private This getField(FieldExpr x)
  {
    // special handling for fan.sys.FanBool.xxx
    field := x.field
    targetType := x.target?.ctype
    if (targetType != null && JavaUtil.isJavaNative(targetType))
    {
      qnFanVal(targetType).w(".").fieldName(field)
      return this
    }

    if (x.target != null) expr(x.target).w(".")
    fieldName(field)
    if (useFieldCall(x)) w("()")

    return this
  }

  private Bool useFieldCall(FieldExpr x)
  {
    if (curMethod.isGetter || curMethod.isSetter) return true
    if (x.field.isSynthetic) return false
    if (x.field.parent.pod.name == "sys" && !x.useAccessor) return false
    return true
  }

  private This fieldAssign(FieldExpr x, Expr rhs)
  {
    if (x.target != null) expr(x.target).w(".")
    fieldName(x.field)
    if (x.useAccessor)
      w("(").expr(rhs).w(")")
    else
      w(" = ").expr(rhs)
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Closures & Synthetics
//////////////////////////////////////////////////////////////////////////

  override This closureExpr(ClosureExpr x)
  {
    callMethodExpr(x.substitute)
  }

  private Void syntheticClasses(TypeDef parent)
  {
    // gen synthetic classes associated with TypeDef as inner classes
    prefix := parent.qname + "\$"
    parent.podDef.typeDefs.each |x|
    {
      if (JavaUtil.isSyntheticInner(parent, x))
        syntheticClass(x,  JavaUtil.syntheticInnerClass(x))
    }

    // also generate every wrapper used as an inner class
    wrappers.each |x|
    {
      syntheticClass(x, x.name)
    }

  }

  private Void syntheticClass(TypeDef x, Str name)
  {
    nl
    w("/** Synthetic closure support */").nl
    w("static final class ").w(name).extends(x).w(" {").nl
    indent
    slots(x)
    unindent
    w("}").nl
  }

//////////////////////////////////////////////////////////////////////////
// Choke point for qualified names
//////////////////////////////////////////////////////////////////////////

  This qnOpUtil() { w("OpUtil") }

  This qnFanObj() { w("FanObj") }

  This qnFanVal(CType t) { w("Fan").w(t.name) } // FanStr, FanInt, FanBool, etc

  This qnList() { w("List") }

  This qnMap() { w("Map") }

  This qnType() { w("Type") }

  This qnSys() { w("Sys") }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  This slotScope(SlotDef x)
  {
    if (x.isPublic)  return w("public ")
    if (x.isPrivate) return w("private ")
    return this
  }

  This typeName(CType t)
  {
    w(JavaUtil.typeName(t))
  }

  This fieldName(CField x)
  {
    w(JavaUtil.fieldName(x))
  }

  This methodName(CMethod x)
  {
    w(JavaUtil.methodName(x))
  }

  This varName(Str x)
  {
    w(JavaUtil.varName(x))
  }

  This typeSig(CType t, Bool parameterize := true)
  {
    // speical handling for system types
    if (t.pod.name == "sys")
    {
      if (t.isVoid)      return w("void")
      if (t.isObj)       return w("Object")
      if (t.isStr)       return w("String")
      if (t.isBool)      return t.isNullable ? w("Boolean") : w("boolean")
      if (t.isInt)       return t.isNullable ? w("Long") : w("long")
      if (t.isFloat)     return t.isNullable ? w("Double") : w("double")
      if (t.isDecimal)   return w("java.math.BigDecimal")
      if (t.isNum)       return w("java.lang.Number")
      if (t.isType)      return qnType
      if (t.isThis)      return typeSig(curType)
      if (t is ListType) return listSig(t, parameterize)
      if (t is MapType)  return mapSig(t, parameterize)
      if (t.isGenericParameter)
      {
        if (t.name == "L") return qnList.w("<V>")
        if (t.name == "M") return qnMap.w("<K,V>")
        return w(t.name)
      }
    }

    // assume synthetics are my own inner classes
    if (t.isSynthetic)
    {
      if (JavaUtil.isSyntheticWrapper(t))
      {
        // keep track of synthetic wrappers used by parent type
        wrappers[t.name] = t
        return w(t.name)
      }
      else
      {
        // closure synthetic
        return w(JavaUtil.syntheticInnerClass(t))
      }
    }

    // qname
    return w("fan.").w(t.pod.name).w(".").typeName(t)
  }

  This listSig(ListType t, Bool parameterize)
  {
    qnList
    if (parameterize) w("<").typeSigNullable(t.v).w(">")
    return this
  }

  This mapSig(MapType t, Bool parameterize)
  {
    qnMap
    if (parameterize) w("<").typeSigNullable(t.k).w(",").typeSigNullable(t.v).w(">")
    return this
  }

  This typeSigNullable(CType t, Bool parameterize := true)
  {
    if (t.isVal)
    {
      if (t.isBool)    return w("Boolean")
      if (t.isInt)     return w("Long")
      if (t.isFloat)   return w("Double")
    }
    return typeSig(t, parameterize)
  }

  This str(Obj x) { w(x.toStr.toCode) }

  This eos() { w(";").nl }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private TypeDef? curType
  private Str:TypeDef wrappers := [:]
  private MethodDef? curMethod
  private Str? selfVar
}

