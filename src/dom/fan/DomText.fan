//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

**
** DomText models a DOM text node.  Setting its [text] replaces
** just this node's text without touching its siblings.
**
@Js
class DomText : DomNode
{
  ** Create a new text node in the current Doc.
  new make(Str text := "") { _make(text) }

  private native Void _make(Str text)
}
