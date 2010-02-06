//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    7 Nov 08  Brian Frank  Creation
//

**
** XNode is the base class for `XElem` and `XText`.
**
abstract class XNode
{

  **
  ** Return the node type enum.  Note that XElem always
  ** returns 'elem', but that during pull parsing XParser
  ** will return 'elemStart' and 'elemEnd'.
  **
  abstract XNodeType nodeType()

  **
  ** Get the root document node or null if this node is
  ** not mounted under a XDoc instance.
  **
  XDoc? doc()
  {
    for (XNode? x := this; x != null; x = x.parent)
      if (x is XDoc) return x
    return null
  }

  **
  ** Get the parent of this node or null if unmounted.
  **
  XNode? parent { internal set }

  **
  ** Conveniece to `write` to an in-memory string.
  **
  Str writeToStr()
  {
    s := StrBuf()
    write(s.out)
    return s.toStr
  }

  **
  ** Write this node to the output stream.
  **
  abstract Void write(OutStream out)

}

**************************************************************************
** XNodeType
**************************************************************************

**
** Enumerates the type of `XNode` and current node of `XParser`.
**
enum class XNodeType
{
  ** Document node type by `XDoc.nodeType`
  doc,

  ** Element node type returned by `XElem.nodeType`
  elem,

  ** Text node type returned by `XText.nodeType`
  text,

  ** Processing instruction node type returned by `XPi.nodeType`
  pi,

  ** Start of element used by XParser when pull parsing.
  elemStart,

  ** End of element used by XParser when pull parsing.
  elemEnd
}