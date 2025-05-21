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
    prelude(t)
    typeHeader(t)
    slots(t)
    unindent.w("}").nl
  }

  Void prelude(TypeDef t)
  {
    w("// Transpiled $Date.today").nl
    nl
    w("package fan.").w(t.pod.name).eos
    nl
  }

  Void typeHeader(TypeDef t)
  {
    // scope
    if (t.isPublic) w("public ")

    // interface vs class
    w(t.isMixin ? "interface" : "class").sp.typeName(t)

    // extends
    w(" extends ")
    if (t.base.isObj) w("fan.sys.FanObj")
    else if (t.isClosure) w(JavaUtil.closureBase(t))
    else typeSig(t.base)

    w(" {").nl
    indent
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
    w("public static void main(String[] args) {").nl
    indent
    if (!x.isStatic) w("make().")
    w("main(fan.sys.List.make(fan.sys.Sys.StrType, args));").nl
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

  private Bool isJavaSwitchCase(Expr expr)
  {
    expr.id === ExprId.intLiteral || expr.id === ExprId.strLiteral
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
    condVar := "_switch"
    cond := x.condition
    typeSig(cond.ctype).sp.w(condVar).w(" = ").expr(cond).eos
    x.cases.each |c, i|
    {
      if (i > 0) w("else ")
      w(" if (")
      c.cases.each |caseExpr, j|
      {
        if  (j > 0) w(" || ")
        w("fanx.util.OpUtil.compareEQ(").w(condVar).w(", ").expr(caseExpr).w(")")
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
    return expr(x)
  }

  private This caseCondition(Expr x)
  {
    if (x.id == ExprId.intLiteral) return w(((LiteralExpr)x).val)
    if (x.id == ExprId.strLiteral) return str(((LiteralExpr)x).val)
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
    w("fan.sys.Type.find(").str(t.qname).w(")")
  }

  override This slotLiteral(SlotLiteralExpr x)
  {
    find := x.slot is CField ? "findField" : "findMethod"
    w("fan.sys.Slot.").w(find).w("(").str("${x.parent.qname}.${x.name}").w(")")
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
    w("fan.sys.List.make(").doTypeLiteral(type.v).w(", ").w(x.vals.size).w(")")
    x.vals.each |item|
    {
      w(".add(").expr(item).w(")")
    }
    return this
  }

  override This mapLiteral(MapLiteralExpr x)
  {
    type := (MapType)x.ctype
    w("fan.sys.Map.makeKV(").doTypeLiteral(type.k).w(", ").doTypeLiteral(type.v).w(")")
    x.keys.each |key, i|
    {
      w(".set(").expr(key).w(", ").expr(x.vals[i]).w(")")
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
    oparen.expr(x.target).w(" instanceof ").typeSigNullable(x.check).cparen
  }

  override This isnotExpr(TypeCheckExpr x)
  {
    w("!(").expr(x.target).w(" instanceof ").typeSigNullable(x.check).w(")")
  }

  override This asExpr(TypeCheckExpr x)
  {
    w("as(").typeSigNullable(x.check).w(".class, ").expr(x.target).w(")")
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
    w("fanx.util.OpUtil.")
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
      w("fan.sys.Fan").w(targetType.name).w(".").w(methodName).w("(")
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
    w("fan.sys.FanObj.trap(").expr(x.target).w(", ").str(x.name)
    if (!x.args.isEmpty)
    {
      w(", fan.sys.List.makeObj(new Object[] {").args(x.args).w("})")
    }
    return w(")")
  }

  override This safeCallExpr(CallExpr x)
  {
    // uh Java is fun isn't it?
    w("java.util.Optional.<").typeSig(x.target.ctype).w(">ofNullable(").expr(x.target).w(")")
    w(".<").typeSig(x.ctype).w(">map(").w("it -> ")
    call(ItExpr(x.loc, x.target.ctype), x.method, x.args)
    w(").orElse(null)")
    return this
  }

  override This elvisExpr(BinaryExpr x)
  {
    // uh Java is fun isn't it?
    w("java.util.Optional.<").typeSig(x.ctype).w(">ofNullable(").expr(x.lhs).w(")")
    w(".orElse(").expr(x.rhs).w(")")
    return this
  }

  override This ctorExpr(CallExpr x)
  {
    expr(x.target).w(".").methodName(x.method).w("(").args(x.args).w(")")
  }

  override This staticTargetExpr(StaticTargetExpr x)
  {
    typeSig(x.ctype)
  }


  override This assignShortcutExpr(ShortcutExpr x)
  {
    // only support Int/Float
    if (!isJavaNumVal(x.method.parent))
      throw Err("Postfix not supported: $x.method.qname")

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
    // special handling for fan.sys.FanBool.xxx
    field := x.field
    targetType := x.target?.ctype
    if (targetType != null && JavaUtil.isJavaNative(targetType))
    {
      w("fan.sys.Fan").w(targetType.name).w(".").fieldName(field)
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
    if (x.field.parent.pod.name == "sys") return false
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
// Closures
//////////////////////////////////////////////////////////////////////////

  override This closureExpr(ClosureExpr x)
  {
    callMethodExpr(x.substitute)
  }

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

  This typeSig(CType t)
  {
    if (t.pod.name == "sys")
    {
      if (t.isVoid)    return w("void")
      if (t.isObj)     return w("Object")
      if (t.isStr)     return w("String")
      if (t.isBool)    return t.isNullable ? w("Boolean") : w("boolean")
      if (t.isInt)     return t.isNullable ? w("Long") : w("long")
      if (t.isFloat)   return t.isNullable ? w("Double") : w("double")
      if (t.isDecimal) return w("java.math.BigDecimal")
      if (t.isNum)     return w("java.lang.Number")
      if (t is ListType) return listSig(t)
      if (t.isGenericParameter)
      {
        if (t.name == "L") return w("fan.sys.List<V>")
        if (t.name == "M") return w("fan.sys.Map<K,V>")
        return w(t.name)
      }
    }
    return w("fan.").w(t.pod.name).w(".").typeName(t)
  }

  This listSig(ListType t)
  {
    w("fan.sys.List<").typeSig(t.v).w(">")
  }

  This typeSigNullable(CType t)
  {
    if (t.isVal)
    {
      if (t.isBool)    return w("Boolean")
      if (t.isInt)     return w("Long")
      if (t.isFloat)   return w("Double")
    }
    return typeSig(t)
  }

  This str(Obj x) { w(x.toStr.toCode) }

  This eos() { w(";").nl }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private MethodDef? curMethod
  private Str? selfVar
}

