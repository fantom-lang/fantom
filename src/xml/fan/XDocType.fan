//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 Nov 08  Brian Frank  Creation
//

**
** XML document type declaration (but not the whole DTD).
**
class XDocType
{

  **
  ** Element name of of the  document.
  **
  Str rootElem := "undefined"

  **
  ** Public ID of an external DTD or null.
  **
  Str? publicId

  **
  ** System ID of an external DTD or null.
  **
  Uri? systemId

  **
  ** Return string representation of this processing instruction.
  **
  override Str toStr()
  {
    s := StrBuf().add("<!DOCTYPE ").add(rootElem)
    if (publicId != null)
    {
      s.add(" PUBLIC '").add(publicId).add("'")
    }
    if (systemId != null)
    {
      if (publicId == null) s.add(" SYSTEM '")
      else s.add(" '")
      s.add(systemId).add("'")
    }
    s.add(">")
    return s.toStr
  }

}