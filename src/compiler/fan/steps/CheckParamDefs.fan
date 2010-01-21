//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jun 06  Brian Frank  Creation
//    1 Oct 06  Brian Frank  Port from Java to Fan
//

**
** CheckParamDefs is used to process all the parameter default
** expressions for all the methods.  What we are looking for is
** default expressions which use default expressions before it
** which require us to insert a store instruction.
**
class CheckParamDefs : CompilerStep
{

  new make(Compiler compiler)
    : super(compiler)
  {
  }

  override Void run()
  {
    walk(compiler, VisitDepth.slotDef)
  }

  override Void visitMethodDef(MethodDef m)
  {
    // unless there are two or more defaults don't bother
    params := m.paramDefs
    num := params.size
    if (num <= 1 || params[-2].def == null)
      return

    // if a def expr calculates a local used after it,
    // then we need to insert a store (local set)
    (num-1).times |Int i|
    {
      if (params[i].def == null) return
      if (usedInSuccDef(params, i))
      {
        param := params[i]
        var   := m.vars[i]
        loc   := param.loc

        if (!param.name.equals(var.name)) throw err("invalid state", loc)

        param.def = BinaryExpr.makeAssign(LocalVarExpr(loc, var), param.def, true)
      }
    }
  }

  Bool usedInSuccDef(ParamDef[] params, Int index)
  {
    this.name = params[index].name
    for (i:=index+1; i<params.size; ++i)
    {
      this.used = false
      params[i].def.walk(this)
      if (this.used) return true
    }
    return false
  }

  override Expr visitExpr(Expr expr)
  {
    if (expr.id === ExprId.localVar)
    {
      local := (LocalVarExpr)expr
      if (name == local.var.name) used = true
    }
    return expr
  }

  Str? name
  Bool used

}