//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Dec 08  Andy Frank  Creation
//

using compiler

**
** Generates a Javascript source file from a TypeDef AST.
**
class JavascriptWriter : CompilerSupport
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(Compiler compiler, TypeDef typeDef, OutStream out)
    : super(compiler)
  {
    this.typeDef = typeDef
    this.out = AstWriter(out)
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  Void write()
  {
    //if (!typeDef.qname.contains(r"$"))
    //  typeDef.print(AstWriter())

    // we inline closures directly, so no need to generate
    // anonymous types like we do in Java and .NET
    if (typeDef.isClosure) return
    if (typeDef.qname.contains(r"$Cvars")) return

    name := qname(typeDef)
    base := qname(typeDef.base)
    out.w("var $name = ${base}.extend(").nl
    out.w("{").nl
    out.w("  init: function() {},").nl
    out.indent
    typeDef.methodDefs.each |MethodDef m| { method(m) }
    typeDef.fieldDefs.each |FieldDef f| { field(f) }
    out.unindent
    out.w("});").nl
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Void method(MethodDef m)
  {
    if (m.isStatic) err("Static methods not yet supported: $m.name", m.location)
    if (m.isFieldAccessor) return // getter/setters are defined when field is emitted
    hasCThis = false
    out.w("$m.name: function(")
    m.vars.each |MethodVar v, Int i|
    {
      if (!v.isParam) return
      if (i > 0) out.w(", ")
      out.w(var(v.name))
    }
    out.w(")").nl
    out.w("{").nl
    block(m.code, false)
    out.w("},").nl
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Void field(FieldDef f)
  {
    if (f.isStatic) err("Static fields not yet supported: $f.name", f.location)
    out.w("$f.name: {").nl
    out.w("  get: function() { return this.val },").nl
    out.w("  set: function(val) { this.val = val; },").nl
    out.w("  val: ")
    if (f.init != null) expr(f.init)
    else out.w("null")
    out.w(",").nl
    out.w("},").nl
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  Void block(Block block, Bool braces := true)
  {
    if (braces) out.w("{").nl
    out.indent
    block.stmts.each |Stmt s| { stmt(s) }
    out.unindent
    if (braces) out.w("}").nl
  }

//////////////////////////////////////////////////////////////////////////
// Stmt
//////////////////////////////////////////////////////////////////////////

  Void stmt(Stmt stmt, Bool nl := true)
  {
    switch (stmt.id)
    {
      case StmtId.nop:          return
      case StmtId.expr:         exprStmt(stmt->expr)
      case StmtId.localDef:     out.w("var "); expr(stmt->init); out.w(";"); if (nl) out.nl
      //case StmtId.ifStmt:       return
      case StmtId.returnStmt:   out.w("return;"); if (nl) out.nl
      //case StmtId.throwStmt:    return
      case StmtId.forStmt:      forStmt(stmt)
      //case StmtId.whileStmt:    return
      //case StmtId.breakStmt:    return
      //case StmtId.continueStmt: return
      //case StmtId.tryStmt:      return
      //case StmtId.switchStmt:   return
      default: err("Unknown StmtId: $stmt.id", stmt.location)
    }
  }

  Void exprStmt(Expr ex)
  {
    // use cvar def as hook to create local this ptr
    /*
    if (ex.toStr.startsWith(r"($cvars ="))
    {
      if (!inClosure)
        out.w("var \$this = this;").nl
    }
    else
    {
      expr(ex)
      out.w(";").nl
    }
    */
    if (!ex.toStr.startsWith(r"($cvars ="))
    {
      expr(ex)
      out.w(";").nl
    }
  }

  Void forStmt(ForStmt fs)
  {
    out.w("for (")
    if (fs.init != null) { stmt(fs.init, false); out.w(" ") }
    else out.w("; ")
    if (fs.condition != null) expr(fs.condition)
    out.w("; ")
    if (fs.update != null) expr(fs.update)
    out.w(")").nl
    block(fs.block)
  }

//////////////////////////////////////////////////////////////////////////
// Expr
//////////////////////////////////////////////////////////////////////////

  Void expr(Expr ex)
  {
    switch (ex.id)
    {
      case ExprId.nullLiteral:  out.w("null")
      case ExprId.trueLiteral:  out.w("true")
      case ExprId.falseLiteral: out.w("false")
      case ExprId.intLiteral:   out.w(ex)
      case ExprId.floatLiteral: out.w(ex)
      //case ExprId.decimalLiteral
      case ExprId.strLiteral:   out.w("\"").w(ex.toStr.toCode('\"', true)[3..-4]).w("\"")
      //case ExprId.durationLiteral
      //case ExprId.uriLiteral
      case ExprId.typeLiteral:  out.w("sys_Type.find(\"${ex->val->signature}\")")
      //case ExprId.slotLiteral
      //case ExprId.rangeLiteral
      case ExprId.listLiteral:  listLiteralExpr(ex)
      //case ExprId.mapLiteral
      case ExprId.boolNot:      out.w("!"); expr(ex->operand)
      case ExprId.cmpNull:      expr(ex->operand); out.w(" == null")
      case ExprId.cmpNotNull:   expr(ex->operand); out.w(" != null")
      //case ExprId.elvis
      case ExprId.assign:       expr(ex->lhs); out.w(" = "); expr(ex->rhs)
      case ExprId.same:         expr(ex->lhs); out.w(" === "); expr(ex->rhs)
      //case ExprId.notSame
      case ExprId.boolOr:       condExpr(ex)
      case ExprId.boolAnd:      condExpr(ex)
      case ExprId.isExpr:       typeCheckExpr(ex)
      //case ExprId.isnotExpr
      case ExprId.asExpr:       typeCheckExpr(ex)
      case ExprId.coerce:       expr(ex->target)
      case ExprId.call:         callExpr(ex)
      //case ExprId.construction
      case ExprId.shortcut:     shortcutExpr(ex)
      case ExprId.field:        fieldExpr(ex)
      case ExprId.localVar:     out.w(var(ex.toStr))
      case ExprId.thisExpr:     out.w(inClosure ? "\$this" : "this")
      //case ExprId.superExpr
      case ExprId.staticTarget: out.w(qname(ex->ctype))
      //case ExprId.unknownVar
      //case ExprId.storage
      //case ExprId.ternary
      //case ExprId.withBlock
      //case ExprId.withSub
      //case ExprId.withBase
      //case ExprId.curry
      case ExprId.closure:      closureExpr(ex)
      default: err("Unknown ExprId: $ex.id", ex.location)
    }
  }

  Void listLiteralExpr(ListLiteralExpr le)
  {
    out.w("[")
    le.vals.each |Expr ex, Int i|
    {
      if (i > 0) out.w(",")
      expr(ex)
    }
    out.w("]")
  }

  Void typeCheckExpr(TypeCheckExpr te)
  {
    method := te.id == ExprId.asExpr ? "as" : "is"
    out.w("sys_Obj.$method(")
    expr(te.target)
    out.w(",").w(qname(te.check)).w(")")
  }

  Void callExpr(CallExpr ce)
  {
    // check if we need a $this local var
    if (!hasCThis && ce.args.find(|Expr e->Bool| { return e is ClosureExpr }) != null)
    {
      hasCThis = true
      out.w("var \$this = this;").nl
    }

    // check for special cases
    if (isObjMethod(ce.method.name))
    {
      if (ce is ShortcutExpr && ce->opToken.toStr == "!=") out.w("!")
      out.w("sys_Obj.$ce.method.name(")
      expr(ce.target)
      ce.args.each |Expr arg| { out.w(", "); expr(arg) }
      out.w(")")
      if (ce is ShortcutExpr && ce->op === ShortcutOp.cmp && ce->opToken.toStr != "<=>")
        out.w(" ${ce->opToken} 0")
      return
    }

    // normal case
    if (ce.target != null)
    {
      if (isPrimitive(ce.target.ctype.toStr) || ce.target is TypeCheckExpr)
      {
        ctype := ce.target.ctype
        if (ce.target is TypeCheckExpr) ctype = ce.target->check
        out.w("${qname(ctype)}.$ce.name(")
        if (!ce.method.isStatic)
        {
          expr(ce.target)
          if (ce.args.size > 0) out.w(",")
        }
        ce.args.each |Expr arg, Int i| { if (i > 0) out.w(","); expr(arg) }
        out.w(")")
        return
      }
      expr(ce.target)
      out.w(".")
    }
    else if (ce.method != null && (ce.method.isStatic || ce.method.isCtor))
    {
      out.w("<$ce.method.parent.qname>").w(".")
    }
    out.w(ce.name).w("(")
    ce.args.each |Expr arg, Int i|
    {
      if (i > 0) out.w(", ")
      expr(arg)
    }
    out.w(")")
  }

  Void shortcutExpr(ShortcutExpr se)
  {
    // try to optimize the primitive case
    if (isPrimitive(se.target.ctype?.qname) && se.method.name != "compare")
    {
      lhs := se.target
      rhs := se.args.first
      if (se.op == ShortcutOp.increment)
      {
        if (se.isPostfixLeave) { expr(lhs); out.w("++") }
        else { out.w("++"); expr(lhs) }
        return
      }
      if (se.op == ShortcutOp.decrement)
      {
        if (se.isPostfixLeave) { expr(lhs); out.w("--") }
        else { out.w("--"); expr(lhs) }
        return
      }
      if (se.op.degree == 1) { out.w(se.opToken); expr(lhs); return }
      if (se.op.degree == 2) { expr(lhs); out.w(" $se.opToken "); expr(rhs); return }
    }

    // check for list access
    if (se.op == ShortcutOp.get || se.op == ShortcutOp.set)
    {
      expr(se.target)
      out.w("[$se.args.first]")
      return
    }

    // fallback to call as method
    callExpr(se)
  }

  Void condExpr(CondExpr ce)
  {
    ce.operands.each |Expr op, Int i|
    {
      if (i > 0 && i<ce.operands.size) out.w(" $ce.opToken ")
      expr(op)
    }
  }

  Void fieldExpr(FieldExpr fe)
  {
    cvar := fe.target?.toStr == r"$cvars"
    name := fe.name
    if (fe.target != null && !cvar)
    {
      expr(fe.target)
      if (name == r"$this") return // skip $this ref for closures
      out.w(".")
    }
    if (cvar)
    {
      if (name[0] == '$') name = name[1..-1]
      else { i := name.index(r"$"); if (i != null) name = name[0...i] }
    }
    out.w(name)
    if (!cvar && !fe.useAccessor) out.w(".val")
  }

  Void closureExpr(ClosureExpr ce)
  {
    inClosure = true
    out.w("function(")
    ce.doCall.vars.each |MethodVar v, Int i|
    {
      if (!v.isParam) return
      if (i > 0) out.w(", ")
      out.w(var(v.name))
    }
    out.w(") {")
    if (ce.doCall?.code != null)
    {
      out.nl
      block(ce.doCall.code, false)
    }
    out.w("}")
    inClosure = false
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the Javascript qname for this TypeDef.
  ** The Javascript qname is <pod>_<type>:
  **
  **   foo::Bar  ->  foo_Bar
  **
  Str qname(CType ctype)
  {
    return ctype.pod.name + "_" + ctype.name
  }

  Bool isPrimitive(Str qname) { return primitiveMap.get(qname, false) }
  const Str:Bool primitiveMap :=
  [
    "sys::Bool":   true,
    "sys::Bool?":  true,
    "sys::Float":  true,
    "sys::Float?": true,
    "sys::Int":    true,
    "sys::Int?":   true,
    "sys::Str":    true,
    "sys::Str?":   true,
  ]

  Bool isObjMethod(Str methodName) { return objMethodMap.get(methodName, false) }
  const Str:Bool objMethodMap :=
  [
    "equals":      true,
    "compare":     true,
    "isImmutable": true,
    "type":        true,
  ]

  Str var(Str name)
  {
    if (vars.get(name, false)) return "\$$name";
    return name;
  }
  const Str:Bool vars :=
  [
    "char": true,
    "var":  true
  ]

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  TypeDef typeDef
  AstWriter out
  Bool inClosure := false
  Bool hasCThis  := false

}