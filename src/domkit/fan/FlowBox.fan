//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 2015  Andy Frank  Creation
//

using dom

**
** FlowBox lays out its children in a one-directional flow.
**
** See also: [pod doc]`pod-doc#flowBox`
**
@Js class FlowBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-FlowBox")
  }

  ** How to align children inside container.  Valid values
  ** are 'left', 'center', 'right'.
  Align halign := Align.left
  {
    set { &halign=it; style->textAlign=it.toStr }
  }

  ** Gaps to insert between child elements.  If 'gaps.length' is less
  ** than the number of children, then 'gaps' will be cycled to
  ** apply to all children.
  Str[] gaps := Str[,]

  protected override Void onAdd(Elem c)    { applyStyle }
  protected override Void onRemove(Elem c) { applyStyle }

  private Void applyStyle()
  {
    kids := children
    text := kids.any |kid| { kid is TextField }

    kids.each |kid,i|
    {
      // add gap
      gap := 0
      if (gaps.size > 0)
      {
        s := gaps[i % gaps.size]
        gap = s[0..-3].toInt
        if (gap > 0 && i < kids.size-1) kid.style["margin-right"] = s
      }

      // add join classes
      // TODO FIXIT: more optimized way than toggling classes on each add/remove?
      if (kids.size > 1 && gap == -1)
      {
        // TODO: be nice to do purely in CSS
        if (text) kid.style.addClass("domkit-group-textfield")

        if (i == 0) kid.style.addClass("domkit-group-left")
        else if (i < kids.size-1) kid.style.removeClass("domkit-group-right").addClass("domkit-group-middle")
        else kid.style.addClass("domkit-group-right")
      }
    }
  }
}