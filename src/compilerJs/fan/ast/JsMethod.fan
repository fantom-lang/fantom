//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsMethod
**
class JsMethod : JsSlot
{
  new make(JsCompilerSupport s, MethodDef m) : super(s, m)
  {
    this.parentPeer = JsType.findPeer(s, m.parent)
    this.isCtor     = m.isCtor
    this.isGetter   = m.isGetter
    this.isSetter   = m.isSetter
    this.params     = m.params.map |CParam p->JsMethodParam| { JsMethodParam(s, p) }
    this.ret        = JsTypeRef(s, m.ret)
    this.hasClosure = ClosureFinder(m).exists
    if (m.ctorChain != null) this.ctorChain = JsExpr.makeFor(s, m.ctorChain)
    if (m.code != null) this.code = JsBlock(s, m.code)
  }

  Bool isFieldAccessor() { isGetter || isSetter }

  override Void write(JsWriter out)
  {
    if (isCtor)
    {
      // write static factory make method
      ctorParams := [JsMethodParam.makeSelf(support)].addAll(params)
      out.w("${parent}.$name = function${sig(params)}
             {
               var self = new $parent();
               ${parent}.$name\$${sig(ctorParams)};
               return self;
             }").nl

      // write factory make$ method
      support.thisName = "self"
      writeMethod(out, "$name\$", ctorParams)
      support.thisName = "this"
    }
    else if (isSetter) writeMethod(out, "$name\$", params)
    else writeMethod(out, name, params)
  }

  Void writeMethod(JsWriter out, Str methName, JsMethodParam[] methParams)
  {
    // skip abstract methods
    if (isAbstract) return

    out.w(parent)
    if (!isStatic && !isCtor) out.w(".prototype")
    out.w(".$methName = function${sig(methParams)}").nl
    out.w("{").nl
    out.indent

    // def params
    params.each |p|
    {
      if (!p.hasDef) return
      out.w("if ($p.name === undefined) $p.name = ")
      p.defVal.write(out)
      out.w(";").nl
    }

    // closure support
    if (hasClosure) out.w("var \$this = $support.thisName;").nl

    if (isNative)
    {
      if (isStatic)
      {
        out.w("return ${parentPeer.qname}Peer.$methName${sig(methParams)};").nl
      }
      else
      {
        pars := isStatic ? params : [JsMethodParam.makeThis(support)].addAll(methParams)
        out.w("return this.peer.$methName${sig(pars)};").nl
      }
    }
    else
    {
      // ctor chaining
      if (ctorChain != null)
      {
        ctorChain.write(out)
        out.w(";").nl
      }

      // method body
      code?.write(out)
    }

    out.unindent
    out.w("}").nl
  }

  Str sig(JsMethodParam[] pars)
  {
    buf := StrBuf().addChar('(')
    pars.each |p,i|
    {
      if (i > 0) buf.addChar(',')
      buf.add(p.name)
    }
    buf.addChar(')')
    return buf.toStr
  }

  JsTypeRef? parentPeer   // parent peer if has one
  Bool isCtor             // is this method a constructor
  Bool isGetter           // is this method a field getter
  Bool isSetter           // is this method a field setter
  JsMethodParam[] params  // method params
  JsTypeRef ret           // return type for method
  Bool hasClosure         // does this method contain a closure
  JsExpr? ctorChain       // ctorChain if has one
  JsBlock? code           // method body if has one
}

**************************************************************************
** JsMethodParam
**************************************************************************

**
** JsMethodParam
**
class JsMethodParam : JsNode
{
  new make(JsCompilerSupport s, CParam p) : super(s)
  {
    this.name = vnameToJs(p.name)
    this.paramType = JsTypeRef(s, p.paramType)
    this.hasDef = p.hasDefault
    if (hasDef) this.defVal = JsExpr.makeFor(s, p->def)
  }

  new makeThis(JsCompilerSupport s) : super.make(s)
  {
    this.name = "this"
  }

  new makeSelf(JsCompilerSupport s) : super.make(s)
  {
    this.name = "self"
  }

  override Void write(JsWriter out)
  {
    out.w(name)
  }

  Str name              // param name
  JsTypeRef? paramType  // param type
  Bool hasDef           // has default value
  JsNode? defVal        // default value
}

**************************************************************************
** ClosureFinder
**************************************************************************

internal class ClosureFinder : Visitor
{
  new make(Node node) { this.node = node }
  Bool exists()
  {
    node->walk(this, VisitDepth.expr)
    return found
  }
  override Expr visitExpr(Expr expr)
  {
    if (expr is ClosureExpr) found = true
    return Visitor.super.visitExpr(expr)
  }
  Node node
  Bool found := false
}