//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 08  Brian Frank  Creation
//

using gfx

**
** ScrollPane displays a scrollbars to scroll its content child.
** If the ScrollPane is smaller than the preferred size of the
** content child, then scrollbars are shown.  If the ScrollPane is
** bigger than the preferred area, the content child will fill the
** available space.
**
@Js
@Serializable
class ScrollPane : ContentPane
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Horizontal scroll bar.
  **
  @Transient ScrollBar hbar := ScrollBar.makeNative(Orientation.horizontal) { private set }

  **
  ** Vertical scroll bar.
  **
  @Transient ScrollBar vbar := ScrollBar.makeNative(Orientation.vertical) { private set }

  **
  ** Draw a border around the widget.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

  override Void onLayout()
  {
    if (content == null) return
    setMinSize(content.prefSize)
  }

  private native Void setMinSize(Size s)

}