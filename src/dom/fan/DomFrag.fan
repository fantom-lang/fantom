//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

**
** DomFrag models a DOM document fragment: a parentless container
** whose children move into the target when it is added to a node.
**
@NoDoc @Js
class DomFrag : DomNode
{
  ** Create a new empty fragment in the current Doc.
  new make() { _make }

  private native Void _make()
}
