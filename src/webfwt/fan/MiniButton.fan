//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 09  Andy Frank  Creation
//

using fwt
using gfx

**
** MiniButton.
**
@Js
class MiniButton : Pane
{

  **
  ** Constructor
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Text for button.  Defaults to "".
  **
  native Str text

  **
  ** Callback function when button is pressed or selection is changed.
  **
  ** Event id fired:
  **  - `fwt::EventId.action`
  **
  ** Event fields:
  **   - none
  **
  @Transient EventListeners onAction := EventListeners() { private set }

  override native Size prefSize(Hints hints := Hints.defVal)
  override Void onLayout() {}

  **
  ** Command associated with this button.  Setting the
  ** command automatically maps the text, enable state,
  ** and eventing to the command.
  **
  Command? command
  {
    set
    {
      newVal := it
      this.&command?.unregister(this)
      this.&command = newVal
      if (newVal != null)
      {
        enabled = newVal.enabled
        text    = newVal.name
        onAction.add |e| { newVal.invoke(e) }
        newVal.register(this)
      }
    }
  }
}

