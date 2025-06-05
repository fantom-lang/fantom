//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 2025  Brian Frank  Split from JavaPrinter
//

using compiler

**
** Java transpiler printer for types
**
internal class JavaTypePrinter : JavaPrinter
{
  new make(OutStream out) : super.makeTop(out) {}

  override JavaPrinterState m() { super.m }

  Void type(TypeDef t)
  {
    m.curType = t
    wrappers.clear

    prelude(t)
    typeHeader(t)
    w(" {").nl
    indent.nl
    javaCtor(t, JavaUtil.typeName(t))
    typeOf(t)
    enumOrdinals(t)
    slots(t)
    syntheticClasses(t)
    nativePeer(t)
    unindent
    w("}").nl

    m.curType = null
    wrappers.clear
  }

  Void prelude(TypeDef t)
  {
    // NOTE: we use non-qualified names for the following imported types
    // because we expect they would never be used in typical Fantom code;
    // but the Java code will not compile if there is a duplicate class

    w("// Transpiled $Date.today").nl
    nl
    w("package fan.").w(t.pod.name).eos
    nl
    w("import fan.sys.FanObj").eos
    w("import fan.sys.FanBool").eos
    w("import fan.sys.FanNum").eos
    w("import fan.sys.FanInt").eos
    w("import fan.sys.FanFloat").eos
    w("import fan.sys.FanStr").eos
    w("import fan.sys.List").eos
    w("import fan.sys.Map").eos
    w("import fan.sys.Type").eos
    w("import fan.sys.Func").eos
    w("import fan.sys.Sys").eos
    w("import fanx.util.OpUtil").eos
    nl
  }

  Void typeHeader(TypeDef t)
  {
    // scope
    if (t.isPublic) w("public ")
    if (t.isAbstract) w("abstract ")
    if (t.isFinal) w("final ")

    // interface vs class
    w(t.isMixin ? "interface" : "class").sp.typeName(t)

    // extends
    if (!t.isMixin) extends(t)

    // implements
    if (!t.mixins.isEmpty) implements(t)
  }

  This extends(TypeDef t)
  {
    w(" extends ")
    if (t.base.isObj) qnFanObj
    else if (t.isClosure) w(JavaUtil.closureBase(t))
    else typeSig(t.base)
    return this
  }

  This implements(TypeDef t)
  {
    if (t.isMixin)
      w(" extends ")
    else
      w(" implements ")
    t.mixins.each |m, i|
    {
      if (i > 0) w(", ")
      typeSig(m)
    }
    return this
  }

  Void javaCtor(TypeDef t, Str name, |This|? onCode := null)
  {
    if (t.isMixin) return

    w("/** Constructor for Fantom use only */").nl
    w(t.isFinal ? "private" : "protected").sp.w(name).w("()").sp.w("{").nl
    indent
    if (onCode != null) onCode(this)
    if (t.hasNativePeer)
      w("this.").w(JavaUtil.peerFieldName).w(" = ").w(JavaUtil.peerTypeName(t)).w(".make(this)").eos
    unindent
    w("}").nl
  }

  Void typeOf(TypeDef t)
  {
    nl
    if (t.isMixin)
    {
      // for mixins:
      // - don't generate typeof()
      // - don't generate cache static variable; lookup every call
      w("/** Type literal for $t.qname */").nl
      w("public static ").qnType.w(" typeof\$() { return ")
      qnType.w(".find(").str(t.qname).w("); }").nl
    }
    else
    {
      // normal classes:
      //   public Type typeof() { typeof$() }
      //   public static Type typeof$() {
      //     if (typeof$cache == null)
      //       typeof$cache = Type.find("foo::Foo");
      //     return typeof$cache;
      //   }
      //   private static Type typeof$cache;      w("/** Type literal for $t.qname */").nl
      w("/** Reflect type of this object */").nl
      w("public ").qnType.w(" typeof() { return typeof\$(); }").nl
      nl
      w("/** Type literal for $t.qname */").nl
      w("public static ").qnType.w(" typeof\$() {").nl
      w("  if (typeof\$cache == null)").nl
      w("    typeof\$cache = ").qnType.w(".find(").str(t.qname).w(");").nl
      w("  return typeof\$cache;").nl
      w("}").nl
      w("private static ").qnType.w(" typeof\$cache;").nl
    }
  }

  Void enumOrdinals(TypeDef t)
  {
    if (!t.isEnum) return

    nl
    t.enumDefs.each |e|
    {
      name := e.name.upper
      if (t.slot(name) != null) name = "_$name"
      w("public static final int ").w(name).w(" = ").w(e.ordinal).eos
    }
  }

  Void nativePeer(TypeDef t)
  {
    if (!t.hasNativePeer) return

    nl.w(JavaUtil.peerTypeName(t)).sp.w(JavaUtil.peerFieldName).eos
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  Void slots(TypeDef t)
  {
    ctors    := MethodDef[,]
    methods  := MethodDef[,]
    consts   := FieldDef[,]
    storages := FieldDef[,]
    MethodDef? staticInit

    t.slotDefs.each |x|
    {
      if (x is MethodDef)
      {
        m := (MethodDef)x
        if (m.isCtor || m.isInstanceInit)
          ctors.add(m)
        else if (m.isStaticInit)
          staticInit = m
        else
          methods.add(m)
      }
      else
      {
        f := (FieldDef)x
        if (f.isConst) consts.add(f)
        if (f.isStorage) storages.add(f)
      }
    }

    ctors.each    |x| { nl.method(x) }
    consts.each   |x| { constAccessors(x) }
    methods.each  |x| { nl.method(x) }
    if (!t.isMixin)
    {
      if (staticInit != null) nl.method(staticInit)
      storages.each |x| { fieldStorage(x) }
    }
    else
    {
      mixinStaticFields(staticInit, storages)
    }
  }

  Void constAccessors(FieldDef x)
  {
    // getter
    if (!x.isOverride)
    {
      nl
      slotScope(x)
      if (x.isStatic) w("static ")
      typeSig(x.type).sp.fieldName(x)

      w("() { return ")
      if (x.parent.isMixin) w(JavaUtil.mixinFieldsName).w(".")
      fieldName(x).w("; }").nl
    }

    // if the current class has an it-block ctor then
    // generate special setting that takes the it-block func
    if (curType.hasItBlockCtor && !x.isStatic)
    {
      nl
      w("/** Initialize const field $x.name - DO NOT USE DIRECTLY */").nl
      slotScope(x)
      if (x.isStatic) w("static ")
      w("void ").fieldName(x).w("\$init(").qnFunc.w(" f, ").typeSig(x.type).w(" it) {")
      w(" this.").fieldName(x).w(" = it; }").nl
    }
  }

  Void fieldStorage(FieldDef x)
  {
    if (x.isStatic) w("static ")
    typeSig(x.type).sp.fieldName(x).eos
    return this
  }

  Void mixinStaticFields(MethodDef? init, FieldDef[] fields)
  {
    // Java interfaces don't support static fields nor initializers;
    // so generate an inner class named Fields that declares storage
    // and handles static initilizer.  We swizzle get via constGetter()
    // and set in fieldAssign()
    nl.w("static class ").w(JavaUtil.mixinFieldsName).w(" {").nl
    indent
    fields.each |f| { fieldStorage(f) }
    if (init != null) method(init)
    unindent
    w("}").nl
  }

  Void method(MethodDef x)
  {
    // we cannot generate mixin object in Java
    if (x.parent.isMixin && x.name == "equals")
    {
      warn("Cannot generate mixin equals() in Java", x.loc)
      return
    }

    m.curMethod = x

    JavaMethodPrinter(this, x).print

    m.curMethod = null
    m.selfVar   = null
  }

//////////////////////////////////////////////////////////////////////////
// Closures & Synthetics
//////////////////////////////////////////////////////////////////////////

  private Void syntheticClasses(TypeDef parent)
  {
    // find my closures
    prefix := parent.qname + "\$"
    closures := TypeDef[,]
    parent.podDef.typeDefs.each |x|
    {
      if (JavaUtil.isSyntheticClosure(parent, x)) closures.add(x)
    }

    // sort by inner class name and generate
    closures.sort.each |x|
    {
      m.closure = x
      syntheticClass(x,  JavaUtil.syntheticClosureName(x))
      m.closure = null
    }

    // also generate every wrapper used as an inner class
    wrappers.each |x|
    {
      syntheticClass(x, JavaUtil.syntheticWrapperName(x))
    }
  }

  private Void syntheticClass(TypeDef x, Str name)
  {
    nl
    w("/** Synthetic closure support */").nl
    w("static final class ").w(name).extends(x).w(" {").nl
    indent
    if (x.isClosure) syntheticClosureSupport(x, name)
    slots(x)
    unindent
    w("}").nl
  }

  private Void syntheticClosureSupport(TypeDef x, Str name)
  {
    // constructor that calls super with type signature
    javaCtor(x, name) { it.w("super(typeof\$)").eos }

    // generate typeof and tyepof$
    nl.w("private static final fan.sys.FuncType typeof\$ = (fan.sys.FuncType)")
      .qnType.w(".find(").str(x.base.signature).w(")").eos
  }
}

