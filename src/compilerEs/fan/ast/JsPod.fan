//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 May 2023  Matthew Giannini Creation
//

using compiler

**
** JsPod
**
class JsPod : JsNode
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(CompileEsPlugin plugin) : super(plugin)
  {
    this.pod = plugin.pod

    // map native files by name
    baseDir := c.input.baseDir
    c.jsFiles?.each |f| {
      // get the relative uri to this js file from the baseDir.
      // For example, consider pod "podName" in this location:
      //   /path/to/podName/js/Foo.js
      // The baseDir is /path/to/podName/
      // When we relativie it it becomes js/Foo.js
      // We then strip the first directory from the path and change it to es.
      // Therefore we look for the file in /path/to/podName/es/Foo.js
      //
      // This supports deeper paths also:
      //   /path/to/podName/js/dir1/Bar.js => /path/to/podname/es/dir1/Bar.js
      relUri := f.uri.relTo(baseDir.uri)[1..-1]
      esFile := baseDir.plus(`es/${relUri}`)
      if (esFile.exists)
        natives[f.name] = esFile
    }

    // find types to emit
    c.types.findAll { isJsType(it) }.each { types.add(JsType(plugin, it)) }
  }

  private PodDef pod
  private JsType[] types := [,]
  private [Str:File] natives := [:]
  private [Str:Bool] peers := [:]{ it.def = false }

//////////////////////////////////////////////////////////////////////////
// JsPod
//////////////////////////////////////////////////////////////////////////

  override Void write()
  {
    writeRequire
    writeTypes
    writeTypeInfo
    writeProps
    writeClosureFields
    writeNatives
    writeExports
    js.wl("}).call(this);")
  }

  private Void writeRequire()
  {
    js.wl("// cjs require begin")
    CommonJs.moduleStart.splitLines.each |line| { js.wl(line) }

    js.wl("const fan = __require('fan.js');")
    js.wl("const fantom = __require('fantom.js');")
    js.wl("const sys = fantom ? fantom.sys : __require('sys.js');")

    // we need to require full dependency chain
    pods := (CPod[])pod.depends.mapNotNull |p->CPod?|
    {
      if (p.name.startsWith("[java]")) return null
      return c.ns.resolvePod(p.name, null)
    }
    c.ns.flattenAndOrderByDepends(pods).each |depend|
    {
      if (depend.name == "sys") return
      if (!c.ns.resolvePod(depend.name, null).hasJs && !c.input.forceJs) return
      // NOTE if we change sys to fan we need to update JNode.qnameToJs
      // js.wl("import * as ${depend.name} from './${depend.name}.js';")
      js.wl("const ${plugin.podAlias(depend.name)} = __require('${depend.name}.js');")
    }

    js.wl("// cjs require end")
    js.wl("const js = (typeof window !== 'undefined') ? window : global;")
  }

  private Void writeTypes()
  {
    types.each |JsType t|
    {
      plugin.curType = t.def
      if (t.def.isNative) writePeer(t, null)
      else
      {
        t.write
        if (t.hasNatives) writePeer(t, t.peer)
      }
      js.nl
      plugin.curType = null
    }
  }

  private Void writePeer(JsType t, CType? peer)
  {
    key := "${t.name}.js"
    if (peer != null)
    {
      key = "${peer.name}Peer.js"
      this.peers[t.name] = true
    }

    file := natives.remove(key)
    if (file == null || !file.exists)
    {
      warn("Missing native impl for ${t.def.signature}", Loc("${t.name}.fan"))
      // Do not export peer types that we don't have implementations for
      this.peers[t.name] = false
    }
    else
    {
      in := file.in
      js.minify(in)
    }
  }

  private Void writeTypeInfo()
  {
    // add the pod to the type system
    js.wl("const p = sys.Pod.add\$('${pod.name}');")
    js.wl("const xp = sys.Param.noParams\$();")
    // general use map variable
    js.wl("let m;")

    // filter out synthetic types from reflection
    reflect := types.findAll |t| { !t.def.isSynthetic }

    // write all types first
    reflect.each |t|
    {
      adder := t.def.isMixin ? "p.am\$" : "p.at\$"
      base  := "${t.base.pod}::${t.base.name}"
      mixins := t.mixins.join(",") |m| { "'${m.pod}::${m.name}'" }
      facets := toFacets(t.facets)
      flags  := t.def.flags
      js.wl("${t.name}.type\$ = ${adder}('${t.name}','${base}',[${mixins}],{${facets}},${flags},${t.name});")
    }

    // then write slot info
    reflect.each |JsType t|
    {
      if (t.fields.isEmpty && t.methods.isEmpty) return
      js.w("${t.name}.type\$")
      t.fields.each |FieldDef f|
      {
        // don't write for FFI
        if (f.isForeign || f.type.isForeign) return

        facets := toFacets(f.facets)
        js.w(".af\$('${f.name}',${f->flags},'${f.type.signature}',{${facets}})")
      }
      t.methods.each |MethodDef m|
      {
        if (m.isFieldAccessor) return
        if (m.params.any |CParam p->Bool| { p.type.isForeign }) return
        params := m.params.join(",") |p| { "new sys.Param('${p.name}','${p.type.signature}',${p.hasDefault})"}
        paramList := m.params.isEmpty
          ? "xp"
          : "sys.List.make(sys.Param.type\$,[${params}])"
        facets := toFacets(m.facets)
        js.w(".am\$('${m.name}',${m.flags},'${m.returns.signature}',${paramList},{${facets}})")
      }
      js.wl(";")
    }

    // pod meta
    js.nl.wl("m=sys.Map.make(sys.Str.type\$,sys.Str.type\$);")
    pod.meta.each |v, k|
    {
      js.wl("m.set(${k.toCode}, ${v.toCode});")
    }
    js.wl("p.__meta(m);").nl
  }

  private static Str toFacets(FacetDef[]? facets)
  {
    facets == null ? "" : facets.join(",") |f| { "'${f.type.qname}':${f.serialize.toCode}" }
  }

  private Void writeProps()
  {
    baseDir := c.input.baseDir
    if (baseDir != null)
    {
      c.jsPropsFiles?.each |file|
      {
        if (file.ext != "props") return
        uri   := file.uri.relTo(baseDir.uri)
        key   := "${pod.name}:${uri}"
        try
        {
          props := file.in.readProps
          js.wl("m=sys.Map.make(sys.Str.type\$, sys.Str.type\$);")
          props.each |v,k| { js.wl("m.set(${k.toCode},${v.toCode});") }
          js.wl("sys.Env.cur().__props(${key.toCode}, m);").nl
        }
        catch (ArgErr err)
        {
          // some props files aren't actually valid props files, so we ignore those
          // e.g. they have duplicate keys which is not allowed
          warn("Invalid props file: ${uri}. ${err.msg}")
        }
      }
      js.nl
    }
  }

  private Void writeClosureFields()
  {
    plugin.closureSupport.write
  }

  private Void writeNatives()
  {
    natives.each |f| { js.minify(f.in) }
  }

  private Void writeExports()
  {
    // only export public types
    js.wl("// cjs exports begin")
    js.wl("const __${pod.name} = {").indent
    types.findAll { it.def.isPublic }.each |t| {
      js.wl("${t.name},")
      if (this.peers[t.name]) js.wl("${t.peer.name}Peer,")
    }
    js.unindent.wl("};")
    js.wl("fan.${pod.name} = __${pod.name};")
    js.wl("if (typeof exports !== 'undefined') module.exports = __${pod.name};")
    js.wl("// cjs exports end")
  }
}

