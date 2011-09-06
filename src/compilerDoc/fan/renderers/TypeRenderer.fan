//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web

**
** TypeRenderer renders the API of a Fantom type modeled via `DocType`.
**
** Overview
** ========
**
**   <h1>
**    <span>{type.flags}</span> {type.qname}
**   </h1>
**   <pre>...</pre>                 // inhertiance
**   <p class='facets'>...</p>      // facet list (if available)
**   <p class='src'><a>...</a></p>  // source link (if available)
**   ...                            // type fandoc
**   <ul>...</ul>                   // emum list (if available)
**
** Slots
** =====
**
**   <dl>
**    <dt id='{slot.name}'>{slot.name}</dt>
**    <dd>
**     <p class='sig'><code>...</code></p>  // slot signature
**     <p class='src'><a>...</a></p>        // source link (if available)
**     ...                                  // slot fandoc
**    </dd>
**   </dl>
**
** Table of Contents
** ==================
**
**   <h3>Source</h3>
**   <ul><li><a>...</a></li></ul>     // if source link
**   <ul><li>Not available</li></ul>  // if no source link
**
**   <h3>Slots</h3>
**   <ul>
**    <li><a href='#{slot.name}'>{slot.name}</a></li>
**   </ul>
**
class TypeRenderer : DocRenderer
{

//////////////////////////////////////////////////////////////////////////
// TypeRenderer
//////////////////////////////////////////////////////////////////////////

  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out, DocType type)
    : super(env, out)
  {
    this.type = type
    this.pod  = env.pod(type.pod)
  }

  ** Type to renderer
  const DocType type

  ** Pod for type
  DocPod pod { private set }

  ** Render the HTML for the DocType referened by `type` field.
  virtual Void writeType()
  {
    writeTypeOverview
    writeSlots
  }

//////////////////////////////////////////////////////////////////////////
// Overview
//////////////////////////////////////////////////////////////////////////

  **
  ** Render the HTML for the type overview (base, mixins, type doc)
  **
  virtual Void writeTypeOverview()
  {
    // type name
    out.h1
      .span.w(DocFlags.toTypeDis(type.flags)).spanEnd
      .w(" $type.qname")
      .h1End

    // inheritance
    writeTypeInheritance

    // facets
    if (type.facets.size > 0)
    {
      out.p("class='facets'")
      type.facets.each |f| { writeFacet(f); out.br }
      out.pEnd
    }

    // if source if available
    writeSourceLink(type.doc.loc)

    // fandoc
    writeFandoc(type, type.doc)

    // enum vals
    if (DocFlags.isEnum(type.flags))
    {
      out.ul
      type.slots.each |s|
      {
        if (DocFlags.isEnum(s.flags))
          out.li.a(`#$s.name`).esc(s.name).aEnd.liEnd
      }
      out.ulEnd
    }
  }

  ** Render type inheritance.
  virtual Void writeTypeInheritance()
  {
    out.pre
    indent := 0
    type.base.eachr |ref|
    {
      if (indent > 0) out.w("\n${Str.spaces(indent*2)}")
      writeTypeRef(ref, true)
      indent++
    }
    if (type.base.size > 0) out.w("\n${Str.spaces(indent*2)}")
    out.w("$type.qname")
    type.mixins.each |ref,i|
    {
      out.w(i==0 ? " : " : ", ")
      writeTypeRef(ref, true)
    }
    out.preEnd
  }

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

  ** Render the HTML for all the slot definitions
  virtual Void writeSlots()
  {
    out.dl
    type.slots.each |slot| { writeSlot(slot) }
    out.dlEnd
  }

  ** Render the HTML for all the given slot
  virtual Void writeSlot(DocSlot slot)
  {
    out.dt("id='$slot.name'").w("$slot.name").dtEnd
    out.dd
    writeSlotSig(slot)
    writeSourceLink(slot.doc.loc)
    writeFandoc(type, slot.doc)
    out.ddEnd
  }

  ** Render HTML for slot signature.
  virtual Void writeSlotSig(DocSlot slot)
  {
    out.p("class='sig'").code
    slot.facets.each |f| { writeFacet(f); out.br }

    if (slot is DocField)
    {
      // field sig
      field := (DocField)slot
      out.w(DocFlags.toSlotDis(field.flags)).w(" ")
      writeTypeRef(field.type)
      out.w(" ").w(field.name)
      if (field.init != null) out.w(" := ").w(field.init.toXml)

      // field setter if different protection scope
      if (field.setterFlags != null)
        out.w(" { ").w(DocFlags.toSlotDis(field.setterFlags)).w(" set }")
    }
    else
    {
      //  method sig
      method := (DocMethod)slot
      if (DocFlags.isCtor(method.flags)) out.w("new")
      else
      {
        out.w(DocFlags.toSlotDis(method.flags)).w(" ")
        writeTypeRef(method.returns)
      }
      out.w(" $method.name(")
      method.params.each |param, i|
      {
        if (i > 0) out.w(", ")
        writeTypeRef(param.type)
        out.w(" $param.name")
        if (param.def != null) out.w(" := $param.def.toXml")
      }
      out.w(")")
    }

    out.codeEnd.pEnd
  }

//////////////////////////////////////////////////////////////////////////
// Toc
//////////////////////////////////////////////////////////////////////////

  ** Render the table of contents for this type.
  virtual Void writeToc()
  {
    // source link
    out.h3.w("Source").h3End
    out.ul
    loc := type.doc.loc
    src := pod.source(loc.file, false)
    if (src == null)
      out.li.w("Not available").liEnd
    else
      out.li.a(`src-${src.name}.html#line$loc.line`).w("View Source").aEnd.liEnd
    out.ulEnd

    // slot list
    out.h3.w("Slots").h3End
    out.ul
    type.slots.each |slot|
    {
      out.li.a(`#$slot.name`).w(slot.name).aEnd.liEnd
    }
    out.ulEnd
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  ** Write the given type ref as a hyperlink
  virtual Void writeTypeRef(DocTypeRef ref, Bool full := false)
  {
    if (ref.isParameterized)
    {
      if (ref.qname == "sys::List")
      {
        writeTypeRef(ref.v)
        out.w("[]")
      }
      else if (ref.qname == "sys::Map")
      {
        if (ref.isNullable) out.w("[")
        writeTypeRef(ref.k)
        out.w(":")
        writeTypeRef(ref.v)
        if (ref.isNullable) out.w("]")
      }
      else if (ref.qname == "sys::Func")
      {
        isVoid := ref.funcReturn.qname == "sys::Void"
        out.w("|")
        ref.funcParams.each |p, i|
        {
          if (i > 0) out.w(",")
          writeTypeRef(p)
        }
        if (!isVoid || ref.funcParams.isEmpty)
        {
          out.w("->")
          writeTypeRef(ref.funcReturn)
        }
        out.w("|")
      }
      else throw Err("Unsupported parameterized type: $ref")
      if (ref.isNullable) out.w("?")
    }
    else
    {
      uri := StrBuf()
      if (ref.pod != type.pod) uri.add("../").add(ref.pod).add("/")
      uri.add(ref.name).add(".html")

      out.a(uri.toStr.toUri)
         .w(full ? ref.qname : ref.name)
         .w(ref.isNullable ? "?" : "")
         .aEnd
    }
  }

  ** Write the given facet.
  virtual Void writeFacet(DocFacet f)
  {
    out.code("class='sig'")
    out.w("@")
    writeTypeRef(f.type)
    if (f.fields.size > 0)
    {
      s := f.fields.join("; ") |v,n| { "$n.toXml=$v.toXml" }
      out.w(" { $s }")
    }
    out.codeEnd
  }

  ** Write source code link if source is available. Return
  ** true if source is available.
  virtual Void writeSourceLink(DocLoc loc)
  {
    uri := sourceLink(pod, loc)
    if (uri == null) return
    out.p("class='src'").a(uri).w("Source").aEnd.pEnd
  }
}

