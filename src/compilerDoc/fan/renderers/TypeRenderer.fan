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
    writeTypeOverview
    writeSlots
    writeEnd
  }

  ** Render the HTML for the type overview (base, mixins, type doc)
  virtual Void writeTypeOverview()
  {
    out.h1.w("type $type.qname").h1End
    writeFandoc(type.doc, type.loc)
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
    out.h3.w(slot.name).h3End
    writeFandoc(slot.doc, slot.loc)
  }


}

