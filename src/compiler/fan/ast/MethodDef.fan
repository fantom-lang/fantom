//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//   19 Jul 06  Brian Frank  Ported from Java to Fan
//

**
** MethodDef models a method definition - it's signature and body.
**
class MethodDef : SlotDef, CMethod
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MethodDef makeStaticInit(Location location, TypeDef parent, Block? block)
  {
    def := make(location, parent)
    def.name   = "static\$init"
    def.flags  = FConst.Private | FConst.Static | FConst.Synthetic
    def.ret    = parent.ns.voidType
    def.code   = block
    return def;
  }

  public static MethodDef makeInstanceInit(Location location, TypeDef parent, Block? block)
  {
    def := make(location, parent)
    def.name   = "instance\$init\$$parent.pod.name\$$parent.name";
    def.flags  = FConst.Private | FConst.Synthetic
    def.ret    = parent.ns.voidType
    def.code   = block
    return def;
  }

  new make(Location location, TypeDef parent, Str name := "?", Int flags := 0)
     : super(location, parent)
  {
    this.name = name
    this.flags = flags
    this.ret = parent.ns.error
    paramDefs = ParamDef[,]
    vars = MethodVar[,]
    needsCvars = false
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this a static initializer block.
  **
  Bool isStaticInit() { return name == "static\$init" }
  static Bool isNameStaticInit(Str name) { return name == "static\$init" }

  **
  ** Return if this a instance initializer block.
  **
  Bool isInstanceInit() { return name.startsWith("instance\$init\$") }
  static Bool isNameInstanceInit(Str name) { return name.startsWith("instance\$init\$") }

  **
  ** Return if getter/setter for FieldDef
  **
  Bool isFieldAccessor()
  {
    return accessorFor != null
  }

  **
  ** Return if this is a once method
  **
  Bool isOnce() { return flags & Parser.Once != 0 }

  **
  ** Make and add a MethodVar for a local variable.
  **
  MethodVar addLocalVarForDef(LocalDefStmt def, Block? scope)
  {
    var := addLocalVar(def.ctype, def.name, scope)
    var.isCatchVar = def.isCatchVar
    return var
  }

  **
  ** Make and add a MethodVar for a local variable.  If name is
  ** null then we auto-generate a temporary variable name
  **
  MethodVar addLocalVar(CType ctype, Str? name, Block? scope)
  {
    // allocate next register index, implicit this always register 0
    reg := vars.size
    if (!isStatic) reg++

    // auto-generate name
    if (name == null) name = "\$temp" + reg

    // create variable and add it variable list
    var := MethodVar.make(reg, ctype, name, 0, scope)
    vars.add(var)
    return var
  }

  **
  ** Get the cvars local variable or throw and exception if not defined
  **
  MethodVar cvarsVar()
  {
    var := vars.find |MethodVar v->Bool| { v.name == "\$cvars" }
    if (var != null) return var
    throw Err("Expected cvars local to be defined: $qname")
  }

//////////////////////////////////////////////////////////////////////////
// CMethod
//////////////////////////////////////////////////////////////////////////

  override Str signature()
  {
    return qname + "(" + params.join(",") + ")"
  }

  override CType returnType()
  {
    return ret
  }

  override CType inheritedReturnType()
  {
    if (inheritedRet != null)
      return inheritedRet
    else
      return ret
  }

  override CParam[] params()
  {
    return paramDefs
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  override Void walk(Visitor v, VisitDepth depth)
  {
    v.enterMethodDef(this)
    walkFacets(v, depth)
    if (depth >= VisitDepth.stmt)
    {
      if (depth >= VisitDepth.expr)
      {
        if (ctorChain != null) ctorChain = (CallExpr)ctorChain.walk(v)
        paramDefs.each |ParamDef p| { if (p.def != null) p.def = p.def.walk(v) }
      }
      if (code != null) code.walk(v, depth)
    }
    v.visitMethodDef(this)
    v.exitMethodDef(this)
  }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  override [Str:Str]? docMeta()
  {
    if (paramDefs.isEmpty || !paramDefs[-1].hasDefault)
      return null

    meta := Str:Str[:]
    paramDefs.each |ParamDef p|
    {
      if (p.hasDefault) meta[p.name+".def"] = p.def.toDocStr
    }
    return meta
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Void print(AstWriter out)
  {
    printFacets(out)
    out.flags(flags).w(ret).w(" ").w(name).w("(")
    paramDefs.each |ParamDef p, Int i|
    {
      if (i > 0) out.w(", ")
      p.print(out)
    }
    out.w(")").nl

    if (ctorChain != null) { out.w(" : "); ctorChain.print(out); out.nl }

    if (code != null) code.print(out)
    out.nl
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  CType ret              // return type
  CType? inheritedRet    // used for original return if covariant
  ParamDef[] paramDefs   // parameter definitions
  Block? code            // code block
  CallExpr? ctorChain    // constructor chain for this/super ctor
  MethodVar[] vars       // all param/local variables in method
  FieldDef? accessorFor  // if accessor method for field
  Bool needsCvars        // does this method have locals used inside closures

}