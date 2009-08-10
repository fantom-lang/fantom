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
  new make(CompilerSupport s, TypeDef def) : super(s)
  {
    this.base        = JsTypeRef(s, def.base)
    this.qname       = qnameToJs(def)
    this.pod         = def.pod.name
    this.name        = def.name
    this.peer        = findPeer(s, def)
    this.isMixin     = def.isMixin
    this.isSynthetic = def.isSynthetic
    this.mixins      = def.mixins.map |TypeRef r->JsTypeRef| { JsTypeRef(s, r) }
    this.methods     = def.methodDefs.map |MethodDef m->JsMethod| { JsMethod(s, m) }
    this.fields      = def.fieldDefs.map |FieldDef f->JsField| { JsField(s, f) }
    if (def.staticInit != null) this.staticInit = def.staticInit.name
  }

  static JsTypeRef? findPeer(CompilerSupport cs, CType def)
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
    out.w("${qname}.prototype.\$ctor = function() {")
    if (peer != null) out.w(" this.peer = new ${peer.qname}Peer(this); ")
    out.w("}").nl

    // cache type
    if (!isSynthetic)
    {
      out.w("${qname}.\$type = fan.sys.Type.find(\"$pod::$name\");").nl
      out.w("${qname}.prototype.type = function() { return ${qname}.\$type; }").nl
    }

    // slots
    methods.each |m| { m.write(out) }
    fields.each |f| { f.write(out) }

    // static init
    // static init's are written out after all
    // types have been defined - see Translate.fan
    //if (staticInit != null) out.w("${qname}.$staticInit();").nl
  }

  Void copyMixin(JsTypeRef ref, JsWriter out)
  {
    ref.slots.each |s|
    {
      if (s.parent == "fan.sys.Obj") return
      if (s.isAbstract) return
      if (s.isStatic) return
      out.w("${qname}.prototype.${s.name} = ${s.parent}.prototype.${s.name};").nl
    }
  }

  JsTypeRef base      // base type qname
  Str qname           // type qname
  Str pod             // pod name for type
  Str name            // simple type name
  Bool isMixin        // is this type a mixin
  Bool isSynthetic    // is type synthetic
  JsTypeRef? peer     // peer type if has one
  JsTypeRef[] mixins  // mixins for this type
  JsMethod[] methods  // methods
  JsField[] fields    // fields
  Str? staticInit     // name of static initializer if has one
}

**************************************************************************
** JsTypeRef
**************************************************************************

**
** JsTypeRef
**
class JsTypeRef : JsNode
{
  new make(CompilerSupport cs, CType ref) : super(cs)
  {
    this.qname = qnameToJs(ref)
    this.pod   = ref.pod.name
    this.name  = ref.name
    this.sig   = ref.signature
    this.slots = ref.slots.values.map |CSlot s->JsSlotRef| { JsSlotRef(cs, s) }
    this.isSynthetic = ref.isSynthetic
  }

  override Void write(JsWriter out)
  {
    out.w(qname)
  }

  Str qname          // qname of type ref
  Str pod            // pod name for type
  Str name           // simple type name
  Str sig            // full type signature
  JsSlotRef[] slots  // slots
  Bool isSynthetic   // is type synthetic
}

