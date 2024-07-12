//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsType
**
class JsType : JsNode
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(CompileEsPlugin plugin, TypeDef def) : super(plugin, def)
  {
    this.hasNatives = null != def.slots.find |n| { n.isNative && n.parent.qname == def.qname }
    this.peer = findPeer(plugin, def)
  }

  static CType? findPeer(CompileEsPlugin plugin, CType def)
  {
    CType? t := def
    while (t != null)
    {
      slot := t.slots.find |s| { s.isNative && s.parent.qname == t.qname }
      if (slot != null) return slot.parent
      t = t.base
    }
    return null
  }

  override TypeDef? node() { super.node }

  ** Does this type have any native slots directly
  const Bool hasNatives

  ** Compiler peer type if it has one
  CType? peer { private set }

  ** Compiler TypeDef
  TypeDef def() { this.node }

  ** Compiler name for the type
  Str name() { def.name }

  ** Compiler base type
  CType base() { def.base }

  ** Facets for this type
  FacetDef[] facets() { def.facets ?: FacetDef[,] }

  ** Mixins for this type
  CType[] mixins() { def.mixins }

  ** Fields
  FieldDef[] fields() { def.fieldDefs }

  once FieldDef[] enumFields()
  {
    fields.findAll { it.enumDef != null }.sort |a,b| { a.enumDef.ordinal <=> b.enumDef.ordinal }
  }

  ** Methods (excluding instanceInit)
  once MethodDef[] methods() { def.methodDefs.findAll |m| { !m.isInstanceInit } }

  ** Get the instanceInit method if one is defined
  once MethodDef? instanceInit() { def.methodDefs.find |m| { m.isInstanceInit } }

  override Str toStr() { def.signature }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  override Void write()
  {
    // class/mixin - note mixins do not extend Obj
    if (def.isMixin)
      js.wl("class ${name} {", loc)
    else
      js.wl("class ${name} extends ${qnameToJs(base)} {", loc)

    js.indent

    writeCtor
    if (!def.isSynthetic) js.wl("typeof() { return ${name}.type\$; }", loc).nl
    mixins.each |m| { copyMixin(m) }

    // slots
    fields.each |f| { writeField(f) }
    methods.each |m| { writeMethod(m) }

    js.unindent
    js.wl("}")
  }

  private Void copyMixin(CType ref)
  {
    ref.slots.each |CSlot slot|
    {
      if (slot.parent.isObj) return
      if (slot.isAbstract) return

      if (slot.isStatic)
      {
        // copy static fields
        //
        // NOTE: we don't need to do static methods because the compiler
        // appears to resolve those correctly in an earlier step
        if (slot.isPrivate) return
        if (slot.name == "static\$init") return
        if (slot is CMethod) return
        slotName := methodToJs(slot.name)
        js.wl("static ${slotName}() { return ${qnameToJs(slot.parent)}.${slotName}(); }").nl
        return
      }

      if (!slot.isPrivate)
      {
        // check if this mixin's slot was resolved by the compiler as the
        // implementation for the corresponding slot on this JsType
        resolved := def.slots.find { it.qname == slot.qname }
        if (resolved == null) return
      }

      // use mixin implementation (hijack it from the parent type's prototype)
      slotName := methodToJs(slot.name)
      js.wl("${slotName}() { return ${qnameToJs(slot.parent)}.prototype.${slotName}.apply(this, arguments); }").nl
    }
  }

  private Void writeCtor()
  {
    js.wl("constructor() {", loc)
    js.indent
    if (!def.isMixin) js.wl("super();")
    if (peer != null) js.wl("this.peer = new ${qnameToJs(peer)}Peer(this);", loc)
    js.wl("const this\$ = this;", loc)
    if (instanceInit != null)
    {
      plugin.curMethod = instanceInit
      writeBlock(instanceInit.code)
      plugin.curMethod = null
    }
    js.unindent
    js.wl("}").nl
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Void writeField(FieldDef f)
  {
    privName   := fieldToJs(f.name)
    accessName := methodToJs(f.name)

    if (f.isNative) return writeNativeField(f, accessName)
    if (f.isEnum)   return writeEnumField(f, accessName)
    if (f.isStatic) return writeStaticField(f, privName, accessName)

    // write "normal" field

    // write field storage
    js.wl("${privName} = ${fieldDefVal(f)};", f.loc).nl

    // write synthetic public API for reading/writing the field

    // private getter/setter
    priv := "__${accessName}(it) { if (it === undefined) return this.${privName}; else this.${privName} = it; }"
    if (f.isPrivate)
    {
      // generate internal getter/setter for use by compiler/reflection
      js.wl("// private field reflection only")
      js.wl(priv, f.loc).nl
      return
    }

    // special handling for const fields
    if (f.isConst)
    {
      // generate public getter
      js.wl("${accessName}() { return this.${privName}; }", f.loc).nl
      // but always generate a synthetic getter/setter for use by the compiler/reflection
      js.wl(priv, f.loc).nl
      return
    }

    // skip fields with no public getter or setter
    // TODO: I don't think this code path ever gets triggered
    if ((f.getter?.isPrivate ?: true) && (f.setter?.isPrivate ?: true)) return

    // use actual field name for public api
    allowSet := f.setter != null && !f.setter.isPrivate
    js.w("${accessName}(", f.loc)
    if (allowSet) js.w("it")
    js.wl(") {")
    js.indent

    // closure support
    getterHasClosure := ClosureFinder((MethodDef?)f.getter).exists
    setterHasClosure := ClosureFinder((MethodDef?)f.setter).exists

    if (!allowSet)
    {
      plugin.curMethod = f.getter
      if (getterHasClosure) js.wl("const this\$ = ${plugin.thisName};", loc)
      writeBlock(f.getter->code)
      plugin.curMethod = null
    }
    else
    {
      js.wl("if (it === undefined) {").indent
      plugin.curMethod = f.getter
      if (getterHasClosure) js.wl("const this\$ = ${plugin.thisName};", loc)
      writeBlock(f.getter->code)
      plugin.curMethod = null
      js.unindent.wl("}")
      js.wl("else {").indent
      plugin.curMethod = f.setter
      if (setterHasClosure) js.wl("const this\$ = ${plugin.thisName};", loc)
      writeBlock(f.setter->code)
      plugin.curMethod = null
      js.unindent.wl("}")
    }
    js.unindent.wl("}").nl
  }

  private static Str fieldDefVal(FieldDef f)
  {
    defVal    := "null"
    fieldType := f.fieldType
    if (!fieldType.isNullable)
    {
      switch (fieldType.signature)
      {
        case "sys::Bool":    defVal = "false"
        case "sys::Int":     defVal = "0"
        case "sys::Float":   defVal = "sys.Float.make(0)"
        case "sys::Decimal": defVal = "sys.Decimal.make(0)"
      }
    }
    return defVal
  }

  private Void writeNativeField(FieldDef f, Str accessName)
  {
    if (f.isStatic) throw Err("TODO:FIXIT static native field")
    if (f.isPrivate) throw Err("TODO:FIXIT private native field?")

    js.wl("$accessName(it) {").indent
    js.wl("if (it === undefined) return this.peer.${accessName}(this);")
    js.wl("this.peer.${accessName}(this, it);")
    js.unindent.wl("}").nl
  }

  private Void writeStaticField(FieldDef f, Str privName, Str accessName)
  {
    target := f.parent.name
    js.wl("static ${privName} = undefined;", f.loc).nl

    // we generate our own special version of this
    if (f.parent.isEnum && accessName == "vals") return

    js.wl("static ${accessName}() {").indent

    fieldAccess := "${target}.${privName}"
    js.wl("if (${fieldAccess} === undefined) {").indent
    // call the static initializer
    // if the value is still not initialized, then set it to its default value
    js.wl("${target}.${curType.staticInit.name}();")
    js.wl("if (${fieldAccess} === undefined) ${fieldAccess} = ${fieldDefVal(f)};")
    js.unindent.wl("}")

    // we can't do it this way because if a static field is initialized in an
    // actual static block, then we f.init will be null, and the the static init
    // block might not have initialized the field
    // js.w("if (${target}.${privName} === undefined) ${target}.${privName} = ")
    //   if (f.init == null) js.w(fieldDefVal(f))
    //   else writeExpr(f.init)
    //   js.wl(";")

    js.wl("return ${target}.${privName};")
    js.unindent.wl("}").nl
  }

  private Void writeEnumField(FieldDef f, Str accessName)
  {
    ord := f.enumDef.ordinal
    js.wl("static ${accessName}() { return ${qnameToJs(f.parent)}.vals().get(${ord}); }").nl
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  private Void writeMethod(MethodDef m)
  {
    plugin.curMethod = m
    if (curType.isEnum)
    {
      if (m.isStaticInit) return writeEnumStaticInit(m)
      else if (m.isStatic && m.name == "fromStr") return writeEnumFromStr(m)
    }

    selfJs := nameToJs("\$self")
    nameJs := methodToJs(m.name)
    typeJs := qnameToJs(m.parentDef)
    if (typeJs != qnameToJs(def)) throw Err("??? ${typeJs} ${qnameToJs(def)}")
    if (m.isInstanceCtor)
    {
      // write static factory make method
      ctorParams := CParam[SyntheticParam(selfJs, curType)].addAll(m.params)
      js.wl("static ${nameJs}${methodParams(m.params)} {", m.loc)
        .indent
        .wl("const ${selfJs} = new ${typeJs}();")
        .wl("${typeJs}.${nameJs}\$${methodParams(ctorParams)};")
        .wl("return ${selfJs};")
        .unindent
        .wl("}").nl

      // write factory make$ method
      try
      {
        plugin.thisName = selfJs
        doWriteMethod(m, "${nameJs}\$", ctorParams)
      }
      finally plugin.thisName = "this"
    }
    else if (m.isGetter || m.isSetter)
    {
      // getters and setters are synthetically generated when we emit
      // the field (see writeField)
      return
    }
    else doWriteMethod(m)
    plugin.curMethod = null
  }

  private Void doWriteMethod(MethodDef m, Str methName := methodToJs(m.name), CParam[] methParams := m.params)
  {
    // skip abstract methods
    if (m.isAbstract) return

    if (m.isStatic || m.isInstanceCtor) js.w("static ")
    js.wl("${methName}${methodParams(methParams)} {", m.loc)
    js.indent

    // default parameters
    methParams.each |param|
    {
      if (!param.hasDefault) return
      nameJs := nameToJs(param.name)
      js.w("if (${nameJs} === undefined) ${nameJs} = ", toLoc(param))
      JsExpr(plugin, param->def).write
      js.wl(";")
    }

    // closure support
    writeClosureSupport(m, methName, methParams)

    if (m.isNative)
    {
      if (m.isStatic)
      {
        js.wl("return ${qnameToJs(peer)}Peer.${methName}${methodParams(methParams)};", m.loc)
      }
      else
      {
        pars := CParam[SyntheticParam("this", curType)].addAll(methParams)
        js.wl("return this.peer.${methName}${methodParams(pars)};", m.loc)
      }
    }
    else
    {
      // ctor chaining
      if (m.ctorChain != null)
      {
        JsExpr(plugin, m.ctorChain).write
        js.wl(";")
      }

      // method body
      writeBlock(m.code)
    }

    js.unindent
    js.wl("}").nl
  }

  private Void writeClosureSupport(MethodDef m, Str methName, CParam[] methParams)
  {
    // if the method contains closure we need to provide them access to this
    hasClosure := ClosureFinder(m).exists
    if (hasClosure) js.wl("const this\$ = ${plugin.thisName};")

    // if the last argument is a closure and this is a "special" typed method
    // then we need to set the return type on the closure
    if (!JsCallExpr.typedFuncs.contains(methName)) return
    param := methParams.last
    if (param == null) return
    ft := resolveType(param.paramType) as FuncType
    if (ft == null) return
    name := nameToJs(param.name)
    js.wl("${name}.__returns = ((arg) => { let r = arg; if (r == null || r == sys.Void.type\$ || !(r instanceof sys.Type)) r = null; return r; })(arguments[arguments.length-1]);")
  }

  ** An enum static$init method is used to initialize the enum vals.
  ** We handle that by doing it lazily so that we don't run into
  ** static init ordering issues.
  private Void writeEnumStaticInit(MethodDef m)
  {
    enumName  := qnameToJs(m.parent)
    valsField := "${enumName}.#vals"

    js.wl("static vals() {", m.loc).indent
    js.wl("if (${valsField} == null) {").indent

    js.wl("${valsField} = sys.List.make(${enumName}.type\$, [").indent
    enumFields.each |FieldDef f, Int i| {
      def := f.enumDef
      js.w("${enumName}.make(${def.ordinal}, ${def.name.toCode}, ")
      def.ctorArgs.each |Expr arg, Int j| {
        if (j > 0) js.w(", ")
        writeExpr(arg)
      }
      js.wl("),")
    }
    js.unindent.wl("]).toImmutable();")

    js.unindent.wl("}")
    js.wl("return ${valsField};")
    js.unindent.wl("}").nl

    // TODO: this feels brittle
    // some enums have static initializers for other fields
    // so we still need to emit the code for those. It turns
    // out they appear to be all statements including and after the first if stmt:
    //   if (true) {...}
    // so we look for those and only write those.
    js.wl("static static\$init() {").indent
    // force the enum vals to be loaded because the static init code
    // might be attempting to reference <Enum>.#vals field directly
    js.wl("const ${uniqName} = ${enumName}.vals();")

    // find the first IfStmt block. It is assumed that all static init
    // prior to that is for the actual enum fields. We skip those since they are
    // handled special by the compiler and do the rest of the stmts
    ifIdx := m.code.stmts.findIndex |item| { item is IfStmt }
    if (ifIdx != null)
    {
      m.code.stmts[ifIdx..-1].each |stmt| {
        writeStmt(stmt)
        js.wl(";")
      }
    }
    js.unindent.wl("}").nl
  }

  private Void writeEnumFromStr(MethodDef m)
  {
    typeName := qnameToJs(m.parent)
    js.w("static ").w("fromStr(name\$, checked=true)", m.loc).wl(" {").indent
    js.wl("return sys.Enum.doFromStr(${typeName}.type\$, ${typeName}.vals(), name\$, checked);")
    js.unindent.wl("}").nl
  }

}

**************************************************************************
** SyntheticParam
**************************************************************************

internal class SyntheticParam : CParam
{
  new make(Str name, CType type) { this.name = name; this.type = type }
  override const Str name
  private CType type
  override CType paramType() { return this.type; }
  override const Bool hasDefault := false
}

**************************************************************************
** ClosureFinder
**************************************************************************

internal class ClosureFinder : Visitor
{
  new make(Node? node) { this.node = node }
  Node? node { private set }
  Bool found := false
  Bool exists()
  {
    if (node == null) return found
    node->walk(this, VisitDepth.expr)
    return found
  }
  override Expr visitExpr(Expr expr)
  {
    if (expr is ClosureExpr) found = true
    return Visitor.super.visitExpr(expr)
  }
}
