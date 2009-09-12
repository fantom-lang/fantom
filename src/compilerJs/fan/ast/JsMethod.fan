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
  new make(CompilerSupport s, MethodDef m) : super(s, m)
  {
    this.parentPeer = JsType.findPeer(s, m.parent)
    this.isCtor     = m.isCtor
    this.isGetter   = m.isGetter
    this.isSetter   = m.isSetter
    this.params     = m.params.map |CParam p->JsMethodParam| { JsMethodParam(s, p) }
    this.hasClosure = ClosureFinder(m).exists
    if (m.ctorChain != null) this.ctorChain = JsExpr(s, m.ctorChain, false)
    if (m.code != null) this.code = JsBlock(s, m.code, false)
  }

  Bool isFieldAccessor() { isGetter || isSetter }

  override Void write(JsWriter out)
  {
    if (isCtor)
    {
      writeMethod(out,
       "  var instance = new $parent();
          instance.$name\$${sig(params)};
          return instance;
        ")
      name   = "$name\$"
      isCtor = false
    }
    else if (isGetter) name = "$name"
    else if (isSetter) name = "$name\$"
    writeMethod(out)
  }

  Void writeMethod(JsWriter out, Str? alt := null)
  {
    // skip abstract methods
    if (isAbstract) return

    out.w(parent)
    if (!isStatic && !isCtor) out.w(".prototype")
    out.w(".$name = function${sig(params)}").nl
    out.w("{").nl

    // def params
    params.each |p|
    {
      if (!p.hasDef) return
      out.w("  if ($p.name == undefined) $p.name = ")
      p.defVal.write(out)
      out.w(";").nl
    }

    // closure support
    if (hasClosure) out.w("  var \$this = this;").nl

    if (alt != null) out.w(alt)
    else if (isNative)
    {
      if (isStatic)
      {
        out.w("  return ${parentPeer.qname}Peer.$name${sig(params)};").nl
      }
      else
      {
        pars := isStatic ? params : [JsMethodParam.makeThis(support)].addAll(params)
        out.w("  return this.peer.$name${sig(pars)};").nl
      }
    }
    else
    {
      // ctor chaining
      if (ctorChain != null)
      {
        out.w("  ")
        ctorChain.write(out)
        out.w(";").nl
      }

      // method body
      code?.write(out)
    }

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
  new make(CompilerSupport s, CParam p) : super(s)
  {
    this.name = vnameToJs(p.name)
    this.hasDef = p.hasDefault
    if (hasDef) this.defVal = JsExpr(s, p->def, false)
  }

  new makeThis(CompilerSupport s) : super.make(s)
  {
    this.name = "this"
  }

  override Void write(JsWriter out)
  {
    out.w(name)
  }

  Str name        // param name
  Bool hasDef     // has default value
  JsNode? defVal  // default value
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