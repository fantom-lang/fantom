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
  ** Get the parent of this node or null if unmounted.
  **
  XNode? parent { internal set }

  **
  ** Write this node to the output stream.
  **
  abstract Void write(OutStream out)

}

