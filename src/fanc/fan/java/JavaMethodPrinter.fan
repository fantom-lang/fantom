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
  new make(JavaPrinter base, MethodDef def) : super(base)
  {
    this.def  = def
    this.name = JavaUtil.methodName(def)
  }

  override JavaPrinterState m() { super.m }

//////////////////////////////////////////////////////////////////////////
// Top
//////////////////////////////////////////////////////////////////////////

  Void print()
  {
    // Fantom implementation
    if (isStaticInit)
      staticInit
    else if (isCtor)
      ctor
    else
      method

    // Java main for all main(Str[] args) methods
    if (isJavaMain) javaMain
  }

  private Void staticInit()
  {
     w("static ").code.nl
  }

  private Void method()
  {
    // param default conveniences
    paramDefaults

    // implementation signature
    methodSig

    // body
    if (isAbstract) return eos
    if (isNative)   return sp.nativeCode.nl
    sp.code.nl
  }

  private Void ctor()
  {
    // use this varaiable instead of this in expressions
    m.selfVar = "self\$"

    // static factory side of constructor
    if (isStatic || !parent.isAbstract) ctorFactory

    // instance initialization implementation side of constructor
    if (!isStatic) ctorImpl
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  private Void ctorFactory()
  {
    // param default conveniences
    paramDefaults

    // full parameter factory method
    methodSig

    // if static ctor its just a static method
    if (isStatic)
    {
      sp.code.nl
      return
    }

    w(" { ").nl
    indent

    // fan.acme.Foo self$ = new fan.acmeFoo()
    typeSig(selfType).sp.w(selfVar).w(" = new ").typeSig(selfType).w("()").eos

    // make$(self$, ....)
    w(implName).w("(").w(selfVar)
    paramDefs.each |p| { w(", ").varName(p.name) }
    w(")").eos

    w("return ").w(selfVar).eos
    unindent
    w("}").nl.nl
  }

  private Void ctorImpl()
  {
    // param default conveniences
    paramDefaults(true)

    // signature
    ctorImplSig

    sp.w("{").nl
    indent

    // this or super chain
    if (def.ctorChain != null)
    {
      chain     := def.ctorChain
      chainType := chain.target.id == ExprId.superExpr ? selfType.base : selfType
      chainName := JavaUtil.ctorImplName(chain.method)
      typeSig(chainType).w(".").w(chainName).w("(").w(selfVar).args(def.ctorChain.args, true).w(")").eos
    }

    // rest of code
    def.code.stmts.each |s| { stmt(s) }

    unindent
    w("}").nl
  }

  private CType selfType() { parent }

  private Str implName() {  JavaUtil.ctorImplName(def) }

//////////////////////////////////////////////////////////////////////////
// Param Default Conveniences
//////////////////////////////////////////////////////////////////////////

  private Void paramDefaults(Bool isCtorImpl := false)
  {
    starti := paramDefs.findIndex |p| { p.hasDefault }
    if (starti == null) return

    for (i := starti; i<paramDefs.size; ++i)
      paramDefault(isCtorImpl, i)
  }

  private Void paramDefault(Bool isCtorImpl, Int numParams)
  {
    w("/** Convenience for $name */").nl
    if (isCtorImpl)
      ctorImplSig(numParams)
    else
      methodSig(numParams)
    if (isAbstract) return eos.nl

    w(" {").nl
    indent

    thrus := paramDefs[0..<numParams]
    defs  := paramDefs[numParams..-1]

    // if a param uses previous param, then the compiler adds an assign expr;
    // this requires us to generate these are local varaible definitions
    defs.each |p|
    {
      if (p.isAssign) typeSig(p.type).sp.expr(p.def).eos
    }

    // call implementation version
    first := true
    if (isCtorImpl)
    {
      w(implName).w("(").w(selfVar)
      first = false
    }
    else
    {
      if (!returns.isVoid || isCtor) w("return ")
      w(name).w("(")
    }

    // pass thru arguments
    thrus.each |p|
    {
      if (first) first = false
      else w(", ")
      varName(p.name)
    }

    // default expression arguments
    defs.each |p|
    {
      if (first) first = false
      else w(", ")
      if (p.isAssign) varName(p.name) // use local variable
      else if (name == "trap") w("(").qnList.w(")null") // special case for amibiguity
      else expr(p.def) // inline expression
    }
    w(")").eos

    unindent
    w("}").nl
    nl
  }

//////////////////////////////////////////////////////////////////////////
// Signature
//////////////////////////////////////////////////////////////////////////

  private This methodSig(Int numParams := paramDefs.size)
  {
    // flags
    slotScope(def)
    if (isStatic || isCtor) w("static ")
    if (isAbstract) w("abstract ")
    else if (parent.isMixin && !isStatic) w("default ")

    // return name(...)
    returnsSig.sp.w(name).w("(").paramsSig(true, numParams).w(")")
    return this
  }

  private This returnsSig()
  {
    // ctor always returns parent type
    if (isCtor) return typeSig(parent)

    // always return just return Object in closure doCall
    if (name == "doCall" && parent.isFunc && !returns.isVoid)
      return w("Object")

    // parameterized list/map cannot be covariant
    if (returns.isParameterized && (returns.isList || returns.isMap))
    {
      return typeSig(def.inheritedRet ?: returns)
    }

    return typeSig(returns)
  }

  private This ctorImplSig(Int numParams := paramDefs.size)
  {
    w("protected static void ").w(implName).w("(")
    typeSig(selfType).sp.w(selfVar)
    paramsSig(false, numParams)
    w(")")
    return this
  }

  private This paramsSig(Bool first, Int numParams)
  {
    paramDefs.eachRange(0..<numParams) |p, i|
    {
      if (first) first = false
      else w(", ")
      paramSig(p)
    }
    return this
  }

  private Void paramSig(ParamDef p)
  {
    typeSig(p.type).sp.varName(p.name)
  }

//////////////////////////////////////////////////////////////////////////
// Native Code
//////////////////////////////////////////////////////////////////////////

  private This nativeCode()
  {
    w("{").nl
    indent
    if (!returns.isVoid) w("return ")
    first := true
    if (isStatic)
    {
      w(JavaUtil.peerTypeName(curType)).w(".").w(name).w("(")
    }
    else
    {
      w(JavaUtil.peerFieldName).w(".").w(name).w("(this")
      first = false
    }
    paramDefs.each |p|
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

//////////////////////////////////////////////////////////////////////////
// Code
//////////////////////////////////////////////////////////////////////////

  private This code()
  {
    code := def.code ?: throw Err("No code")
    w("{").nl
    indent
    if (isNoJava(code.stmts.first))
    {
      // backdoor hook to skip code generation if first line is:
      // __noJava := xxx
      if (!returns.isVoid) w("  throw fan.sys.UnsupportedErr.make(\"no java\")").eos
    }
    else
    {
      // otherwise generate code until we hit a __noJava def
      sp := JavaStmtPrinter(this)
      code.stmts.eachWhile |x|
      {
        if (isNoJava(x)) return "break"
        sp.stmt(x)
        return null
      }
    }
    return unindent.w("}")
 }

  private Bool isNoJava(Stmt x)
  {
    x.id === StmtId.localDef && ((LocalDefStmt)x).name == "__noJava"
  }

//////////////////////////////////////////////////////////////////////////
// SAM
//////////////////////////////////////////////////////////////////////////

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
    paramDefs.eachRange(0..-2) |p|
    {
      if (needComma) w(", "); else needComma = true
      paramSig(p)
    }
    if (needComma) w(", ")
    w(samSig).sp.varName(paramDefs.last.name).w(") {").nl

    // generate unique names for call that don't conflict with method params
    callNames := Str[,]
    funcParams.each |p, i|
    {
      name := 'a'.plus(i).toChar
      if (paramDefs.any { it.name == name }) name = "_$name"
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
    paramDefs.eachRange(0..-2) |p|
    {
      if (needComma) w(", "); else needComma = true
      paramSig(p)
    }
    if (needComma) w(", ")
    w("new Func.Sam").w(funcParams.size).w("() {").nl
      indent
      w("public final Object call(")
      callNames.each |n, i| { if (i > 0) w(", "); w("Object ").w(n) }
      w(") {").nl
        indent
        if (!isVoid) w("return ")
        w(paramDefs.last.name).w(".call(")
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

//////////////////////////////////////////////////////////////////////////
// Java Main
//////////////////////////////////////////////////////////////////////////

  Bool isJavaMain()
  {
    !parent.isAbstract && name == "main" && paramDefs.size == 1 && paramDefs[0].type.isList
  }

  Void javaMain()
  {
    nl
    w("/** Java main */").nl
    w("public static void main(String[] args) {").nl
    indent
    if (!isStatic) w("make().")
    w("main(").qnList.w(".make(").qnSys.w(".StrType, args));").nl
    unindent
    w("}").nl
  }

//////////////////////////////////////////////////////////////////////////
// Method Access
//////////////////////////////////////////////////////////////////////////

  MethodDef def

  const Str name

  TypeDef parent() { def.parentDef }

  CType returns() { def.returns }

  ParamDef[] paramDefs() { def.params }

  Bool isStaticInit() { def.isStaticInit }

  Bool isStatic() { def.isStatic }

  Bool isCtor() { def.isCtor }

  Bool isAbstract() { def.isAbstract }

  Bool isNative() { def.isNative }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  This stmt(Stmt stmt)
  {
    JavaStmtPrinter(this).stmt(stmt)
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

