//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   05 Nov 2024  Matthew Giannini  Creation
//

**
** A link resolver can be used to modify link nodes prior to rendering.
**
@Js
@NoDoc const class LinkResolver
{
  ** Resolve the given `LinkNode`. This will be called prior to any rendering
  ** for the given node and provides an opportunity to modify the link destination,
  ** mark the link as code, and change the link display text.
  virtual Void resolve(LinkNode node) { }
}