//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split out from CodePrinter
//

using build
using compiler
using util

**
** CodePrinter routing for Expr nodes
**
mixin ExprPrinter : CodePrinter
{

  virtual This expr(Expr x)
  {
    m.exprStack.push(x)
    doExpr(x)
    m.exprStack.pop
    return this
  }

  virtual This doExpr(Expr x)
  {
    switch (x.id)
    {
      // literals
      case ExprId.nullLiteral:     return nullLiteral(x)
      case ExprId.trueLiteral:     return trueLiteral(x)
      case ExprId.falseLiteral:    return falseLiteral(x)
      case ExprId.intLiteral:      return intLiteral(x)
      case ExprId.floatLiteral:    return floatLiteral(x)
      case ExprId.decimalLiteral:  return decimalLiteral(x)
      case ExprId.strLiteral:      return strLiteral(x)
      case ExprId.durationLiteral: return durationLiteral(x)
      case ExprId.uriLiteral:      return uriLiteral(x)
      case ExprId.typeLiteral:     return typeLiteral(x)
      case ExprId.slotLiteral:     return slotLiteral(x)
      case ExprId.rangeLiteral:    return rangeLiteral(x)
      case ExprId.listLiteral:     return listLiteral(x)
      case ExprId.mapLiteral:      return mapLiteral(x)

      // comparison / type checking
      case ExprId.boolNot:         return notExpr(x)
      case ExprId.cmpNull:         return compareNullExpr(x)
      case ExprId.cmpNotNull:      return compareNotNullExpr(x)
      case ExprId.same:            return sameExpr(x)
      case ExprId.notSame:         return notSameExpr(x)
      case ExprId.boolOr:          return orExpr(x)
      case ExprId.boolAnd:         return andExpr(x)
      case ExprId.isExpr:          return isExpr(x)
      case ExprId.isnotExpr:       return isnotExpr(x)
      case ExprId.asExpr:          return asExpr(x)
      case ExprId.elvis:           return elvisExpr(x)
      case ExprId.coerce:          return coerceExpr(x)

      // local var handling
      case ExprId.localVar:        return localExpr(x)
      case ExprId.thisExpr:        return thisExpr(x)
      case ExprId.superExpr:       return superExpr(x)
      case ExprId.itExpr:          return itExpr(x)

      // complicated stuff
      case ExprId.call:            return callExpr(x)
      case ExprId.staticTarget:    return staticTargetExpr(x)
      case ExprId.construction:    return ctorExpr(x)
      case ExprId.shortcut:        return shortcutExpr(x)
      case ExprId.field:           return fieldExpr(x)
      case ExprId.assign:          return assignExpr(x)
      case ExprId.closure:         return closureExpr(x)
      case ExprId.ternary:         return ternaryExpr(x)
      case ExprId.throwExpr:       return throwExpr(x)

      default:                     throw Err("${x.id}: ${x.toStr}")
    }
  }

  // literals

  abstract This nullLiteral(LiteralExpr x)

  abstract This trueLiteral(LiteralExpr x)

  abstract This falseLiteral(LiteralExpr x)

  abstract This intLiteral(LiteralExpr x)

  abstract This floatLiteral(LiteralExpr x)

  abstract This decimalLiteral(LiteralExpr x)

  abstract This strLiteral(LiteralExpr x)

  abstract This durationLiteral(LiteralExpr x)

  abstract This uriLiteral(LiteralExpr x)

  abstract This typeLiteral(LiteralExpr x)

  abstract This slotLiteral(SlotLiteralExpr x)

  abstract This rangeLiteral(RangeLiteralExpr x)

  abstract This listLiteral(ListLiteralExpr x)

  abstract This mapLiteral(MapLiteralExpr x)

  // logic, type checking, comparisons

  abstract This compareExpr(Expr lhs, Token op, Expr rhs)

  abstract This compareNullExpr(UnaryExpr x)

  abstract This compareNotNullExpr(UnaryExpr x)

  abstract This notExpr(UnaryExpr x)

  abstract This elvisExpr(BinaryExpr x)

  abstract This sameExpr(BinaryExpr x)

  abstract This notSameExpr(BinaryExpr x)

  abstract This orExpr(CondExpr x)

  abstract This andExpr(CondExpr x)

  abstract This isExpr(TypeCheckExpr x)

  abstract This isnotExpr(TypeCheckExpr x)

  abstract This asExpr(TypeCheckExpr x)

  abstract This coerceExpr(TypeCheckExpr x)

  // local vars

  abstract This localExpr(LocalVarExpr x)

  abstract This thisExpr(LocalVarExpr x)

  abstract This superExpr(LocalVarExpr x)

  abstract This itExpr(LocalVarExpr x)

  // misc stuff

  abstract This staticTargetExpr(StaticTargetExpr x)

  abstract This fieldExpr(FieldExpr x)

  abstract This closureExpr(ClosureExpr x)

  abstract This ternaryExpr(TernaryExpr x)

  abstract This throwExpr(ThrowExpr x)

  abstract This assignExpr(BinaryExpr x)

//////////////////////////////////////////////////////////////////////////
// Calls
//////////////////////////////////////////////////////////////////////////

  ** Call expression handling
  virtual This callExpr(CallExpr x)
  {
    if (x.isDynamic) return trapExpr(x)

    if (x.isSafe) return safeCallExpr(x)

    if (x.target != null && !x.synthetic)
    {
      if (x.args.size == 0)
      {
        op := unaryOperator(x.method.qname)
        if (op != null) return unaryExpr(op, x.target)
      }

      if (x.args.size == 1)
      {
        op := binaryOperator(x.method.qname)
        if (op != null) return binaryExpr(x.target, op, x.args.first)
      }
    }

    return callMethodExpr(x)
  }

  ** Shortcut special handling for comparison, otherwise route to callExpr
  virtual This shortcutExpr(ShortcutExpr x)
  {
    if (x.isCompare)      return compareExpr(x.target, x.opToken, x.args.first)
    if (x.isPostfixLeave) return postfixLeaveExpr(x)
    if (x.isAssign)       return shortcutAssignExpr(x)
    return callExpr(x)
  }

  ** Write unary expression with optional grouping parens
  virtual This unaryExpr(Str op, Expr operand)
  {
    w("(").w(op).w("(").expr(operand).w("))")
  }

  ** Write binary expression with optional grouping parens
  virtual This binaryExpr(Expr lhs, Str op, Expr rhs)
  {
    w("(").expr(lhs).w(")").sp.w(op).sp.w("(").expr(rhs).w(")")
  }

  ** Write list of cond with operator with optional grouping parens
  virtual This condExpr(Str op, Expr[] operands)
  {
    oparen
    operands.each |x, i|
    {
      if (i > 0) sp.w(op).sp
      expr(x)
    }
    return cparen
  }

  ** Return operator if given method qname maps to unary operator or null
  virtual Str? unaryOperator(Str qname) { null }

  ** Return operator if given method qname maps to binary operator or null
  virtual Str? binaryOperator(Str qname) { null }

  ** Normal call method
  abstract This callMethodExpr(CallExpr x)

  ** Trap call expression handling
  abstract This trapExpr(CallExpr x)

  ** Null safe call expression handling
  abstract This safeCallExpr(CallExpr x)

  ** Constructor call expression
  abstract This ctorExpr(CallExpr x)

  ** Handle special assign+math operators: '+= -= *= /='
  abstract This shortcutAssignExpr(ShortcutExpr x)

  ** Handle postfix ++ or --
  abstract This postfixLeaveExpr(ShortcutExpr x)

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Top expr - if false might need to wrap some exprs in parens
  Bool isTopExpr()
  {
    // if only one expr in stack
    if (m.exprStack.size <= 1) return true

    // if this is a call arg, don't need parens
    peek := m.exprStack[-2]
    call := peek as CallExpr
    if (call != null && call.target !== m.exprStack.last) return true

    // adds for list/map literal
    switch (peek.id)
    {
      case ExprId.listLiteral:
      case ExprId.mapLiteral: return true
    }

    return false
  }

  ** Open paren only if not top expr
  This oparen() { isTopExpr ? this : w("(") }

  ** Close paren only if not top expr
  This cparen() { isTopExpr ? this : w(")") }

}

