//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsBlock
**
** TODO FIXIT - TEMP TILL WE REFACTOR THIS CODE!!!!
**
class JsBlock : JsNode
{
  new make(CompilerSupport support, Node n) : super(support)
  {
    this.x = n
  }

  override Void write(JsWriter out)
  {
    this.out = out
    block(x)
  }

//////////////////////////////////////////////////////////////////////////
// Block
//////////////////////////////////////////////////////////////////////////

  Void block(Block block, Bool braces := false, Bool indent := true)
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
      default: support.err("Unknown StmtId: $stmt.id", stmt.location)
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
// TODO
//    if (inStaticInit) return
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
    block(fs.trueBlock, true)
    if (fs.falseBlock != null)
    {
      out.w("else").nl
      block(fs.falseBlock, true)
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
    block(fs.block, true)
  }

  Void whileStmt(WhileStmt ws)
  {
    out.w("while (")
    expr(ws.condition)
    out.w(")").nl
    block(ws.block, true)
  }

  Void tryStmt(TryStmt ts)
  {
    out.w("try").nl
    block(ts.block, true)
    // TODO
    //ts.catches.each |Catch c|
c := ts.catches.first
if (c != null)
    {
      errVar := c.errVariable ?: "err"
      out.w("catch ($errVar)").nl
      out.w("{").nl
      out.w("  $errVar = fan.sys.Err.make($errVar);").nl
      block(c.block, false)
      out.w("}").nl
    }
    if (ts.catches.size == 0 && ts.finallyBlock == null)
    {
      // TODO - is this right?
      out.w("catch (err) {}").nl
    }
    if (ts.finallyBlock != null)
    {
      out.w("finally").nl
      block(ts.finallyBlock, true)
    }
  }

  Void switchStmt(SwitchStmt ss)
  {
    var := unique
    out.w("var $var = "); expr(ss.condition); out.w(";").nl
    ss.cases.each |c,ia|
    {
      if (ia > 0) out.w("else ")
      out.w("if (")
      c.cases.each |e,ib|
      {
        if (ib > 0) out.w(" || ")
        out.w("fan.sys.Obj.equals($var,"); expr(e); out.w(")")
      }
      out.w(")").nl
      if (c.block != null) block(c.block, true)
      else out.w("{").nl.w("}").nl  // TODO - is this right??
    }
    if (ss.defaultBlock != null)
    {
      if (ss.cases.size > 0)
      {
        out.w("else").nl
        block(ss.defaultBlock, true)
      }
      else block(ss.defaultBlock, false, false)
    }
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
      case ExprId.intLiteral:   intLiteralExpr(ex)
      case ExprId.floatLiteral: out.w("fan.sys.Float.make($ex)")
      case ExprId.decimalLiteral: out.w("fan.sys.Decimal.make($ex)")
      case ExprId.strLiteral:   out.w("\"").w(ex->val.toStr.toCode('\"', true)[1..-2]).w("\"")
      case ExprId.durationLiteral: out.w("fan.sys.Duration.fromStr(\"").w(ex).w("\")")
      case ExprId.uriLiteral:   out.w("fan.sys.Uri.fromStr(").w(ex->val.toStr.toCode('\"', true)).w(")")
      case ExprId.typeLiteral:  out.w("fan.sys.Type.find(\"${ex->val->signature}\")")
      case ExprId.slotLiteral:  out.w("fan.sys.Type.find(\"${ex->parent->signature}\").slot(\"${ex->name}\")")
      case ExprId.symbolLiteral: out.w("fan.sys.Symbol.find(\"${ex->symbol->qname}\")")
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
      case ExprId.localVar:     out.w(vnameToJs(ex.toStr))
      case ExprId.thisExpr:     out.w(inClosure ? "\$this" : "this")
      case ExprId.superExpr:    out.w("this.\$super")
      case ExprId.itExpr:       out.w("it")
      case ExprId.staticTarget: out.w(qnameToJs(ex->ctype))
      //case ExprId.unknownVar
      //case ExprId.storage
      case ExprId.ternary:
        out.w("(("); expr(ex->condition); out.w(") ? ")
        out.w("("); expr(ex->trueExpr);  out.w(") : ")
        out.w("("); expr(ex->falseExpr); out.w("))")
      //case ExprId.curry
      //case ExprId.complexLiteral
      case ExprId.closure:      closureExpr(ex)
      default: support.err("Unknown ExprId: $ex.id", ex.location)
    }
  }

  Void intLiteralExpr(LiteralExpr le)
  {
    val := le.val as Int
    if (val.abs > maxInt || val == Int.minVal)
    {
      hi := (val >> 32) & 0xffff_ffff
      lo := val & 0xffff_ffff
      out.w("new Long(0x$hi.toHex,0x$lo.toHex)")
    }
    else out.w(val)
  }

  Void rangeLiteralExpr(RangeLiteralExpr re)
  {
    out.w("fan.sys.Range.make(")
    expr(re.start)
    out.w(",")
    expr(re.end)
    if (re.exclusive) out.w(",true")
    out.w(")")
  }

  Void listLiteralExpr(ListLiteralExpr le)
  {
    t := le.explicitType != null ? le.explicitType.v.qname : Obj#.qname
    out.w("fan.sys.List.make(fan.sys.Type.find(\"$t\"), [")
    le.vals.each |Expr ex, Int i|
    {
      if (i > 0) out.w(",")
      expr(ex)
    }
    out.w("])")
  }

  Void mapLiteralExpr(MapLiteralExpr me)
  {
    out.w("fan.sys.Map.fromLiteral([")
    me.keys.each |Expr key, Int i| { if (i > 0) out.w(","); expr(key) }
    out.w("],[")
    me.vals.each |Expr val, Int i| { if (i > 0) out.w(","); expr(val) }
    out.w("]")
    if (me.explicitType != null)
    {
      out.w(",fan.sys.Type.find(\"").w(me.explicitType.k).w("\")")
      out.w(",fan.sys.Type.find(\"").w(me.explicitType.v).w("\")")
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
    out.w("fan.sys.Obj.$method(")
    expr(te.target)
    out.w(",fan.sys.Type.find(\"$te.check\"))")
  }

  Void callExpr(CallExpr ce, Bool doSafe := true)
  {
    // skip mock methods used to insert implicit runtime checks
    if (ce.method is MockMethod) return

    if (ce.isSafe && doSafe)
    {
      out.w("((")
      expr(ce.target)
      out.w(" == null) ? null : (")
      callExpr(ce, false)
      out.w("))")
      return
    }

    // check for special cases
    if (isObjMethod(ce.method.name))
    {
      firstArg := true
      if (ce is ShortcutExpr && ce->opToken.toStr == "!=") out.w("!")
      if (ce.target is SuperExpr)
      {
        base := ce.target->explicitType ?: ce.target.ctype
        out.w(qnameToJs(base)).w(".prototype.${ce.method.name}.call(this,")
        firstArg = false
      }
      else
      {
        out.w("fan.sys.Obj.${vnameToJs(ce.method.name)}(")
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
          ce.target is TypeCheckExpr ||
          ce.target is ItExpr)
      {
        ctype := ce.target.ctype
        route := false
        if (ce.target is TypeCheckExpr) ctype = ce.target->check
        if (ctype.isList)      { out.w("fan.sys.List.${vnameToJs(ce.name)}("); route=true }
        else if (ctype.isFunc) { out.w("fan.sys.Func.${vnameToJs(ce.name)}("); route=true }
        else if (isPrimitive(ctype.toStr))
        {
          mname := ce.name
          if (ce.method.isCtor || mname == "<ctor>")
          {
            if (mname == "<ctor>") mname = "make"
            first := ce.method.params.first
            if (ce.args.size == 1 && first?.paramType?.qname == "sys::Str")
              mname = "fromStr"
          }
          out.w("${qnameToJs(ctype)}.${vnameToJs(mname)}(")
          route = true
        }
        i := 0
        if (!route)
        {
          expr(ce.target)
          out.w(".${vnameToJs(ce.name)}(")
        }
        else if (!ce.method.isStatic)
        {
          expr(ce.target)
          if (ce.args.size > 0) i++
        }
        ce.args.each |arg| { if (i++ > 0) out.w(","); expr(arg) }
        out.w(")")
        return
      }
      else if (ce.target.ctype.qname == "sys::Err" && ce.method.name == "trace")
      {
        out.w("fan.sys.Err.trace(")
        expr(ce.target)
        out.w(")")
        return
      }
      if (ce.target is SuperExpr)
      {
        base := ce.target->explicitType ?: ce.target.ctype
        out.w(qnameToJs(base)).w(".prototype")
      }
      else
      {
        expr(ce.target)
      }
    }
    else if (ce.method.isStatic || ce.method.isCtor)
    {
      out.w(qnameToJs(ce.method.parent))
    }
    Str? mname := vnameToJs(ce.name)
    if (ce.method.isCtor || ce.name == "<ctor>")
    {
      mname = ce.name == "<ctor>" ? "make" : ce.name
      if (ce.target is SuperExpr) mname = "$mname\$"
      first := ce.method.params.first
      if (ce.args.size == 1 && first?.paramType?.qname == "sys::Str")
      {
        parent  := ce.method.parent
        fromStr := parent.methods.find |m| { m.parent.qname == parent.qname && m.name == "fromStr" }
        if (fromStr != null) mname = "fromStr"
      }
    }
    else if (ce.target != null)
    {
      // TODO - not sure we need this, or if its right...
      if (ce.target.ctype.qname == "sys::Func" && Regex("call\\d").matches(mname))
        mname = null
    }
    if (ce.isDynamic)
    {
      out.w(".trap('$mname',fan.sys.List.make(fan.sys.Type.find('sys::Obj'),[")
      ce.args.each |arg,i|
      {
        if (i > 0) out.w(",")
        expr(arg)
      }
      out.w("]))")
      return
    }
    if (mname != null) out.w(".").w(mname)
    i := 0
    if (ce.target is SuperExpr)
    {
      out.w(".call(this")
      i++
    }
    else out.w("(")
    ce.args.each |arg|
    {
      if (i++ > 0) out.w(", ")
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
          case ShortcutOp.plus:   op = "plus"
          case ShortcutOp.minus:  op = "minus"
          case ShortcutOp.mult:   op = "mult"
          case ShortcutOp.div:    op = "div"
          case ShortcutOp.mod:    op = "mod"
          case ShortcutOp.and:    op = "and"
          case ShortcutOp.or:     op = "or"
          case ShortcutOp.lshift: op = "shl"
          case ShortcutOp.rshift: op = "shr"
        }
        if (op != null)
        {
          if (se.isAssign) { expr(lhs); out.w(" = ") }
          if (se.opToken == Token.notEq) out.w("!")
          out.w("fan.sys.Int.$op(")
          expr(lhs)
          out.w(",")
          expr(rhs)
          out.w(")")
          return
        }
      }
      if (se.target.ctype?.qname == "sys::Float")
      {
        if (se.op == ShortcutOp.eq)
        {
          if (se.opToken == Token.notEq) out.w("!")
          out.w("fan.sys.Float.equals(")
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
    if (fe.target?.ctype?.isList == true)
    {
      if (fe.name == "size" && get)
      {
        expr(fe.target)
        out.w(".length")
      }
      else
      {
        out.w("fan.sys.List.${vnameToJs(fe.name)}(")
        expr(fe.target)
        out.w(get ? ")" : ",")
      }
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
      out.w(qnameToJs(fe.field.parent)).w(".")
    }
    if (!cvar && !fe.useAccessor) out.w("m_")
    out.w(vnameToJs(name))
    if (!cvar && fe.useAccessor) out.w(get ? "()" : "\$")
  }

  Void closureExpr(ClosureExpr ce)
  {
    closureLevel++
    out.w("fan.sys.Func.make(function(")
    ce.doCall.vars.each |MethodVar v, Int i|
    {
      if (!v.isParam) return
      if (i > 0) out.w(",")
      out.w(vnameToJs(v.name))
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
      out.w("new fan.sys.Param(\"$p.name\",\"$p.paramType.qname\",$p.hasDefault)")
    }
    out.w("],fan.sys.Type.find(\"$ce.doCall.ret.qname\"))")
    closureLevel--
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  const Int maxInt := 9007199254740992  // max exact int in js (2^53)

  Int closureLevel := 0

  **
  ** Return true if we are inside a closure.
  **
  Bool inClosure()
  {
    return closureLevel > 0
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
    "sys::Num":      true,
    "sys::Num?":     true,
    "sys::Str":      true,
    "sys::Str?":     true,
  ]

  Bool isObjMethod(Str methodName) { return objMethodMap.get(methodName, false) }
  const Str:Bool objMethodMap :=
  [
    "equals":      true,
    "compare":     true,
    "isImmutable": true,
    "toImmutable": true,
    "toStr":       true,
    "type":        true,
    "with":        true,
  ]

  Str unique() { return "\$_u${lastId++}" }
  Int lastId := 0

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Node x
  JsWriter? out

}

