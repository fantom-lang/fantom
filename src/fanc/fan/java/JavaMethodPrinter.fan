//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split from JavaPrinter
//

using compiler

**
** Java transpiler printer for methods
**
internal class JavaMethodPrinter : JavaPrinter
{
  new make(JavaPrinter parent) : super(parent) {}

  override JavaPrinterState m() { super.m }

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

  private Void ctor(MethodDef x)
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

  private Void stdMethod(MethodDef x)
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

  private This methodSig(MethodDef x, Int numParams)
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

  private Void methodParamDefaults(MethodDef x)
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

  private This nativeMethodCode(MethodDef x)
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

  private Void samMethod(MethodDef x, FuncType funcType, CType[] funcParams)
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

  private This params(MethodDef x, Int numParams)
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

