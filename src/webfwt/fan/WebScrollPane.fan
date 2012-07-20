//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 10  Andy Frank  Creation
//

using fwt
using gfx

**
** WebScrollPane provides a scrollable viewport for a content widget.
**
@NoDoc
@Js
class WebScrollPane : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Background color of scroll pane.
  Color bg := Color.white

  ** Border color of scroll pane, or null for default.
  Color? border

  ** Scroll policy for horizontal scrollbar.
  Int hpolicy := WebScrollPane.off

  ** Scroll policy for vertical scrollbar.
  Int vpolicy := WebScrollPane.auto

//////////////////////////////////////////////////////////////////////////
// Policy Constants
//////////////////////////////////////////////////////////////////////////

  ** Never display the scrollbar.
  static const Int off := 0

  ** Always display the scrollbar.
  static const Int on := 1

  ** Only display scrollbar when needed.
  static const Int auto := 2

//////////////////////////////////////////////////////////////////////////
// Scrolling
//////////////////////////////////////////////////////////////////////////

  ** Horizontal scroll offset.
  native Int scrollX()

  ** Vertical scroll offset.
  native Int scrollY()

  ** Scroll to the top of the content.
  native Void scrollToTop()

  ** Scroll to the bottom of the content.
  native Void scrollToBottom()

  ** Scroll to the left-most point of the content.
  native Void scrollToLeft()

  ** Scroll to the right-most point of the content.
  native Void scrollToRight()

  ** Callback when content is scrolled.
  **   - Event.pos: 'scrollX' and 'scrollY'.
  once EventListeners onScroll() { EventListeners() }

//////////////////////////////////////////////////////////////////////////
// Pane
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if (content == null) return Size.defVal

    // +2 accounts for CSS border - see peer
    pref := content.prefSize(hints)
    return Size(pref.w+2, pref.h+2)
  }

  override Void onLayout()
  {
    if (content == null) return

    // -2 accounts for CSS border - see peer
    // -10 accounts for scrollbar when present - see peer

    if (hpolicy != off && vpolicy != off)
    {
      // both
      pref := content.prefSize
      w := (size.w-2).max(pref.w)
      h := (size.h-2).max(pref.h)
      if (w > size.w || hpolicy == on) h -= 10
      if (h > size.h || vpolicy == on) w -= 10
      content.bounds = Rect(0, 0, w, h)
    }
    else if (hpolicy != off)
    {
      // horiz only
      pref := content.prefSize
      w := (size.w-2).max(pref.w)
      h := size.h-2
      if (w > size.w || hpolicy == on) h -= 10
      content.bounds = Rect(0, 0, w, h)
    }
    else
    {
      // vert only
      pref := content.prefSize
      w := size.w-2
      h := (size.h-2).max(pref.h)
      if (h > size.h || vpolicy == on) w -= 10
      content.bounds = Rect(0, 0, w, h)
    }
  }

  // force native
  private native Void dummy()
}