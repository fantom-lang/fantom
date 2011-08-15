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

  ** Render the HTML for the type overview (base, mixins, type doc)
  virtual Void writeTypeOverview()
  {
    out.h1.w("$type.qname").h1End

    // <flags> <name> <base/mixins>
    out.div.code("style='color:green;'")
    out.w(DocFlags.toTypeDis(type.flags)).w(" ").w(type.name)
    if (type.base != null || !type.mixins.isEmpty)
    {
      comma := false
      out.w(" : ")
      if (type.base != null) { writeTypeRef(type.base); comma = true}
      type.mixins.each |m|
      {
        if (comma) out.w(", "); else comma = true
        writeTypeRef(m)
      }
    }
    out.codeEnd.divEnd

    writeFandoc(type, type.doc)
  }

  ** Render the HTML for all the slot definitions
  virtual Void writeSlots()
  {
    out.h1.w("Slots").h1End
    type.slots.each |slot| { writeSlot(slot) }
  }

  ** Render the HTML for all the given slot
  virtual Void writeSlot(DocSlot slot)
  {
    out.hr.h3.w(slot.name).h3End

    // signature
    out.div.code("style='color:green;'")
    out.w(DocFlags.toSlotDis(slot.flags)).w(" ")
    if (slot is DocField)
    {
      field := (DocField)slot
      writeTypeRef(field.type)
      out.w(" ").w(field.name)
      if (field.init != null) out.w(" := ").w(field.init.toXml)
    }
    else
    {
      // method signature
      method := (DocMethod)slot
      writeTypeRef(method.returns)
      out.w(" ").w(method.name).w("(")
      method.params.each |param, i|
      {
        if (i > 0) out.w(", ")
        writeTypeRef(param.type)
        out.w(" ")
        out.w(param.name)
        if (param.def != null) out.w(" := ").w(param.def.toXml)
      }
      out.w(")")
    }
    out.codeEnd.divEnd

    // documentation
    writeFandoc(type, slot.doc)
  }

  ** Write the given type ref as a hyperlink
  virtual Void writeTypeRef(DocTypeRef ref)
  {
    // TODO
    uri := StrBuf()
    if (ref.pod != type.pod) uri.add("../").add(ref.pod).add("/")
    uri.add(ref.name).add(".html")

    dis := ref.isParameterized ? ref.signature : ref.name

    out.a(uri.toStr.toUri).w(dis).aEnd
  }


}

