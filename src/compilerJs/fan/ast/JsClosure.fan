//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Jun 15  Matthew Giannini Creation
//

using compiler

**
** Utility for working with JS closures. Shared by JsPod and JsClosureExpr
** for writing javascript related to closures.
**
** Every closure in JS requires that* we create a 'fan.sys.Func'. The Func
** requires a parameter list specification, as well as a 'fan.sys.FuncType'
** specification. This class analyzes all closures for the pod and creates
** static variables for each unique parameter list and  each unique function
** type specification. Then, when the actual closure Func is created and
** called, it uses those static fields instead of creating new instance each
**  time the closure is called.
**
class JsPodClosures : JsNode
{
  new make(JsCompilerSupport s) : super(s)
  {
  }

  ** Write the actual closure Func (JsClosureExpr)
  Void writeClosure(ClosureExpr ce, JsWriter out)
  {
    typeField   := mapFuncSpec(ce)
    paramsField := mapParams(ce)

    func := JsMethod(support, ce.doCall)
    sig  := func.sig(func.params)

    out.w("fan.sys.Func.make\$explicit(").nl
    out.indent

    // params
    out.w("${paramsField},").nl

    // func type
    out.w("${typeField},").nl

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

  ** Write the unique fields referenced by closures in this pod. (JsPod)
  override Void write(JsWriter out)
  {
    // write Func types
    varToType.each |JsMethod func, Str var|
    {
      out.w("${var} = new fan.sys.FuncType([")
      func.params.each |p, i|
      {
        if (i > 0) out.w(",")
        out.w("fan.sys.Type.find(\"${p.paramType.sig}\")")
      }
      out.w("], ")
      JsTypeLiteralExpr.writeType(func.ret, out)
      out.w(");").nl
    }

    // write params
    varToParams.each |JsMethodParam[] params, Str var|
    {
      out.w("${var} = fan.sys.List.make(fan.sys.Param.\$type, [")
      params.each |p,i|
      {
        if (i > 0) out.w(",")
        out.w("new fan.sys.Param(\"$p.name\",\"$p.paramType.sig\",$p.hasDef)")
      }
      out.w("]);").nl
    }
  }

  ** Creates a variable for the FuncType of this closure and returns
  ** the variable name. If we have seen a closure with the same
  ** FuncType already, then re-use that variable declaration and return
  ** the existing variable name.
  private Str mapFuncSpec(ClosureExpr ce)
  {
    funcType := ce.signature
    var := sigToTypeVar.getOrAdd(funcType.signature) |->Str|
    {
      "${pod(ce)}\$closType${support.unique}"
    }
    func := JsMethod(support, ce.doCall)
    varToType.getOrAdd(var) |->JsMethod| { func }
    return var
  }

  ** Creates a variable for the parameter list of this closure and
  ** returns the variable name. If we have seen a closure wit the
  ** exact same parameters (name, type, defVal), then re-use that variable
  ** declaration and return the existing variable name.
  private Str mapParams(ClosureExpr ce)
  {
    func := JsMethod(support, ce.doCall)
    var  := paramsKeyToVar.getOrAdd(paramsKey(func.params)) |->Str|
    {
      "${pod(ce)}\$closParams${support.unique}"
    }
    varToParams[var] = func.params
    return var
  }

  ** Create a unique key for a parameter list.
  private Str paramsKey(JsMethodParam[] params)
  {
    buf := StrBuf()
    params.each |p|
    {
      buf.add("${p.name}-${p.paramType.sig}-${p.hasDef},")
    }
    return buf.toStr
  }

  ** Get the pod variable prefix for all static closure variables.
  private Str pod(ClosureExpr ce) { "fan.${ce.enclosingType.pod}" }

  ** FuncType signature to variable name
  private [Str:Str] sigToTypeVar := [:]

  ** FuncType variable name to JsMethod for that closure
  private [Str:JsMethod] varToType := [:] { ordered = true }

  ** Parameter list key (`paramKey`) to variable name
  private [Str:Str] paramsKeyToVar := [:] { ordered = true }

  ** Paramater list variable name to JsMethodParam[]
  private [Str:JsMethodParam[]] varToParams := [:] { ordered = true }

}
