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
  abstract NodeType nodeType()

  **
  ** Get the parent of this node or null if unmounted.
  **
  XNode? parent { internal set }

  **
  ** Write this node to the output stream.
  **
  abstract Void write(OutStream out)

}

**************************************************************************
** NodeType
**************************************************************************

enum NodeType
{
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