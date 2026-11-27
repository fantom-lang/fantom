//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 2026  Brian Frank  Creation
//

**
** DomComment models a DOM comment node.  A comment is not drawn and
** is not part of the text of its parent, so it marks a place in the
** tree which nothing else will merge or remove.
**
@NoDoc @Js
class DomComment : DomNode
{
  ** Create a new comment node in the current Doc.
  new make(Str text := "") { _make(text) }

  private native Void _make(Str text)
}
