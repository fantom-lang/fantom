//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using gfx

**
** Button displays a push, toggle, check, or radio button with
** text and/or an image.  Buttons can also be used as the
** children of a `ToolBar`.
**
@Js
@Serializable
class Button : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Make a button the specified command.
  **
  new makeCommand(Command c, |This|? f := null)
  {
    if (f != null) f(this)
    mode = c.mode.toButtonMode
    command = c
  }

  **
  ** Callback function when button is pressed or selection is changed.
  **
  ** Event id fired:
  **  - `EventId.action`
  **
  ** Event fields:
  **   - none
  **
  once EventListeners onAction() { EventListeners() }

  **
  ** Button mode defines the style: check, push, radio, or toggle.
  ** If the button is a child of a ToolBar then you can also use
  ** sep and check/toggle have same behavior.  Radio buttons are grouped
  ** by separator in a ToolBar.  The default is push.  This field
  ** cannot be changed once the button is constructed.
  **
  const ButtonMode mode := ButtonMode.push

  **
  ** The button's selection state (if check, radio, or toggle).
  ** Defaults to false.
  **
  native Bool selected

  **
  ** Text of the button. Defaults to "".
  **
  native Str text

  **
  ** Image to display on button. Defaults to null.
  **
  native Image? image

  **
  ** Font for text. Defaults to null (system default).
  **
  native Font? font

  **
  ** Insets to apply for padding between the button's border
  ** and its image and text.  Insets are only applied to push and
  ** toggle butttons; they are not applied to checks, radio, sep, or
  ** toolbar buttons.
  **
  const Insets insets := defInsets
  private const static Insets defInsets := Insets(0, 4, 0, 4)

  **
  ** Command associated with this button.  Setting the
  ** command automatically maps the text, icon, enable state,
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
        enabled  = newVal.enabled
        text     = newVal.name
        image    = newVal.icon
        selected = newVal.selected
        onAction.add |Event e|
        {
          newVal.selected = this.selected
          newVal.invoke(e)
        }
        newVal.register(this)
      }
    }
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pref := super.prefSize(hints)
    if (mode === ButtonMode.push || mode === ButtonMode.toggle)
    {
      i := this.insets
      pref = Size(i.left + pref.w + i.right, i.top + pref.h + i.bottom)
    }
    return pref
  }

}