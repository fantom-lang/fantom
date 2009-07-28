//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsPod
**
class JsPod : JsNode
{
  new make(CompilerSupport s, PodDef pod, TypeDef[] types) : super(s)
  {
    this.name  = pod.name
    this.types = types.map |TypeDef t->JsType| { JsType(s, t) }
  }

  override Void write(JsWriter out)
  {
    out.w("fan.$name = {};").nl  // define namespace
    out.w("fan.${name}.\$pod = fan.sys.Pod.\$add('$name');").nl  // define pod
    typeInfo(out)
  }

  Void typeInfo(JsWriter out)
  {
    out.w("with (fan.${name}.\$pod)").nl
    out.w("{").nl

    // filter out synthetic types from reflection
    reflect := types.findAll |t| { !t.isSynthetic }

    // write all types first
    reflect.each |t,i|
    {
      adder  := t.isMixin ? "\$am" : "\$at"
      base   := "$t.base.pod::$t.base.name"
      mixins := t.mixins.join(",") |m| { "'$m.pod::$m.name'" }
      out.w("  var \$$i=$adder('$t.name','$base',[$mixins])").nl
    }

    // then write slot info
    reflect.each |t,i|
    {
      if (t.fields.isEmpty && t.methods.isEmpty) return
      out.w("  \$$i")
      t.fields.each |f| { out.w(".\$af('$f.name',$f.flags,'$f.ftype.sig')") }
      t.methods.each |m| { if (!m.isFieldAccessor) out.w(".\$am('$m.name',$m.flags)") }
      out.w(";").nl
    }

    out.w("}").nl
  }

  Str name        // pod name
  JsType[] types  // types in this pod
}

