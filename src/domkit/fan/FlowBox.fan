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
** See also: [docDomkit]`docDomkit::Layout#flowBox`
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
  {
    set { &gaps=it; applyStyle }
  }

  protected override Void onAdd(Elem c)    { applyStyle }
  protected override Void onRemove(Elem c) { applyStyle }

  private Void applyStyle()
  {
    kids := children
    text := kids.any |kid| { kid is TextField }

    Float? lastGap
    kids.each |kid,i|
    {
      // add gap
      gap := 0f
      if (gaps.size > 0)
      {
        s := gaps[i % gaps.size]
        gap = CssDim(s).val.toFloat
        if (gap > 0f && i < kids.size-1) kid.style["margin-right"] = s
      }

      // check width
      if (kid.style.effective("width") == "100%") kid.style->width = "auto"

      // add join classes
      // TODO FIXIT: more optimized way than toggling classes on each add/remove?
      if (kids.size > 1 && (gap == -1f || lastGap == -1f))
      {
        if (i == 0 || lastGap >= 0f)
          kid.style.addClass("group-left")
        else if (i < kids.size-1 && gap == -1f)
          kid.style.removeClass("group-right").addClass("group-middle")
        else
          kid.style.addClass("group-right")
      }

      lastGap = gap
    }
  }
}