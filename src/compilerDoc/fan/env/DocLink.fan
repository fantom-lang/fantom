//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//   21 Dec 11  Brian Frank  Major redesign
//

using web

**
** DocLink models a link between two documents.
**
** The following link formats are built-in:
**
**    Format             Display     Links To
**    ------             -------     --------
**    pod::index         pod         absolute link to pod index
**    pod::pod-doc       pod         absolute link to pod doc chapter
**    pod::Type          Type        absolute link to type qname
**    pod::Types.slot    Type.slot   absolute link to slot qname
**    pod::Chapter       Chapter     absolute link to book chapter
**    pod::Chapter#frag  Chapter     absolute link to book chapter anchor
**    Type               Type        pod relative link to type
**    Type.slot          Type.slot   pod relative link to slot
**    slot               slot        type relative link to slot
**    Chapter            Chapter     pod relative link to book chapter
**    Chapter#frag       Chapter     pod relative link to chapter anchor
**    #frag              heading     chapter relative link to anchor
**
const class DocLink
{
  ** Construct with from doc, dis text, target document,
  ** and optional fragment identifier
  new make(Doc from, Doc target, Str dis := target.docName, Str? frag := null)
  {
    this.from   = from
    this.target = target
    this.dis    = dis
    this.frag   = frag
  }

  ** Document we are linking from
  const Doc from

  ** Target document
  const Doc target

  ** Display text for the anchor
  const Str dis

  ** Optional fragment in the link document
  const Str? frag

  ** Debug string representation
  override Str toStr()
  {
    "[$dis] $from.docName -> $target.docName" + (frag == null ? "" : "#$frag")
  }
}