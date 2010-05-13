//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsType
**
class JsType : JsNode
{
  new make(JsCompilerSupport s, TypeDef def) : super(s)
  {
    this.base        = JsTypeRef(s, def.base)
    this.qname       = qnameToJs(def)
    this.pod         = def.pod.name
    this.name        = def.name
    this.sig         = def.signature
    this.flags       = def.flags
    this.peer        = findPeer(s, def)
    this.isNative    = def.isNative
    this.hasNatives  = null != def.slots.find |n| { n.isNative && n.parent.qname == def.qname }
    this.isMixin     = def.isMixin
    this.isSynthetic = def.isSynthetic
    this.mixins      = def.mixins.map |TypeRef r->JsTypeRef| { JsTypeRef(s, r) }
    this.fields      = def.fieldDefs.map |FieldDef f->JsField| { JsField(s, f) }
    if (def.staticInit != null) this.staticInit = def.staticInit.name

    this.methods = JsMethod[,]
    def.methodDefs.each |m|
    {
      if (m.isInstanceInit) instanceInit = JsBlock(s, m.code)
      else this.methods.add(JsMethod(s, m))
    }
  }

  static JsTypeRef? findPeer(JsCompilerSupport cs, CType def)
  {
    CType? t := def
    while (t != null)
    {
      slot := t.slots.find |s| { s.isNative && s.parent.qname == t.qname }
      if (slot != null) return JsTypeRef(cs, slot.parent)
      t = t.base
    }
    return null
  }

  override Void write(JsWriter out)
  {
    // class/mixin
    if (isMixin) out.w("$qname = function() {}").nl
    else out.w("$qname = fan.sys.Obj.\$extend($base.qname);").nl
    mixins.each |m| { copyMixin(m, out) }

    // ctor
    out.w("${qname}.prototype.\$ctor = function()").nl
    out.w("{").nl
    out.indent
    out.w("${base.qname}.prototype.\$ctor.call(this);").nl
    if (peer != null) out.w("this.peer = new ${peer.qname}Peer(this);").nl
    out.w("var \$this = this;").nl
    instanceInit?.write(out)
    out.unindent
    out.w("}").nl

    // type
    if (!isSynthetic)
      out.w("${qname}.prototype.\$typeof = function() { return ${qname}.\$type; }").nl

    // slots
    methods.each |m| { m.write(out) }
    fields.each |f| { f.write(out) }
  }

  // see JsPod.write
  Void writeStatic(JsWriter out)
  {
    // static inits
    if (staticInit != null)
      out.w("${qname}.static\$init();").nl
  }

  Void copyMixin(JsTypeRef ref, JsWriter out)
  {
    ref.slots.each |s|
    {
      if (s.parent == "fan.sys.Obj") return
      if (s.isAbstract) return
      if (s.isStatic) return
      if (overrides(s)) return
      out.w("${qname}.prototype.${s.name} = ${s.parent}.prototype.${s.name};").nl
    }
  }

  Bool overrides(JsSlotRef ref)
  {
    v := methods.find |m| { m.name == ref.name }
    return v != null
  }

  override Str toStr() { sig }

  JsTypeRef base         // base type qname
  Str qname              // type qname
  Str pod                // pod name for type
  Str name               // simple type name
  Str sig                // full type signature
  Int flags              // flags
  Bool isMixin           // is this type a mixin
  Bool isSynthetic       // is type synthetic
  JsTypeRef? peer        // peer type if has one
  Bool isNative          // is this a full native class
  Bool hasNatives        // does type have any native slots directly
  JsTypeRef[] mixins     // mixins for this type
  JsMethod[] methods     // methods
  JsField[] fields       // fields
  JsBlock? instanceInit  // instanceInit block
  Str? staticInit        // name of static initializer if has one - see JsPod
}

**************************************************************************
** JsTypeRef
**************************************************************************

**
** JsTypeRef
**
class JsTypeRef : JsNode
{
  static JsTypeRef make(JsCompilerSupport cs, CType ref)
  {
    key := ref.signature
    js  := cs.typeRef[key]
    if (js == null) cs.typeRef[key] = js = JsTypeRef.makePriv(cs, ref)
    return js
  }

  private new makePriv(JsCompilerSupport cs, CType ref) : super.make(cs)
  {
    this.qname = qnameToJs(ref)
    this.pod   = ref.pod.name
    this.name  = ref.name
    this.sig   = ref.signature
    this.slots = ref.slots.vals.map |CSlot s->JsSlotRef| { JsSlotRef(cs, s) }
    this.isSynthetic = ref.isSynthetic
    this.isNullable  = ref.isNullable
    this.isList = ref.isList
    this.isMap  = ref.isMap
    this.isFunc = ref.isFunc

    deref := ref.deref
    if (deref is ListType) v = JsTypeRef(cs, deref->v)
    if (deref is MapType)
    {
      k = JsTypeRef(cs, deref->k)
      v = JsTypeRef(cs, deref->v)
    }
  }

  override Void write(JsWriter out)
  {
    out.w(qname)
  }

  override Str toStr() { sig }

  Str qname          // qname of type ref
  Str pod            // pod name for type
  Str name           // simple type name
  Str sig            // full type signature
  JsSlotRef[] slots  // slots
  Bool isSynthetic   // is type synthetic
  Bool isNullable    // is type nullable
  Bool isList        // is type a sys::List
  Bool isMap         // is type a sys::Map
  Bool isFunc        // is type a sys::Func

  JsTypeRef? k       // only valid for MapType
  JsTypeRef? v       // only valid for ListType, MapType
}

