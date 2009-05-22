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
    if (typeDef.qname.contains("\$Cvars")) return

    fname := typeDef.qname
    bname := typeDef.base ?: "sys::Obj"
    jname := qname(typeDef)
    jbase := qname(typeDef.base)
    out.w("var $jname = sys_Obj.\$extend($jbase);").nl
// TODO - this is ok for now - it fails because of
// how we trap curried types, which should be rare
// to have type called on them - but we need to fix
// none-the-less
if (!typeDef.name.startsWith("Curry\$"))
{
  out.w("${jname}.\$type = sys_Type.find(\"$fname\");").nl
}
    out.w("${jname}.prototype.\$ctor = function() {")
    // look for natives
    hasNative := typeDef.slots.any |s| { s.isNative && s.parent.qname == typeDef.qname }
    if (hasNative) out.w(" this.peer = new ${nativeQname(typeDef)}(this); ")
    out.w("}").nl
    out.w("${jname}.prototype.type = function() { return ${jname}.\$type; }").nl
    typeDef.methodDefs.each |m| { method(m) }
    typeDef.fieldDefs.each  |f| { field(f) }
    ctors.each |MethodDef m| { ctor(m) }
    staticMethods.each |MethodDef m| { staticMethod(m) }
    staticFields.each |FieldDef f| { staticField(f) }
    staticInits.each |Block b| { staticInit(b) }
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Void method(MethodDef m)
  {
    if (m.isStatic) { staticMethods.add(m); return }
    if (m.isFieldAccessor) return // getter/setters are defined when field is emitted
    mname := var(m.name)
    if (m.isCtor) { ctors.add(m); mname = "\$$mname" }
    out.w("${qname(m.parent)}.prototype.${mname} = ")
    doMethod(m)
    out.nl
  }

  Void ctor(MethodDef m)
  {
    if (!m.isCtor) err("Method must be a ctor: $m.name", m.location)
    out.w("${qname(m.parent)}.$m.name = function")
    doMethodSig(m)
    out.nl
    out.w("{").nl
    out.w("  var instance = new ${qname(m.parent)}();").nl
    out.w("  instance.\$$m.name"); doMethodSig(m); out.w(";").nl
    out.w("  return instance;").nl
    out.w("}").nl
  }

  Void staticMethod(MethodDef m)
  {
    if (!m.isStatic) err("Method must be static: $m.name", m.location)
    if (m.name == "static\$init") { staticInits.add(m.code); return }
    out.w("${qname(m.parent)}.${var(m.name)} = ")
    doMethod(m)
    out.nl
  }

  private Void doMethod(MethodDef m)
  {
    out.w("function"); doMethodSig(m); out.nl
    out.w("{").nl
    if (m.params.find |p| { p.hasDefault } != null)
    {
      m.params.each |p,i|
      {
        if (!p.hasDefault) return
        out.w("  if ($p.name == undefined) $p.name = ")
        expr(p->def)
        out.w(";").nl
      }
    }
    if (m.ctorChain != null)
    {
      out.w("  ")
      callExpr(m.ctorChain)
      out.w(";").nl
    }
    if (m.isNative)
    {
      ret := m.ret.qname == "sys::Void" ? "" : "return "
      if (m.isStatic)
        out.w("  ${ret}${nativeQname(typeDef)}.$m.name")
      else
        out.w("  ${ret}this.peer.${m.name}")
      doMethodSig(m, true)
      out.w(";").nl
    }
    else if (m.code != null)
    {
      if (ClosureFinder(m).exists)
        out.w("  var \$this = this;").nl
      block(m.code, false)
    }
    out.w("}")
  }

  private Void doMethodSig(MethodDef m, Bool passThis := false)
  {
    i := 0
    out.w("(")
    if (passThis) { out.w("this"); i++ }
    m.vars.each |MethodVar v|
    {
      if (!v.isParam) return
      if (i++ > 0) out.w(", ")
      out.w(var(v.name))
    }
    out.w(")")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Void field(FieldDef f)
  {
    if (f.isNative) return
    if (f.isStatic) { staticFields.add(f); return }
    doField(f)
  }

  Void staticField(FieldDef f)
  {
    if (f.isNative) return
    if (!f.isStatic) err("Field must be static: $f.name", f.location)
    doField(f)
  }

  Void doField(FieldDef f)
  {
    qname  := qname(f.parent)
    prefix := f.isStatic ? qname : "${qname}.prototype"
    def    := "null"
    switch (f.fieldType.qname)
    {
      case "sys::Bool":    def = "false"
      case "sys::Decimal": // fall
      case "sys::Float":   def = "0"
      case "sys::Int":     def = "sys_Int.make(0)"
    }

    // getter
    out.w("${prefix}.${var(f.name)}\$get = function() ")
    if (f.hasGet) block(f.get.code)
    else out.w("{ return this.${var(f.name)}; }").nl

    // setter
    out.w("${prefix}.${var(f.name)}\$set = function(val) ")
    if (f.hasSet) block(f.set.code)
    else out.w("{ this.${var(f.name)} = val; }").nl

    // storage
    out.w("${prefix}.${var(f.name)} = $def;").nl
  }

//////////////////////////////////////////////////////////////////////////
// Static Init
//////////////////////////////////////////////////////////////////////////

  Void staticInit(Block code)
  {
    inStaticInit = true
    block(code, false, false)
    inStaticInit = false
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  Void block(Block block, Bool braces := true, Bool indent := true)
  {
    if (braces) out.w("{").nl
    if (indent) out.indent
    block.stmts.each |Stmt s| { stmt(s) }
    if (indent) out.unindent
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
      case StmtId.localDef:     localDef(stmt); if (nl) out.nl
      case StmtId.ifStmt:       ifStmt(stmt)
      case StmtId.returnStmt:   returnStmt(stmt); if (nl) out.nl
      case StmtId.throwStmt:    throwStmt(stmt); if(nl) out.nl
      case StmtId.forStmt:      forStmt(stmt)
      case StmtId.whileStmt:    whileStmt(stmt)
      case StmtId.breakStmt:    out.w("break;"); if (nl) out.nl
      case StmtId.continueStmt: out.w("continue;"); if (nl) out.nl
      case StmtId.tryStmt:      tryStmt(stmt)
      case StmtId.switchStmt:   switchStmt(stmt)
      default: err("Unknown StmtId: $stmt.id", stmt.location)
    }
  }

  Void exprStmt(Expr ex)
  {
    if (!ex.toStr.startsWith("(\$cvars ="))
    {
      expr(ex)
      out.w(";").nl
    }
  }

  Void localDef(LocalDefStmt lds)
  {
    out.w("var ")
    if (lds.init == null) out.w(lds.name)
    else expr(lds.init)
    out.w(";")
  }

  Void returnStmt(ReturnStmt rs)
  {
    if (inStaticInit) return
    out.w("return")
    if (rs.expr != null) { out.w(" "); expr(rs.expr) }
    out.w(";")
  }

  Void throwStmt(ThrowStmt ts)
  {
    out.w("throw ")
    expr(ts.exception)
    out.w(";")
  }

  Void ifStmt(IfStmt fs)
  {
    out.w("if ("); expr(fs.condition); out.w(")").nl
    block(fs.trueBlock)
    if (fs.falseBlock != null)
    {
      out.w("else").nl
      block(fs.falseBlock)
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

  Void whileStmt(WhileStmt ws)
  {
    out.w("while (")
    expr(ws.condition)
    out.w(")").nl
    block(ws.block)
  }

  Void tryStmt(TryStmt ts)
  {
    out.w("try").nl
    block(ts.block)
    // TODO
    //ts.catches.each |Catch c|
c := ts.catches.first
if (c != null)
    {
      errVar := c.errVariable ?: "err"
      out.w("catch ($errVar)").nl
      block(c.block)
    }
    if (ts.catches.size == 0) out.w("catch (err) {}").nl
  }

  Void switchStmt(SwitchStmt ss)
  {
    out.w("switch ("); expr(ss.condition); out.w(")").nl
    out.w("{").nl
    out.indent
    ss.cases.each |Case c|
    {
      c.cases.each |Expr e| { out.w("case "); expr(e); out.w(":").nl }
      if (c.block != null)
      {
        block(c.block, false, true)
        out.w("  break;").nl
      }
    }
    if (ss.defaultBlock != null)
    {
      out.w("default:").nl
      block(ss.defaultBlock, false, true)
    }
    out.unindent
    out.w("}").nl
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
      case ExprId.intLiteral:   out.w("sys_Int.make($ex)")
      case ExprId.floatLiteral: out.w(ex)
      case ExprId.decimalLiteral: out.w(ex)
      case ExprId.strLiteral:   out.w("\"").w(ex->val.toStr.toCode('\"', true)[1..-2]).w("\"")
      case ExprId.durationLiteral: out.w("sys_Duration.fromStr(\"").w(ex).w("\")")
      case ExprId.uriLiteral:   out.w("sys_Uri.fromStr(").w(ex->val.toStr.toCode('\"', true)).w(")")
      case ExprId.typeLiteral:  out.w("sys_Type.find(\"${ex->val->signature}\")")
      case ExprId.slotLiteral:  out.w("sys_Type.find(\"${ex->parent->signature}\").slot(\"${ex->name}\")")
      case ExprId.rangeLiteral: rangeLiteralExpr(ex)
      case ExprId.listLiteral:  listLiteralExpr(ex)
      case ExprId.mapLiteral:   mapLiteralExpr(ex)
      case ExprId.boolNot:      out.w("!"); expr(ex->operand)
      case ExprId.cmpNull:      expr(ex->operand); out.w(" == null")
      case ExprId.cmpNotNull:   expr(ex->operand); out.w(" != null")
      case ExprId.elvis:        elvisExpr(ex)
      case ExprId.assign:       assignExpr(ex)
      case ExprId.same:         expr(ex->lhs); out.w(" === "); expr(ex->rhs)
      case ExprId.notSame:      out.w("!("); expr(ex->lhs); out.w(" === "); expr(ex->rhs); out.w(")")
      case ExprId.boolOr:       condExpr(ex)
      case ExprId.boolAnd:      condExpr(ex)
      case ExprId.isExpr:       typeCheckExpr(ex)
      case ExprId.isnotExpr:    out.w("!"); typeCheckExpr(ex)
      case ExprId.asExpr:       typeCheckExpr(ex)
      case ExprId.coerce:       expr(ex->target)
      case ExprId.call:         callExpr(ex)
      case ExprId.construction: callExpr(ex)
      case ExprId.shortcut:     shortcutExpr(ex)
      case ExprId.field:        fieldExpr(ex)
      case ExprId.localVar:     out.w(var(ex.toStr))
      case ExprId.thisExpr:     out.w(inClosure ? "\$this" : "this")
      case ExprId.superExpr:    out.w("this.\$super")
      case ExprId.itExpr:       out.w("it")
      case ExprId.staticTarget: out.w(qname(ex->ctype))
      //case ExprId.unknownVar
      //case ExprId.storage
      case ExprId.ternary:      expr(ex->condition); out.w(" ? "); expr(ex->trueExpr); out.w(" : "); expr(ex->falseExpr)
      //case ExprId.curry
      //case ExprId.complexLiteral
      case ExprId.closure:      closureExpr(ex)
      default: err("Unknown ExprId: $ex.id", ex.location)
    }
  }

  Void rangeLiteralExpr(RangeLiteralExpr re)
  {
    out.w("sys_Range.make(")
    expr(re.start)
    out.w(",")
    expr(re.end)
    if (re.exclusive) out.w(",true")
    out.w(")")
  }

  Void listLiteralExpr(ListLiteralExpr le)
  {
    t := le.explicitType != null ? le.explicitType.v.qname : Obj#.qname
    out.w("sys_List.make(sys_Type.find(\"$t\"), [")
    le.vals.each |Expr ex, Int i|
    {
      if (i > 0) out.w(",")
      expr(ex)
    }
    out.w("])")
  }

  Void mapLiteralExpr(MapLiteralExpr me)
  {
    out.w("sys_Map.fromLiteral([")
    me.keys.each |Expr key, Int i| { if (i > 0) out.w(","); expr(key) }
    out.w("],[")
    me.vals.each |Expr val, Int i| { if (i > 0) out.w(","); expr(val) }
    out.w("]")
    if (me.explicitType != null)
    {
      out.w(",sys_Type.find(\"").w(me.explicitType.k).w("\")")
      out.w(",sys_Type.find(\"").w(me.explicitType.v).w("\")")
    }
    out.w(")")
  }

  Void elvisExpr(BinaryExpr be)
  {
    out.w("("); expr(be.lhs); out.w(" != null)")
    out.w(" ? ("); expr(be.lhs); out.w(")")
    out.w(" : ("); expr(be.rhs); out.w(")")
  }

  Void assignExpr(BinaryExpr be)
  {
    if (be.lhs is FieldExpr)
    {
      fe := be.lhs as FieldExpr
      if (fe.useAccessor) { fieldExpr(fe,false); out.w("("); expr(be.rhs); out.w(")") }
      else { fieldExpr(fe); out.w(" = "); expr(be.rhs); }
    }
    else { expr(be.lhs); out.w(" = "); expr(be.rhs) }
  }

  Void typeCheckExpr(TypeCheckExpr te)
  {
    method := te.id == ExprId.asExpr ? "as" : "is"
    out.w("sys_Obj.$method(")
    expr(te.target)
    out.w(",sys_Type.find(\"$te.check\"))")
  }

  Void callExpr(CallExpr ce)
  {
    // check for special cases
    if (isObjMethod(ce.method.name))
    {
      firstArg := true
      if (ce is ShortcutExpr && ce->opToken.toStr == "!=") out.w("!")
      if (ce.target is SuperExpr)
      {
        base := ce.target->explicitType ?: ce.target.ctype
        out.w(qname(base)).w(".prototype.${ce.method.name}.call(this,")
        firstArg = false
      }
      else
      {
        out.w("sys_Obj.$ce.method.name(")
        expr(ce.target)
      }
      ce.args.each |arg, i|
      {
        if (i>0 || firstArg) out.w(", ")
        expr(arg)
      }
      out.w(")")
      if (ce is ShortcutExpr && ce->op === ShortcutOp.cmp && ce->opToken.toStr != "<=>")
        out.w(" ${ce->opToken} 0")
      return
    }

    // normal case
    if (ce.target != null)
    {
      if (isPrimitive(ce.target.ctype.toStr) ||
          ce.target.ctype.isList ||
          ce.target.ctype.isFunc ||
          ce.target is TypeCheckExpr)
      {
        ctype := ce.target.ctype
        if (ce.target is TypeCheckExpr) ctype = ce.target->check
        if (ctype.isList)
          out.w("sys_List.${var(ce.name)}(")
        else if (ctype.isFunc)
          out.w("sys_Func.${var(ce.name)}(")
        else
          out.w("${qname(ctype)}.${var(ce.name)}(")
        if (!ce.method.isStatic)
        {
          expr(ce.target)
          if (ce.args.size > 0) out.w(",")
        }
        ce.args.each |Expr arg, Int i| { if (i > 0) out.w(","); expr(arg) }
        out.w(")")
        return
      }
      else if (ce.target.ctype.qname == "sys::Err" && ce.method.name == "trace")
      {
        out.w("sys_Err.trace(")
        expr(ce.target)
        out.w(")")
        return
      }
      if (ce.target is SuperExpr)
      {
        base := ce.target->explicitType ?: ce.target.ctype
        out.w(qname(base)).w(".prototype")
      }
      else
      {
        expr(ce.target)
      }
    }
    else if (ce.method.isStatic || ce.method.isCtor)
    {
      out.w(qname(ce.method.parent))
    }
    Str? mname := var(ce.name)
    if (ce.method.isCtor || ce.name == "<ctor>")
    {
      mname = ce.name == "<ctor>" ? "make" : ce.name
      if (ce.target is SuperExpr)
      {
        out.w(".\$${mname}.call(this")
        ce.args.each |arg| { out.w(","); expr(arg) }
        out.w(")")
        return
      }
      first := ce.method.params.first
      if (ce.args.size == 1 && first?.paramType?.qname == "sys::Str")
      {
        fromStr := ce.method.parent.methods.find |m| { m.name == "fromStr" }
        if (fromStr != null) mname = "fromStr"
      }
    }
    else if (ce.target != null)
    {
      // TODO - not sure we need this, or if its right...
      if (ce.target.ctype.qname == "sys::Func" && Regex("call\\d").matches(mname))
        mname = null
    }
    if (mname != null) out.w(".").w(mname)
    if (ce.isDynamic && ce.noParens)
    {
      if (ce.args.size == 0) return
      if (ce.args.size == 1)
      {
        out.w(" = ")
        expr(ce.args.first)
        return
      }
      throw ArgErr("Parens required for multiple args")
    }
    out.w("(")
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
    if (isPrimitive(se.target.ctype?.qname) &&
        se.method.name != "compare" && se.method.name != "get" && se.method.name != "slice")
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
      if (se.target.ctype?.qname == "sys::Int")
      {
        Str? op := null
        switch (se.op)
        {
          case ShortcutOp.eq:  op = "equals"
          case ShortcutOp.and: op = "and"
          case ShortcutOp.div: op = "div"
          case ShortcutOp.or:  op = "or"
        }
        if (op != null)
        {
          if (se.isAssign) { expr(lhs); out.w(" = ") }
          if (se.opToken == Token.notEq) out.w("!")
          out.w("sys_Int.$op(")
          expr(lhs)
          out.w(",")
          expr(rhs)
          out.w(")")
          return
        }
      }
      if (se.op.degree == 1) { out.w(se.opToken); expr(lhs); return }
      if (se.op.degree == 2)
      {
        out.w("(")
        expr(lhs)
        out.w(" $se.opToken ")
        expr(rhs)
        out.w(")")
        return
      }
    }

    // check for list access
    if (!isPrimitive(se.target.ctype?.qname) &&
        se.op == ShortcutOp.get || se.op == ShortcutOp.set)
    {
      expr(se.target)
      if (!se.args.first.ctype.isInt)
      {
        out.w(se.args.size == 1 ? ".get" : ".set")
        out.w("(")
        expr(se.args.first)
        if (se.args.size > 1) { out.w(","); expr(se.args[1]) }
        out.w(")")
        return
      }
      i := "$se.args.first".toInt(10, false)
      if (i != null && i < 0)
      {
        out.w("[")
        expr(se.target)
        out.w(".length$i]")
      }
      else
      {
        out.w("[")
        expr(se.args.first)
        out.w("]")
      }
      if (se.args.size > 1)
      {
        out.w(" = ")
        expr(se.args[1])
      }
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

  Void fieldExpr(FieldExpr fe, Bool get := true)
  {
    if (fe.target?.ctype?.isList == true && fe.name == "size")
    {
      expr(fe.target)
      out.w(".length")
      return
    }
    cvar := fe.target?.toStr == "\$cvars"
    name := fe.name
    if (fe.target != null && !cvar)
    {
      expr(fe.target)
      if (name == "\$this") return // skip $this ref for closures
      out.w(".")
    }
    if (cvar)
    {
      if (name[0] == '$') name = name[1..-1]
      else { i := name.index("\$"); if (i != null) name = name[0..<i] }
    }
    if (fe.target == null && fe.field.isStatic)
    {
      out.w(qname(fe.field.parent)).w(".")
    }
    out.w(var(name))
    if (!cvar && fe.useAccessor) out.w(get ? "\$get()" : "\$set")
  }

  Void closureExpr(ClosureExpr ce)
  {
    closureLevel++
    out.w("sys_Func.make(function(")
    ce.doCall.vars.each |MethodVar v, Int i|
    {
      if (!v.isParam) return
      if (i > 0) out.w(",")
      out.w(var(v.name))
    }
    out.w(") {")
    if (ce.doCall?.code != null)
    {
      out.nl
      block(ce.doCall.code, false)
    }
    out.w("},[")
    ce.doCall.params.each |p,i|
    {
      if(i > 0) out.w(",")
      out.w("new sys_Param(\"$p.name\",\"$p.paramType.qname\",$p.hasDefault)")
    }
    out.w("],sys_Type.find(\"$ce.doCall.ret.qname\"))")
    closureLevel--
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if we are inside a closure.
  **
  Bool inClosure()
  {
    return closureLevel > 0
  }

  **
  ** Return the Javascript qname for this TypeDef.
  ** The Javascript qname is <pod>_<type>:
  **
  **   foo::Bar  ->  foo_Bar
  **
  Str qname(CType ctype)
  {
    refs[ctype.qname] = ctype
    return ctype.pod.name + "_" + ctype.name
  }

  **
  ** Return the native peer qname for this TypeDef.
  **
  Str nativeQname(CType ctype)
  {
    return "${qname(ctype)}Peer"
  }

  Bool isPrimitive(Str qname) { return primitiveMap.get(qname, false) }
  const Str:Bool primitiveMap :=
  [
    "sys::Bool":     true,
    "sys::Bool?":    true,
    "sys::Decimal":  true,
    "sys::Decimal?": true,
    "sys::Float":    true,
    "sys::Float?":   true,
    "sys::Int":      true,
    "sys::Int?":     true,
    "sys::Str":      true,
    "sys::Str?":     true,
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
    "char":   true,
    "delete": true,
    "in":     true,
    "var":    true,
    "with":   true
  ]

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  TypeDef typeDef
  AstWriter out
  Int closureLevel  := 0            // closure level, 0=no closure
  Bool inStaticInit := false
  MethodDef[] ctors := [,]          // ctors
  MethodDef[] staticMethods := [,]  // static methods
  FieldDef[] staticFields := [,]    // static fields
  Block[] staticInits := [,]        // static init blocks
  Str:CType refs := [:]             // types referenced
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