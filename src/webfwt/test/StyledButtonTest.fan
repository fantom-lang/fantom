//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Oct 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** StyledButton
**
@Js
internal class StyledButtonTest : ContentPane
{
  new make()
  {
    content = InsetPane(24)
    {
      GridPane
      {
        vgap = 12
        StyledButton { text("Normal"), },
        StyledButton { mode=ButtonMode.toggle; text("Toggle"), },
        StyledButton { mode=ButtonMode.toggle; selected=true; text("Toggle/Sel"), },
        StyledButton { it.enabled=false; text("Disabled"), },
        BorderPane
        {
          insets = Insets(12)
          bg = Color("#444")
          GridPane
          {
            vgap = 12
            StyledButton.makeHud { text("Normal", Color.white), },
            StyledButton.makeHud { mode=ButtonMode.toggle; text("Toggle", Color.white), },
            StyledButton.makeHud { mode=ButtonMode.toggle; selected=true; text("Toggle/Sel", Color.white), },
            StyledButton.makeHud { it.enabled=false; text("Disabled", Color.white), },
          },
        },
      },
    }
  }

  private Widget text(Str text, Color fg := Color.black)
  {
    Label { it.text=text; it.fg=fg }
  }
}