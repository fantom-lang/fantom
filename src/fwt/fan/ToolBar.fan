//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** ToolBar contains a bar of Button children.
**
@Js
@Serializable { collection = true }
class ToolBar : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Horizontal or veritical configuration.  Defaults
  ** to horizontal.  Must be set at construction time.
  **
  const Orientation orientation := Orientation.horizontal

  // to force native peer
  private native Void dummyToolBar()

  **
  ** Add a button to the toolbar for the specified command.
  ** Default implementation is to add a button with only an
  ** icon and no text.
  **
  Button addCommand(Command c)
  {
    button := Button.makeCommand(c)
    if (c.icon != null) button.text = ""
    add(button)
    return button
  }

  **
  ** Add a separator to the toolbar.
  **
  Void addSep()
  {
    button := Button
    {
      mode = ButtonMode.sep
    }
    add(button)
  }

}