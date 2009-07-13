//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Dec 05  Brian Frank  Creation
//   30 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** Normalize the abstract syntax tree:
**   - Collapse multiple static new blocks
**   - Init static fields in static new block
**   - Init instance fields in instance new block
**   - Add implicit return in methods
**   - Add implicit super constructor call
**   - Rewrite synthetic getter/setter for override of concrete field
**   - Generate once method boiler plate
**
class Normalize : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("Normalize")
    walk(types, VisitDepth.typeDef)
    bombIfErr
  }

//////////////////////////////////////////////////////////////////////////
// Type Normalization
//////////////////////////////////////////////////////////////////////////

  override Void visitTypeDef(TypeDef t)
  {
    location := t.location
    iInit := Block(location)  // instance init
    sInit := Block(location)  // static init

    // walk thru all the slots
    t.slotDefs.dup.each |SlotDef s|
    {
      if (s is FieldDef)
      {
        f := (FieldDef)s
        normalizeField(f)
        if (f.init != null && !f.isAbstract)
        {
          if (f.isStatic)
            sInit.add(fieldInitStmt(f))
          else
            iInit.add(fieldInitStmt(f))
          f.walkInit = false
        }
      }
      else
      {
        // if a static initializer, append it
        m := (MethodDef)s
        if (m.isStaticInit)
          appendStaticInit(sInit, m)
        else
          normalizeMethod(m, iInit)
      }
    }

    // add instance$init if needed
    if (!iInit.isEmpty)
    {
      iInit.add(ReturnStmt.makeSynthetic(location))
      ii := MethodDef.makeInstanceInit(iInit.location, t, iInit)
      t.addSlot(ii)
      callInstanceInit(t, ii)
    }

    // add static$init if needed
    if (!sInit.isEmpty)
    {
      sInit.add(ReturnStmt.makeSynthetic(location))
      t.normalizeStaticInits(MethodDef.makeStaticInit(sInit.location, t, sInit))
    }
  }

  private Void appendStaticInit(Block sInit, MethodDef m)
  {
    // append inside an "if (true) {}" block so that each static
    // initializer is given its own scope in the unified static initializer;
    // the "if (true)" gets optimized away in CoodeAsm
    loc := m.location
    cond := LiteralExpr(loc, ExprId.trueLiteral, ns.boolType, true)
    ifStmt := IfStmt(loc, cond, m.code)
    sInit.add(ifStmt)
    m.code = null
  }

//////////////////////////////////////////////////////////////////////////
// Method Normalization
//////////////////////////////////////////////////////////////////////////

  private Void normalizeMethod(MethodDef m, Block iInit)
  {
    code := m.code
    if (code == null) return

    // add implicit return
    if (!code.isExit) addImplicitReturn(m)

    // insert super constructor call
    if (m.isCtor) insertSuperCtor(m)

    // once
    if (m.isOnce) normalizeOnce(m, iInit)
  }

  private Void addImplicitReturn(MethodDef m)
  {
    code := m.code
    loc := code.location

    // we allow return keyword to be omitted if there is exactly one statement
    if (code.size == 1 && !m.returnType.isVoid && code.stmts[0].id == StmtId.expr)
    {
      code.stmts[0] = ReturnStmt.makeSynthetic(code.stmts[0].location, code.stmts[0]->expr)
      return
    }

    // return is implied as simple method exit
    code.add(ReturnStmt.makeSynthetic(loc))
  }

  private Void insertSuperCtor(MethodDef m)
  {
    // don't need to insert if one already is defined
    if (m.ctorChain != null) return

    // never insert super call for synthetic types, mixins, or Obj.make
    parent := m.parent
    base := parent.base
    if (parent.isSynthetic) return
    if (parent.isMixin) return
    if (base.isObj) return

    // check if the base class has exactly one available
    // constructor with no parameters
    superCtors := base.ctors
    if (superCtors.size != 1) return
    superCtor := superCtors.first
    if (superCtor.isPrivate) return
    if (superCtor.isInternal && base.pod != parent.pod) return
    if (!superCtor.params.isEmpty) return

    // if we find a ctor to use, then create an implicit super call
    m.ctorChain = CallExpr.makeWithMethod(m.location, SuperExpr(m.location), superCtor)
    m.ctorChain.isCtorChain = true
  }

  private Void normalizeOnce(MethodDef m, Block iInit)
  {
    loc := m.location

    // we'll report these errors in CheckErrors
    if (curType.isConst || curType.isMixin ||
        m.isStatic || m.isCtor || m.isFieldAccessor)
      return

    // error checking
    if (m.ret.isVoid) err("Once method '$m.name' cannot return Void", loc)
    if (!m.params.isEmpty) err("Once method '$m.name' cannot have parameters", loc)

    // generate storage field
    f := FieldDef(loc, curType)
    f.flags     = FConst.Private | FConst.Storage | FConst.Synthetic
    f.name      = m.name + "\$Store"
    f.fieldType = ns.objType.toNullable
    f.init      = LiteralExpr.makeFor(loc, ns, "_once_")
    curType.addSlot(f)
     iInit.add(fieldInitStmt(f))

    // add name$Once with original code
    x := MethodDef(loc, curType)
    x.flags        = FConst.Private | FConst.Synthetic
    x.name         = m.name + "\$Once"
    x.ret          = ns.objType.toNullable
    x.inheritedRet = null
    x.paramDefs    = m.paramDefs
    x.vars         = m.vars
    x.needsCvars   = m.needsCvars
    x.code         = m.code
    curType.addSlot(x)

    // swizzle any closures using that method to the name$Once version
    curType.closures.each |ClosureExpr c|
    {
      if (c.enclosingSlot === m) c.enclosingSlot = x
    }

    // replace original method code with our delegate:
    //   if (name$Store == "_once_")
    //     name$Store = name$Once()
    //   return (RetType)name$Store
    m.code  = Block(loc)

    // if (name$Store == "_once_")
    cond := BinaryExpr(
      f.makeAccessorExpr(loc, false),
      Token.same,
      LiteralExpr.makeFor(loc, ns, "_once_"))

    // name$Store = name$Once()
    trueBlock := Block(loc)
    trueBlock.add(BinaryExpr(
        f.makeAccessorExpr(loc, false),
        Token.assign,
        CallExpr.makeWithMethod(loc, ThisExpr(loc), x)
      ).toStmt)

    ifStmt := IfStmt(loc, cond, trueBlock)
    m.code.add(ifStmt)

    // return (RetType)name$Store
    retStmt := ReturnStmt.makeSynthetic(loc)
    retStmt.expr = TypeCheckExpr.coerce(
      f.makeAccessorExpr(loc, false),
      m.ret)
    m.code.add(retStmt)
  }

  private Void callInstanceInit(TypeDef t, MethodDef ii)
  {
    // we call instance$init in every constructor
    // unless the constructor chains to "this"
    t.methodDefs.each |MethodDef m|
    {
      if (!m.isCtor) return
      if (compiler.isSys) return
      if (m.ctorChain != null && m.ctorChain.target.id === ExprId.thisExpr) return
      call := CallExpr.makeWithMethod(m.location, ThisExpr(m.location), ii)
      m.code.stmts.insert(0, call.toStmt)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Field Normalization
//////////////////////////////////////////////////////////////////////////

  private Void normalizeField(FieldDef f)
  {
    // validate type of field
    t := f.fieldType
    if (t.isThis)   { err("Cannot use This as field type", f.location); return }
    if (t.isVoid)   { err("Cannot use Void as field type", f.location); return }
    if (!t.isValid) { err("Invalid type '$t'", f.location); return }

    // if this field overrides a concrete field, that means we already have
    // a concrete getter/setter for this field - if either of this field's
    // accessors is synthetic, then rewrite the one generated by Parser with
    // one that calls the "super" version of the accessor
    if (f.concreteBase != null && !f.isAbstract && !f.isNative)
    {
      if (!f.hasGet) genSyntheticOverrideGet(f)
      if (!f.hasSet) genSyntheticOverrideSet(f)
    }

    // ensure that getter is using inherited return
    // in case we have a covariant override
    if (f.get != null)
      f.get.inheritedRet = f.inheritedRet
  }

  private Void genSyntheticOverrideGet(FieldDef f)
  {
    loc := f.location
    f.get.code.stmts.clear
    f.get.code.add(ReturnStmt.makeSynthetic(loc, FieldExpr(loc, SuperExpr(loc), f.concreteBase)))
  }

  private Void genSyntheticOverrideSet(FieldDef f)
  {
    loc := f.location
    lhs := FieldExpr(loc, SuperExpr(loc), f.concreteBase)
    rhs := UnknownVarExpr(loc, null, "val")
    code := f.get.code
    f.set.code.stmts.clear
    f.set.code.add(BinaryExpr.makeAssign(lhs, rhs).toStmt)
    f.set.code.add(ReturnStmt.makeSynthetic(loc))
  }

  private static ExprStmt fieldInitStmt(FieldDef f)
  {
    useAccessor := f.concreteBase != null
    lhs := f.makeAccessorExpr(f.location, useAccessor)
    rhs := f.init
    return BinaryExpr.makeAssign(lhs, rhs).toStmt
  }

}