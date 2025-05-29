//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split from JavaPrinter
//

using compiler

**
** Java transpiler printer for types
**
internal class JavaTypePrinter : JavaPrinter
{
  new make(OutStream out) : super.makeTop(out) {}

  override JavaPrinterState m() { super.m }

  Void type(TypeDef t)
  {
    m.curType = t
    wrappers.clear

    prelude(t)
    typeHeader(t)
    w(" {").nl
    indent
    typeOf(t)
    enumOrdinals(t)
    slots(t)
    syntheticClasses(t)
    nativePeer(t)
    unindent
    w("}").nl

    m.curType = null
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
    w("import fan.sys.FanNum").eos
    w("import fan.sys.FanInt").eos
    w("import fan.sys.FanFloat").eos
    w("import fan.sys.FanStr").eos
    w("import fan.sys.List").eos
    w("import fan.sys.Map").eos
    w("import fan.sys.Type").eos
    w("import fan.sys.Func").eos
    w("import fan.sys.Sys").eos
    w("import fanx.util.OpUtil").eos
    nl
  }

  Void typeHeader(TypeDef t)
  {
    // scope
    if (t.isPublic) w("public ")
    if (t.isAbstract) w("abstract ")
    if (t.isFinal) w("final ")

    // interface vs class
    w(t.isMixin ? "interface" : "class").sp.typeName(t)

    // extends
    if (!t.isMixin) extends(t)

    // implements
    if (!t.mixins.isEmpty) implements(t)
  }

  This extends(TypeDef t)
  {
    w(" extends ")
    if (t.base.isObj) qnFanObj
    else if (t.isClosure) w(JavaUtil.closureBase(t))
    else typeSig(t.base)
    return this
  }

  This implements(TypeDef t)
  {
    if (t.isMixin)
      w(" extends ")
    else
      w(" implements ")
    t.mixins.each |m, i|
    {
      if (i > 0) w(", ")
      typeSig(m)
    }
    return this
  }

  Void typeOf(TypeDef t)
  {
    if (t.isSynthetic) return

    if (t.isMixin)
    {
      // for mixins:
      // - don't generate typeof()
      // - don't generate cache static variable; lookup every call
      w("/** Type literal for $t.qname */").nl
      w("public static ").qnType.w(" typeof\$() { return ")
      qnType.w(".find(").str(t.qname).w("); }").nl
    }
    else
    {
      // normal classes:
      //   public Type typeof() { typeof$() }
      //   public static Type typeof$() {
      //     if (typeof$cache == null)
      //       typeof$cache = Type.find("foo::Foo");
      //     return typeof$cache;
      //   }
      //   private static Type typeof$cache;      w("/** Type literal for $t.qname */").nl
      w("/** Reflect type of this object */").nl
      w("public ").qnType.w(" typeof() { return typeof\$(); }").nl
      nl
      w("public static ").qnType.w(" typeof\$() {").nl
      w("  if (typeof\$cache == null)").nl
      w("    typeof\$cache = ").qnType.w(".find(").str(t.qname).w(");").nl
      w("  return typeof\$cache;").nl
      w("}").nl
      w("private static ").qnType.w(" typeof\$cache;").nl
    }
  }

  Void enumOrdinals(TypeDef t)
  {
    if (!t.isEnum) return

    nl
    t.enumDefs.each |e|
    {
      name := e.name.upper
      if (t.slot(name) != null) name = "_$name"
      w("public static final int ").w(name).w(" = ").w(e.ordinal).eos
    }
  }

  Void nativePeer(TypeDef t)
  {
    if (!curType.hasNativePeer) return

    nl.w("private ").w(JavaUtil.peerTypeName(t)).sp.w(JavaUtil.peerFieldName).eos
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
    MethodDef? staticInit

    t.slotDefs.each |x|
    {
      if (x is MethodDef)
      {
        m := (MethodDef)x
        if (m.isCtor || m.isInstanceInit)
          ctors.add(m)
        else if (m.isStaticInit)
          staticInit = m
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
    consts.each   |x| { nl.constAccessors(x) }
    methods.each  |x| { nl.method(x) }
    if (!t.isMixin)
    {
      if (staticInit != null) nl.method(staticInit)
      storages.each |x| { fieldStorage(x) }
    }
    else
    {
      mixinStaticFields(staticInit, storages)
    }
  }

  Void constAccessors(FieldDef x)
  {
    slotScope(x)
    if (x.isStatic) w("static ")
    typeSig(x.type).sp.fieldName(x)

    w("() { return ")
    if (x.parent.isMixin) w(JavaUtil.mixinFieldsName).w(".")
    fieldName(x).w("; }").nl

    // if the current class has an it-block ctor then
    // generate special setting that takes the it-block func
    if (curType.hasItBlockCtor)
    {
      nl
      w("/** Initialize const field $x.name - DO NOT USE DIRECTLY */").nl
      slotScope(x)
      if (x.isStatic) w("static ")
      w("void ").fieldName(x).w("\$init(").qnFunc.w(" f, ").typeSig(x.type).w(" it) {")
      w("}").nl
    }
  }

  Void fieldStorage(FieldDef x)
  {
    if (!x.isSynthetic && !x.isEnum) w("private ")
    if (x.isStatic) w("static ")
    typeSig(x.type).sp.fieldName(x).eos
    return this
  }

  Void mixinStaticFields(MethodDef? init, FieldDef[] fields)
  {
    // Java interfaces don't support static fields nor initializers;
    // so generate an inner class named Fields that declares storage
    // and handles static initilizer.  We swizzle get via constGetter()
    // and set in fieldAssign()
    nl.w("static class ").w(JavaUtil.mixinFieldsName).w(" {").nl
    indent
    fields.each |f| { fieldStorage(f) }
    if (init != null) method(init)
    unindent
    w("}").nl
  }

  Void method(MethodDef x)
  {
    m.curMethod = x

    if (x.isStaticInit)
      w("static ").block(x.code).nl.nl
    else if (x.isCtor)
      ctor(x)
    else
      stdMethod(x)

    m.curMethod = null
    m.selfVar   = null
  }

  Void ctor(MethodDef x)
  {
    // type of constructor
    selfType := x.parent

    // variable to use for this in implementation
    m.selfVar = "self\$"

    // make$ method name
    implName := JavaUtil.ctorImplName(x)

    // static factory side
    if (!curType.isAbstract || x.isStatic)
    {
      // param default conveniences
      methodParamDefaults(x)

      // full parameter factory method
      methodSig(x, x.params.size)

      // if static ctor its just a static method
      if (x.isStatic)
      {
        sp.block(x.code).nl
        return
      }

      w(" { ").nl
      indent

      // fan.acme.Foo self$ = new fan.acmeFoo()
      typeSig(selfType).sp.w(selfVar).w(" = new ").typeSig(selfType).w("()").eos

      // self$.peer$ = FooPeer.make(self$)
      if (curType.hasNativePeer)
        w(selfVar).w(".").w(JavaUtil.peerFieldName).w(" = ").w(JavaUtil.peerTypeName(curType)).w(".make(").w(selfVar).w(")").eos

      // make$(self$, ....)
      w(implName).w("(").w(selfVar)
      x.params.each |p| { w(", ").varName(p.name) }
      w(")").eos

      w("return ").w(selfVar).eos
      unindent
      w("}").nl.nl
    }

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
      typeSig(chainType).w(".").w(chainName).w("(").w(selfVar).args(x.ctorChain.args, true).w(")").eos
    }
    x.code.stmts.each |s| { stmt(s) }
    unindent
    w("}").nl
  }

  Void stdMethod(MethodDef x)
  {
    // param default conveniences
    methodParamDefaults(x)

    // implementation signature
    methodSig(x, x.params.size)

    // body
    if (x.isAbstract) return eos
    if (x.isNative)   return sp.nativeMethodCode(x).nl
    sp.block(x.code).nl

    // generate a java main for all main(Str[] args) methods
    if (x.name == "main") javaMain(x)
  }

  This methodSig(MethodDef x, Int numParams)
  {
    // flags
    slotScope(x)
    if (x.isStatic || x.isCtor) w("static ")
    if (x.isAbstract) w("abstract ")
    else if (x.parent.isMixin && !x.isStatic) w("default ")

    // return type
    if (x.isCtor)
      typeSig(x.parent)
    else if (x.name == "doCall" && x.parent.isFunc && !x.returns.isVoid)
      w("Object") // just return object in closure doCall
    else
      typeSig(x.returns)

    // name(...)
    sp.methodName(x)
    params(x, numParams)
    return this
  }

  Void methodParamDefaults(MethodDef x)
  {
    starti := x.params.findIndex |p| { p.hasDefault }
    if (starti == null) return

    for (i := starti; i<x.params.size; ++i)
      methodParamDefault(x, i)
  }

  Void methodParamDefault(MethodDef x, Int numParams)
  {
    w("/** Convenience for $x.name */").nl
    methodSig(x, numParams)
    if (x.isAbstract) return eos.nl

     w(" {").nl
     indent

    thrus   := x.paramDefs[0..<numParams]
    defs    := x.paramDefs[numParams..-1]

    // if a param uses a previous param, then the compiler addsan assign expr;
    // this requires us to generate these are local varaible definitions
    defs.each |p|
    {
      if (p.isAssign) typeSig(p.type).sp.expr(p.def).eos
    }

    if (!x.returns.isVoid || x.isCtor) w("return ")
    methodName(x).w("(")
    first := true
    thrus.each |p|
    {
      if (first) first = false
      else w(", ")
      varName(p.name)
    }
    defs.each |p|
    {
      if (first) first = false
      else w(", ")
      if (p.isAssign) varName(p.name) // use local variable
      else expr(p.def) // inline expression
    }
    w(")").eos

    unindent
    w("}").nl
    nl
  }

  This nativeMethodCode(MethodDef x)
  {
    w("{").nl
    indent
    if (!x.returns.isVoid) w("return ")
    first := true
    if (x.isStatic)
    {
      w(JavaUtil.peerTypeName(curType)).w(".").methodName(x).w("(")
    }
    else
    {
      w(JavaUtil.peerFieldName).w(".").methodName(x).w("(this")
      first = false
    }
    x.paramDefs.each |p|
    {
      if (first) first = false
      else w(", ")
      varName(p.name)
    }
    w(")").eos
    unindent
    w("}")
    return this
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

  This params(MethodDef x, Int numParams)
  {
    w("(")
    x.params.eachRange(0..<numParams) |p, i|
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
// Closures & Synthetics
//////////////////////////////////////////////////////////////////////////

  private Void syntheticClasses(TypeDef parent)
  {
    // gen synthetic classes associated with TypeDef as inner classes
    prefix := parent.qname + "\$"
    parent.podDef.typeDefs.each |x|
    {
      if (JavaUtil.isSyntheticClosure(parent, x))
      {
        m.closure = x
        syntheticClass(x,  JavaUtil.syntheticClosureName(x))
        m.closure = null
      }
    }

    // also generate every wrapper used as an inner class
    wrappers.each |x|
    {
      syntheticClass(x, JavaUtil.syntheticWrapperName(x))
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

  This slotScope(SlotDef x)
  {
    if (x.isPublic) return w("public ")
    if (x.isProtected) return w("public ")
    if (x.isPrivate && !x.parent.isMixin) return w("private ")
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  This stmt(Stmt stmt)
  {
    JavaStmtPrinter(this).stmt(stmt)
    return this
  }

  This block(Block block)
  {
    JavaStmtPrinter(this).block(block)
    return this
  }

  This expr(Expr expr)
  {
    JavaExprPrinter(this).expr(expr)
    return this
  }

  This args(Expr[] args, Bool forceComma := false)
  {
    JavaExprPrinter(this).args(args, forceComma)
    return this
  }

}

