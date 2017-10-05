//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 2017  Andy Frank  Creation
//

using dom

**
** WellBox displays content in a recessed well.
**
@Js class WellBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-WellBox")
  }

// TODO: this isn't working right
  ** Return a new 'Elem' merging this 'WellBox' with the given 'header'
  ** element, where 'halign' specifies if 'header' should be left, center,
  ** or right aligned with well.
  @NoDoc Elem mergeHeader(Elem header, Align halign := Align.left)
  {
    // setup header
    header.style->top = "12px"
    header.style->zIndex = "10"
    switch (halign)
    {
      case Align.center: header.style->textAlign = "center"
      case Align.right:  header.style->right = "10px"
      default:           header.style->left  = "10px"
    }

    // setup well
    this.style->paddingTop = "24px"

    // merge elements
    return Box
    {
      it.style->marginTop = "-12px"
      header,
      this,
    }
  }
}