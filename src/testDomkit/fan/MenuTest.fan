//
// Copyright (c) 2018, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 2018  Andy Frank  Creation
//

using dom
using domkit

@Js
class MenuTest : DomkitTest
{
  new make()
  {
    grid := GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "padding: 12px")
      it.addRow([menus])
    }

    this.style->overflow = "auto"
    this.style->background = "#eee"
    this.add(grid)
  }

  Elem menus()
  {
    return FlowBox
    {
      it.gaps = ["12px"]
      simple, disabled, bigSync, bigAsync(false), bigAsync(true),
    }
  }

  Elem simple()
  {
    Button {
      it.style.addClass("disclosure")
      it.text = "Simple"
      it.onPopup {
        Menu
        {
          MenuItem { it.text="Alpha"; it.onAction { echo("# MenuItem: Alpha") }},
          MenuItem { it.text="Beta" ; it.onAction { echo("# MenuItem: Beta")  }},
          MenuItem { it.text="Gamma"; it.onAction { echo("# MenuItem: Gamma") }},
          MenuItem { it.text="Delta"; it.onAction { echo("# MenuItem: Delta") }},
        }
      }
    }
  }

  Elem disabled()
  {
    Button {
      it.style.addClass("disclosure")
      it.text = "Disabled"
      it.onPopup {
        Menu
        {
          MenuItem { it.text="Alpha"; it.enabled=false; it.onAction { echo("# MenuItem: Alpha") }},
          MenuItem { it.text="Beta" ; it.enabled=true;  it.onAction { echo("# MenuItem: Beta")  }},
          MenuItem { it.text="Gamma"; it.enabled=false; it.onAction { echo("# MenuItem: Gamma") }},
          MenuItem { it.text="Delta"; it.enabled=false; it.onAction { echo("# MenuItem: Delta") }},
        }
      }
    }
  }

  Elem bigSync()
  {
    Button {
      it.style.addClass("disclosure")
      it.text = "Big Sync"
      it.onPopup |b| {
        menu := Menu {}
        1000.times |x|
        {
          menu.add(MenuItem {
            it.text = "Item #$x"
            it.onAction { echo("# MenuItem: #$x") }
          })
        }
        return menu
      }
    }
  }

  Elem bigAsync(Bool fit)
  {
    Button {
      it.style.addClass("disclosure")
      it.text = "Big Async " + (fit ? "Fit" : "NoFit")
      it.onPopup |b| {
        menu := Menu {}
        menu.add(Label { it.text="Loading..."; it.style->paddingLeft="10px" })

        // delay adding items to bypass Popup.open bounds checking
        Win.cur.setTimeout(500ms)
        {
          menu.removeAll
          1000.times |x|
          {
            menu.add(MenuItem {
              it.text = "Item #$x"
              it.onAction { echo("# MenuItem: #$x") }
            })
          }
          if (fit) menu.fitBounds
        }

        return menu
      }
    }
  }
}