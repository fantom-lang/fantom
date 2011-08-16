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
  }

  ** Type to renderer
  const DocType type

  ** Render the HTML for the DocType referened by `type` field.
  virtual Void writeType()
  {
    writeStart(type.qname)
    out.p.a(`../index.html`).w("Home").aEnd
      .w(" > ").a(`index.html`).w(type.pod).aEnd
      .w(" > ").a(`${type.name}.html`).w(type.name).aEnd
      .pEnd.hr
    writeTypeOverview
    writeSlots
    writeEnd
  }

//////////////////////////////////////////////////////////////////////////
// Overview
//////////////////////////////////////////////////////////////////////////

  ** Render the HTML for the type overview (base, mixins, type doc)
  virtual Void writeTypeOverview()
  {
    // type name
    out.h2.w(DocFlags.toTypeDis(type.flags)).h2End
    out.h1.w("$type.qname").h1End
    writeTypeInheritance

    // facets
    out.p("class='todo'").w("TODO: facets").pEnd

    // fandoc
    writeFandoc(type, type.doc)
  }

  ** Render type inheritance.
  virtual Void writeTypeInheritance()
  {
    chain := DocTypeRef[,]
    base  := type.base
    while (base != null)
    {
      chain.insert(0, base)
      // TODO FIXIT: DocTypeRef.base field
      //base = base.base
      base = null
    }
    out.pre
    chain.each |ref,i|
    {
      if (i > 0) out.w("\n${Str.spaces(i*2)}")
      writeTypeRef(ref, true)
    }
    if (chain.size > 0) out.w("\n${Str.spaces(chain.size*2)}")
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
    writeFandoc(type, slot.doc)
    out.ddEnd
  }

  ** Render HTML for slot signature.
  virtual Void writeSlotSig(DocSlot slot)
  {
    out.p.code("class='sig'")
    out.printLine("TODO: facets").br

    if (slot is DocField)
    {
      field := (DocField)slot
      out.w(DocFlags.toSlotDis(field.flags)).w(" ")
      writeTypeRef(field.type)
      out.w(" ").w(field.name)
      if (field.init != null) out.w(" := ").w(field.init.toXml)
    }
    else
    {
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
// Util
//////////////////////////////////////////////////////////////////////////

  ** Write the given type ref as a hyperlink
  virtual Void writeTypeRef(DocTypeRef ref, Bool full := false)
  {
    // TODO
    uri := StrBuf()
    if (ref.pod != type.pod) uri.add("../").add(ref.pod).add("/")
    uri.add(ref.name).add(".html")

    dis := ref.isParameterized ? ref.signature : (full ? ref.qname : ref.name)

    out.a(uri.toStr.toUri).w(dis).aEnd
  }
}

