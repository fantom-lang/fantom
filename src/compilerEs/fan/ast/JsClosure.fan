//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2024  Matthew Giannini Creation
//

using compiler

**
** JsClosure provides utilities for working with JS closures.
**
class JsClosure : JsNode
{
  new make(CompilerSupport s) : super(s)
  {
  }

  Bool emitReflection() { c.input.jsReflectClosures }

  ** Write the actual ClosureExpr
  Void writeClosure(ClosureExpr ce)
  {

    CType[] sigTypes := [,].addAll(ce.signature.params).add(ce.signature.ret)
    isJs := sigTypes.all { !it.isForeign && checkJsSafety(it, loc) }
    if (isJs)
    {
      if (emitReflection)
      {
        js.wl("sys.Func.__reflect(").indent
        js.wl("${mapFuncSpec(ce)},", loc)
      }

      js.w("${methodParams(ce.doCall.params)}", loc).wl(" => {")
      js.indent
      old := plugin.thisName
      plugin.thisName = "this\$"
      writeBlock(ce.doCall.code)
      plugin.thisName = old
      js.unindent
      js.w("}")

      if (emitReflection)
      {
        js.w(")").unindent
      }
    }
    else
    {
      // this closure uses non-JS types. Write a closure that documents this fact
      js.wl("() => {")
      js.wl("  // Cannot write closure. Signature uses non-JS types: ${ce.signature}")
      js.wl("  throw sys.UnsupportedErr.make('Closure uses non-JS types: ' + ${ce.signature.toStr.toCode});")
      js.w("}")
    }
  }

  ** Write the unique closure specification fields for this pod (JsPod)
  override Void write()
  {
    varToFunc.each |MethodDef func, Str var|
    {
      loc := func.loc
      nullable := func.ret.isNullable ? ".toNullable()" : ""
      js.w("const ${var} = [${qnameToJs(func.ret)}.type\$${nullable},")
      js.w("sys.List.make(sys.Param.type\$, [")
      func.params.each |p,i|
      {
        if (i>0) js.w(",")
        js.w("new sys.Param(${p.name.toCode}, ${p.paramType.signature.toCode}, ${p.hasDefault})")
      }
      js.w("])")
        .w("];").nl
    }
    js.nl
  }

  private Str mapFuncSpec(ClosureExpr ce)
  {
    var := specKeyToVar.getOrAdd(specKey(ce)) |->Str| { "__clos${plugin.nextUid}" }
    varToFunc[var] = ce.doCall
    return var
  }

  private static Str specKey(ClosureExpr ce)
  {
    MethodDef func := ce.doCall
    buf := StrBuf()
    func.params.each |p|
    {
      buf.add("${p.name}-${p.paramType.signature}-${p.hasDefault},")
    }
    buf.add("${func.ret.signature}")
    return buf.toStr
  }

  ** Func spec key to field variable name
  private Str:Str specKeyToVar := [:]

  ** Func spec field variable name to prototype function (for params and return type)
  private Str:MethodDef varToFunc := [:] { ordered = true }
}