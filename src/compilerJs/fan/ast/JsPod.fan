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
  new make(CompilerSupport s, PodDef pod, TypeDef[] defs) : super(s)
  {
    this.name  = pod.name
    this.types = JsType[,]

    compiler := (JsCompiler)support.compiler
    this.natives = compiler.natives.dup

    defs.each |TypeDef def|
    {
      // we inline closures directly, so no need to generate
      // anonymous types like we do in Java and .NET
      if (def.isClosure) return

      // TODO FIXIT: do we still need this?
      if (def.qname.contains("\$Cvars"))
      {
        echo("WARN: Cvar class: $def.qname")
        return
      }

      // check for forced or @js facet
      if (s.compiler->force || def.hasMarkerFacet("sys::js"))
        types.add(JsType(s,def))
    }
  }

  override Void write(JsWriter out)
  {
    // define namespace
    out.w("fan.$name = {};").nl

    // write types
    types.each |t|
    {
      t.write(out)
      if (t.hasNatives) writePeer(out, t)
    }

    // write type info
    writeTypeInfo(out)

    // write static init
    types.each |t| { t.writeStatic(out) }

    // write remaining natives
    natives.each |f|
    {
      in := f.in
      out.minify(in)
      in.close
    }
  }

  Void writePeer(JsWriter out, JsType t)
  {
    key  := "${t.peer.name}Peer.js"
    file := natives[key]
    if (file == null)
    {
      support.err("Missing native impl for $t.sig", Location("${t.name}.fan"))
    }
    else
    {
      in := file.in
      out.minify(in)
      in.close
      natives.remove(key)
    }
  }

  Void writeTypeInfo(JsWriter out)
  {
    out.w("fan.${name}.\$pod = fan.sys.Pod.\$add('$name');").nl
    out.w("with (fan.${name}.\$pod)").nl
    out.w("{").nl

    // filter out synthetic types from reflection
    reflect := types.findAll |t| { !t.isSynthetic }

    // write all types first
    reflect.each |t|
    {
      adder  := t.isMixin ? "\$am" : "\$at"
      base   := "$t.base.pod::$t.base.name"
      mixins := t.mixins.join(",") |m| { "'$m.pod::$m.name'" }
      flags  := t->flags
      out.w("  fan.${t.pod}.${t.name}.\$type = $adder('$t.name','$base',[$mixins],$flags);").nl
    }

    // then write slot info
    reflect.each |t|
    {
      if (t.fields.isEmpty && t.methods.isEmpty) return
      //out.w("  \$$i")
      out.w("  fan.${t.pod}.${t.name}.\$type")
      t.fields.each |f| { out.w(".\$af('$f.name',$f.flags,'$f.ftype.sig')") }
      t.methods.each |m| { if (!m.isFieldAccessor) out.w(".\$am('$m.name',$m.flags)") }
      out.w(";").nl
    }
    out.w("}").nl
  }

  Str name           // pod name
  JsType[] types     // types in this pod
  Str:File natives   // natives
}

