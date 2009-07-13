//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 08  Andy Frank  Creation
//

using gfx

**
** BorderPane provides a callback to use for drawing a custom
** border around a content widget.  You must specifiy non-zero
** insets to leave room to render your border.
**
** TODO: This API is definitely changing to use CSS styling.
**
class BorderPane : Pane
{

  **
  ** The content child widget.
  **
  Widget? content { set { remove(*content); Widget.super.add(val); *content = val } }

  **
  ** If this the first widget added, then assume it the content.
  **
  override This add(Widget? child)
  {
    if (*content == null) *content=child
    super.add(child)
    return this
  }

  **
  ** The callback to paint the custom border.
  ** TODO: this will be replaced with a declarative CSS Border
  **
  |Graphics g, Size size, Insets insets|? onBorder := null

  **
  ** Insets to leave around the edge of the content.
  **
  Insets insets := Insets(0,0,0,0)

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal
    insetSize := insets.toSize
    pref := content.prefSize(hints - insetSize)
    return Size(pref.w + insetSize.w, pref.h + insetSize.h)
  }

  override Void onLayout()
  {
    if (content == null) return
    size := this.size
    content.bounds = Rect(
      insets.left,
      insets.top,
      size.w - insets.left - insets.right,
      size.h - insets.top - insets.bottom)
  }

  internal Void onPaint(Graphics g)
  {
    onBorder?.call(g, size, insets)
  }

  // to force native peer
  private native Void dummyBorderPane()

}

