//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

**
** Button displays a push, toggle, check, or radio button with
** text and/or an image.  Buttons can also be used as the
** children of a `ToolBar`.
**
class Button : Widget
{

  **
  ** Callback function when button is pressed or selection is changed.
  **
  ** Event id fired:
  **  - `EventId.action`
  **
  ** Event fields:
  **   - none
  **
  @transient readonly EventListeners onAction := EventListeners()

  **
  ** Button mode defines the style: check, push, radio, or toggle.
  ** If the button is a child of a ToolBar then you can also use
  ** sep; plus radio and toggle mean the same thing.  The default
  ** is push.  This field cannot be changed once the button is
  ** constructed.
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
  native Image image

  **
  ** Font for text. Defaults to null (system default).
  **
  native Font font

  **
  ** Command associated with this button.  Setting the
  ** command automatically maps the text, icon, enable state,
  ** and eventing to the command.
  **
  Command command
  {
    set
    {
      @command?.unregister(this)
      @command = val
      if (val != null)
      {
        enabled  = val.enabled
        text     = val.name
        image    = val.icon
        onAction.add |Event e| { val.invoke(e) }
        val.register(this)
      }
    }
  }

}