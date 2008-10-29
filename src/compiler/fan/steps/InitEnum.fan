//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Apr 06  Brian Frank  Creation
//   22 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** InitEnum is used to auto-generate EnumDefs into abstract
** syntax tree representation of the fields and method.
**
**
class InitEnum : CompilerStep
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
    log.debug("InitEnum")
    walk(types, VisitDepth.typeDef)
    bombIfErr
  }

  override Void visitTypeDef(TypeDef t)
  {
    if (!t.isEnum) return

    try
    {
      addCtor
      addFromStr
      t.addFacet(this, "simple", true)

      fields := FieldDef[,]
      t.enumDefs.each |EnumDef e| { fields.add(makeField(e)) }
      fields.add(makeValuesField)

      // add enum fields to beginning of type
      fields.each |FieldDef f, Int i| { t.addSlot(f, i) }
    }
    catch (CompilerErr e)
    {
    }
  }

//////////////////////////////////////////////////////////////////////////
// Make Ctor
//////////////////////////////////////////////////////////////////////////

  **
  ** Add constructor or enhance existing constructor.
  **
  Void addCtor()
  {
    // our constructor definition
    MethodDef? m :=  null

    // check if there are any existing constructors - there
    // can only be zero or one called make
    ctors := curType.methodDefs.findAll |MethodDef x->Bool| { return x.isCtor }
    ctors.each |MethodDef ctor|
    {
      if (ctor.name == "make")
        m = ctor
      else
        throw err("Enum constructor must be named 'make'", ctor.location)
    }

    // if we found an existing constructor, then error check it
    if (m != null)
    {
      if (!m.isPrivate)
        err("Enum constructor must be private", m.location)

      if (m.ctorChain != null)
        err("Enum constructor cannot call super constructor", m.location)
    }

    // if we didn't find an existing constructor, then
    // add a synthetic one
    if (m == null)
    {
      m = MethodDef.make(curType.location, curType)
      m.name = "make"
      m.flags = FConst.Ctor | FConst.Private | FConst.Synthetic
      m.ret = TypeRef.make(curType.location, ns.voidType)
      m.code = Block.make(curType.location)
      m.code.stmts.add(ReturnStmt.make(curType.location))
      curType.addSlot(m)
    }

    // Enum.make call
    loc := m.location
    m.ctorChain = CallExpr.make(loc, SuperExpr.make(loc), "make")
    m.ctorChain.isCtorChain = true
    m.ctorChain.args.add(UnknownVarExpr.make(loc, null, "\$ordinal"))
    m.ctorChain.args.add(UnknownVarExpr.make(loc, null, "\$name"))

    // insert ordinal, name params
    m.params.insert(0, ParamDef.make(loc, ns.intType, "\$ordinal"))
    m.params.insert(1, ParamDef.make(loc, ns.strType, "\$name"))
  }

//////////////////////////////////////////////////////////////////////////
// Make FromStr
//////////////////////////////////////////////////////////////////////////

  **
  ** Add fromStr method.
  **
  Void addFromStr()
  {
    // static CurType fromStr(Str name, Bool checked := true)
    loc := curType.location
    m := MethodDef.make(loc, curType)
    m.name = "fromStr"
    m.flags = FConst.Static | FConst.Public
    m.params.add(ParamDef.make(loc, ns.strType, "name"))
    m.params.add(ParamDef.make(loc, ns.boolType, "checked", LiteralExpr.make(loc, ExprId.trueLiteral, ns.boolType, true)))
    m.ret = TypeRef.make(loc, curType.toNullable)
    m.code = Block.make(loc)
    m.doc  = ["Return the $curType.name instance for the specified name.  If not a",
              "valid name and checked is false return null, otherwise throw ParseErr."]
    curType.addSlot(m)

    // return (CurType)doParse(name, checked)
    doFromStr := CallExpr.make(loc, null, "doFromStr")
    doFromStr.args.add(LiteralExpr.make(loc, ExprId.typeLiteral, ns.typeType, curType))
    doFromStr.args.add(UnknownVarExpr.make(loc, null, "name"))
    doFromStr.args.add(UnknownVarExpr.make(loc, null, "checked"))
    cast := TypeCheckExpr(loc, ExprId.coerce, doFromStr, curType.toNullable)
    m.code.stmts.add(ReturnStmt.make(loc, cast))
  }

//////////////////////////////////////////////////////////////////////////
// Make Field
//////////////////////////////////////////////////////////////////////////

  **
  ** Make enum value field:  public static final Foo name = make(ord, name)
  **
  FieldDef makeField(EnumDef def)
  {
    // ensure there isn't already a slot with same name
    dup := curType.slot(def.name)
    if (dup != null)
    {
      if (dup.parent === curType)
        throw err("Enum '$def.name' conflicts with slot", (Location)dup->location)
      else
        throw err("Enum '$def.name' conflicts with inherited slot '$dup.qname'", def.location)
    }

    loc := def.location

    // initializer
    init := CallExpr.make(loc, null, "make")
    init.args.add(LiteralExpr.make(loc, ExprId.intLiteral, ns.intType, def.ordinal))
    init.args.add(LiteralExpr.make(loc, ExprId.strLiteral, ns.strType, def.name))
    init.args.addAll(def.ctorArgs)

    // static field
    f := FieldDef.make(loc, curType)
    f.flags     = FConst.Public | FConst.Static | FConst.Const | FConst.Storage | FConst.Enum
    f.name      = def.name
    f.fieldType = curType
    f.init      = init
    return f
  }

  **
  ** Make values field: List of Enum values
  **
  FieldDef makeValuesField()
  {
    // ensure there isn't already a slot with same name
    dup := curType.slot("values")
    if (dup != null)
    {
      if (dup.parent == curType)
        throw err("Enum 'values' conflicts with slot", (Location)dup->location)
      else
        throw err("Enum 'values' conflicts with inherited slot '$dup.qname'", curType.location)
    }

    loc := curType.location

    // initializer
    listType := curType.toListOf
    init := ListLiteralExpr.make(loc, listType)
    curType.enumDefs.each |EnumDef e|
    {
      target := StaticTargetExpr.make(loc, curType)
      init.vals.add(UnknownVarExpr.make(loc, target, e.name))
    }

    // static field
    f := FieldDef.make(loc, curType)
    f.flags     = FConst.Public | FConst.Static | FConst.Const | FConst.Storage
    f.name      = "values"
    f.fieldType = listType
    f.init      = init
    f.doc       = ["List of $curType.name values indexed by ordinal"]
    return f
  }

}