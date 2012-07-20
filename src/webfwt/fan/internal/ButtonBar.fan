//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jun 10  Andy Frank  Creation
//

using gfx
using fwt

**
** ButtonBar displays buttons flush against a background.
**
@NoDoc
@Js
// TODO: leave as internal until needed
internal class ButtonBar : ContentPane
{
  ** Construct new ButtonBar.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  ** Add a button.
  This addButton(Image image, |fwt::Event| onAction)
  {
    b := BorderPane
    {
      it.insets = Insets(2,4)
      it.border = Border("0,1,0,0 #bebebe")
      it.onMouseDown.add |e| { e.widget->bg=Color("#d5d5d5"); e.widget.relayout }
      it.onMouseUp.add   |e| { e.widget->bg=null; e.widget.relayout; onAction(e) }
      Label { it.image=image },
    }
    buttons.add(b)
    return this
  }

  ** Layout widget.
  override Void onLayout()
  {
    // detach buttons
    buttons.each |b| { b.parent?.remove(b) }

    // rebuild grid
    grid := GridPane { hgap=0; numCols=buttons.size }
    buttons.each |b| { grid.add(b) }
    content = BorderPane
    {
      bg = Gradient("0% 0%, 0% 100%, #fbfbfb, #f4f4f4 0.5, #e5e5e5 0.5, #e6e6e6")
      grid,
    }

    // finish layout
    super.onLayout
  }

  private Widget[] buttons := Widget[,]

}