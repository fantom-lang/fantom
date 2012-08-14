//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Oct 10  Andy Frank  Creation
//

using gfx
using fwt

**
** HudPopup displays a Popup in HUD style.
**
@Js
class HudPopup : Popup
{
  ** Constructor.
  new make(|This|? f := null)
  {
    content = BorderPane
    {
      it.bg = Color("#f53b3b3b")
      it.border = Border("#f5242424 $radius")
      it.insets = this.insets
    }
    if (f != null) f(this)
  }

  ** Insets around content.
  Insets insets := Insets(12)
  {
    set { &insets=it; content->insets=it }
  }

  ** Border radius for popup.
  Insets radius := Insets(5)
  {
    set { &radius=it; content->border=Border("#f5242424 $it") }
  }

  ** Content of popup.
  Widget? body
  {
    get { content->content }
    set { content->content = it }
  }

}