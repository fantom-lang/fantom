//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocFacet models the documentation of a `sys::Facet` on a type or slot.
**
const class DocFacet
{

  ** Constructor
  internal new make(DocTypeRef type, Str:Str fields)
  {
    this.type   = type
    this.fields = fields
  }

  ** Type of the facet definition
  const DocTypeRef type

  ** Map of name:expr pairs for field definitions
  const Str:Str fields

  override Str toStr()
  {
    s := StrBuf()
    s.add("@").add(type)
    if (!fields.isEmpty)
    {
      s.add(" {")
      fields.each |v, n| { s.add(" $n=$v;") }
      s.add(" }")
    }
    return s.toStr
  }

  internal static const Str:Str noFields := [:]
}