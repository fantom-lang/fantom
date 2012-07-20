//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Oct 2010  Andy Frank  Creation
//

using fwt
using gfx

**
** TextPane displays a block of pre-formatted text using
** a fixed-width font.
**
@NoDoc
@Js
class TextPane : Pane
{

  ** The text to display.
  native Str text

  ** Scroll to top of text content within the given duration.
  native This scrollToTop(Duration dur := 100ms)

  ** Scroll to bottom of text content within the given duration.
  native This scrollToBottom(Duration dur := 100ms)

  override native Size prefSize(Hints hints := Hints.defVal)
  override Void onLayout() {}

}

