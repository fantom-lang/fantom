//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using web

**
** Renders DocType documents
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
class DocTypeRenderer : DocRenderer
{

//////////////////////////////////////////////////////////////////////////
// TypeRenderer
//////////////////////////////////////////////////////////////////////////

  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out, DocType doc)
    : super(env, out, doc)
  {
    this.type = doc
  }

  ** Type to renderer
  const DocType type

  ** Pod for type
  DocPod pod() { type.pod }

  override Void writeContent()
  {
    out.div("class='mainSidebar'")
      out.div("class='main type'")
        writeTypeOverview
        writeSlots
      out.divEnd
      out.div("class='sidebar'")
        writeToc
      out.divEnd
    out.divEnd
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
    writeSrcLink(type.doc.loc)

    // fandoc
    writeFandoc(type.doc, pod.format)

    // enum vals
    if (DocFlags.isEnum(type.flags))
    {
      out.ul
      type.declared.each |s|
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
    writeSrcLink(slot.doc.loc)
    writeFandoc(slot.doc, pod.format)
    out.ddEnd
  }

  ** Render HTML for slot signature.
  virtual Void writeSlotSig(DocSlot slot)
  {
    out.p("class='sig'").code
    slot.facets.each |f| { writeFacet(f); out.br }
    writeSlotSigText(slot)
    out.codeEnd.pEnd
  }

  ** Render slot signature inside the outer p element.
  ** This does *not* include facets, but does include signature links.
  @NoDoc Void writeSlotSigText(DocSlot slot)
  {
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
      if (DocFlags.isCtor(method.flags))
      {
        if (DocFlags.isStatic(method.flags)) out.w("static ")
        out.w("new")
      }
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
  }

//////////////////////////////////////////////////////////////////////////
// Toc
//////////////////////////////////////////////////////////////////////////

  ** Render the table of contents for this type.
  virtual Void writeToc()
  {
    // source link
    out.h3.w("Source").h3End
    out.ul.li
    srcLink := toSrcLink(type.doc.loc, "View Source")
    if (srcLink == null)
      out.w("Not available")
    else
      writeLink(srcLink)
    out.liEnd.ulEnd

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
    writeTypeRefHtml(out, ref, full) |x->Uri| { typeRefToHref(x) }
  }

  ** Static utility to write a DocTypeRef as HTML with anchor links.
  ** The 'toHref' maps a basic (non-parameterized) type ref to its href URI.
  static Void writeTypeRefHtml(WebOutStream out, DocTypeRef ref, Bool full, |DocTypeRef->Uri| toHref)
  {
    if (ref.isParameterized)
    {
      switch (ref.qname)
      {
        case "sys::List":
          writeTypeRefHtml(out, ref.v, false, toHref)
          out.w("[]")
        case "sys::Map":
          if (ref.isNullable) out.w("[")
          writeTypeRefHtml(out, ref.k, false, toHref)
          out.w(":")
          writeTypeRefHtml(out, ref.v, false, toHref)
          if (ref.isNullable) out.w("]")
        case "sys::Func":
          isVoid := ref.funcReturn.qname == "sys::Void"
          out.w("|")
          ref.funcParams.each |p, i| { if (i > 0) out.w(","); writeTypeRefHtml(out, p, false, toHref) }
          if (!isVoid || ref.funcParams.isEmpty)
          { out.w("->"); writeTypeRefHtml(out, ref.funcReturn, false, toHref) }
          out.w("|")
        default:
          throw Err("Unsupported parameterized type: $ref")
      }
      if (ref.isNullable) out.w("?")
    }
    else if (ref.isGenericVar)
    {
      out.w(full ? ref.qname : ref.name)
         .w(ref.isNullable ? "?" : "")
    }
    else
    {
      out.a(toHref(ref))
         .w(full ? ref.qname : ref.name)
         .w(ref.isNullable ? "?" : "")
         .aEnd
    }
  }

  ** Make type ref href URI by hand to avoid having to resolve
  ** every tyep to a full fledge Doc instance
  private Uri typeRefToHref(DocTypeRef r)
  {
    s := StrBuf()
    if (r.pod != type.pod.name) s.add("../").add(r.pod).add("/")
    s.add(r.name)
    uriExt := env.linkUriExt
    if (uriExt != null) s.add(uriExt)
    return s.toStr.toUri
  }

  ** Write the given facet.
  virtual Void writeFacet(DocFacet f)
  {
    out.code("class='sig'")
    writeFacetText(f)
    out.codeEnd
  }

  ** Write the facet content inside the outer code element
  ** which includes links to the facet type and body values.
  @NoDoc Void writeFacetText(DocFacet f)
  {
    out.w("@")
    writeTypeRef(f.type)
    if (f.fields.size > 0)
    {
      s := f.fields.join("; ") |v,n| { "$n.toXml=$v.toXml" }
      out.w(" { $s }")
    }
  }

  ** Map filename/line number to a source file link
  DocLink? toSrcLink(DocLoc loc, Str dis)
  {
    src := type.pod.src(loc.file, false)
    if (src == null) return null
    frag := loc.line > 20 ? "line${loc.line}" : null
    return DocLink(doc, src, dis, frag)
  }

  ** Write source code link as <p> if source is available.
  virtual Void writeSrcLink(DocLoc loc, Str dis := "Source")
  {
    link := toSrcLink(loc, dis)
    if (link == null) return
    out.p("class='src'")
    writeLink(link)
    out.pEnd
  }

}

