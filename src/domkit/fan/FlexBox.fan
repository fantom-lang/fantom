//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using dom

**
** FlexBox lays out child elements based on the CSS Flexbox Layout module, which
** primarily lays out items along a single axis (the main axis).  Alignment can
** also be specified for the opposite axis (the cross axis).
**
** See also: [pod doc]`pod-doc#flexBox`
**
@Js class FlexBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-FlexBox")
  }

  **
  ** Direction of the main axis to layout child items:
  **   - "row": layout children left to right
  **   - "column": layout childrent top to bottom
  **
  Str dir := "row"

  **
  ** Define how items are wrapped when content cannot  fit in a
  ** single line/column:
  **   - "nowrap": do not wrap; items are clipped
  **   - "wrap: wrap items onto the next line or column
  **
  Str wrap := "nowrap"

  **
  ** Define child alignment along main axis:
  **
  **   - "flex-start": items are packed toward start of line
  **   - "flex-end": items are packed toward end of line
  **   - "center": items are centered along the line
  **   - "space-between": extra space is evenly distributed between items
  **   - "space-around": extra space is evenly distributed around items
  **
  Str alignMain := "flex-start"

  **
  ** Define child alignment along cross axis:
  **
  **   - "flex-start": items are aligned to top of cross axis
  **   - "flex-end": items are aligned to bottom of cross axis
  **   - "center": items are centered along cross axis
  **   - "baseline": items are aligned so baselines match
  **   - "stretch": stretch items to fill container
  **
  Str alignCross := "center"

  **
  ** Define how multiple lines of content are aligned when extra space
  ** exists in the cross axis:
  **
  **   - "flex-start": lines are packed to top of cross axis
  **   - "flex-end": lines are packed to bottom of cross axis
  **   - "center": lines are packed along center of cross axis
  **   - "space-around": extra space is evenly divided between lines
  **   - "space-between": extra space is evenly divided around lines
  **   - "stretch": stretch lines to fill container
  **
  ** This value has no effect for single line layouts.
  **
  Str alignLines := "stretch"

  **
  ** Convenience to configure the shorthand 'flex' values outside
  ** of child items, where the list position maps to the index of
  ** the child node. Any value here will override the value specified
  ** in the child.
  **
  Str[] flex := [,]

  protected override Void onParent(Elem p) { applyStyle }
  protected override Void onAdd(Elem c)    { applyStyle }
  protected override Void onRemove(Elem c) { applyStyle }

  private Void applyStyle()
  {
    style.setAll([
      "flex-direction":  dir,
      "flex-wrap":       wrap,
      "justify-content": alignMain,
      "align-items":     alignCross,
      "align-content":   alignLines,
    ])

    children.each |kid,i|
    {
      f := flex.getSafe(i)
      if (f != null) kid.style->flex = f
      if (kid is Box)
      {
        if (dir == "row" && kid.style.effective("width") == "100%") kid.style->width  = "auto"
        else if (dir == "column" && kid.style.effective("height") == "100%") kid.style->height = "auto"
      }
    }
  }
}