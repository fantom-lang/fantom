//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Oct 2011  Andy Frank  Creation
//

using gfx
using fwt

**
** TransitionPane animates a transition between two widgets.
**
@NoDoc
@Js
class TransitionPane : ContentPane
{
  ** It-block constructor.
  new make(|This|? f := null) { if (f != null) f(this) }

  ** Transition style.
  **  - slideUp: slide new widget up from bottom
  **  - flip:    flip over like a card to reveal new widget
  const Str style := "flip"

  ** Duration for transition animation.
  const Duration dur := 500ms

  ** Transition to given widget using current style.
  native Void transitionTo(Widget w)

  ** Meta data for transition animations.
  @NoDoc
  Str:Obj meta := [:]
}