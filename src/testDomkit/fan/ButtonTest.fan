//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class ButtonTest : DomkitTest
{
  new make()
  {
    grid := GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "padding: 12px")
      it.addRow([buttons, menus])
      it.addRow([toggles, lists])
      it.addRow([labels,  combos])
      it.addRow([groups1, groups2])
      it.addRow([docDomkit, Elem {}])
    }

    this.style->overflow = "auto"
    this.style->background = "#eee"
    this.add(grid)
  }

  Elem buttons()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Button { it.text="Button"; it.onAction { echo("# Button-1") }},
      Button { it.html="<b>Button</b>"; it.onAction { echo("# Button-2") }},
      Button { it.html="Disabled"; it.enabled=false; it.onAction { echo("# Button-3") }},
      Button { it.onAction { echo("# Empty") }},  // no-text
    }
  }

  Elem toggles()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      ToggleButton { it.text="Toggle" },
      ToggleButton { it.text="Toggle"; selected=true },
      ToggleButton
      {
        it.elemOn  = Elem { it.text="On" }
        it.elemOff = Elem { it.text="Off" }
        it.selected = false
      },
      ToggleButton
      {
        it.style->minWidth = "60px"
        it.elemOn  = "Yes"
        it.elemOff = "No"
        it.selected = false
      },
      ToggleButton { it.html="Disabled"; it.selected=true; it.enabled=false },
      ToggleButton { it.html="Disabled"; it.enabled=false },
    }
  }

  Elem menus()
  {
    menu1 := Menu
    {
      MenuItem { it.text="Alpha"; it.onAction { echo("# MenuItem: Alpha") }},
      MenuItem { it.text="Beta" ; it.onAction { echo("# MenuItem: Beta")  }},
      MenuItem { it.text="Gamma"; it.onAction { echo("# MenuItem: Gamma") }},
      MenuItem { it.text="Delta"; it.onAction { echo("# MenuItem: Delta") }},
    }

    return FlowBox
    {
      it.gaps = ["12px"]
      Button { it.text="Menu"; it.onPopup { menu1 }},
      Button { it.text="Menu"; it.style.addClass("disclosure"); it.onPopup { menu1 }},
      Button { it.text="Stretch Menu to Fit Button"; it.onPopup { menu1 }},
    }
  }

  Elem lists()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      ListButton {},
      ListButton
      {
        it.items = ["Alpha", "Beta", "Gamma", "Delta"]
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
      ListButton
      {
        it.items = [1,2,3,4]
        it.sel.index = 2
        it.onElem |v| { "Item #$v" }
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
      ListButton
      {
        it.items = [1,2,3,4]
        it.sel.index = 0
        it.onElem |Int v->Elem|
        {
          Elem {
            if (v % 2 == 0) it.style.addClass("disabled")
            it.text = "Item #$v"
          }
        }
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
      ListButton
      {
        it.items = genItems("BigList", 1000)
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
      ListButton
      {
        it.style->width = "100px"
        it.items = [
          "#1 Really really long item / clip test",
          "#2 Really really long item / clip test",
          "#3 Really really long item / clip test",
          "#4 Really really long item / clip test",
          "#5 Really really long item / clip test",
        ]
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
      ListButton
      {
        it.style->width = "130px"
        it.items = [
          "Alabama",
          "Alaska",
          "Arizona",
          "Arkansas",
          "California",
          "Colorado",
          "Connecticut",
          "Delaware",
          "Florida",
          "Georgia",
          "Hawaii",
          "Idaho",
          "Illinois",
          "Indiana",
          "Iowa",
          "Kansas",
          "Kentucky",
          "Louisiana",
          "Maine",
          "Maryland",
          "Massachusetts",
          "Michigan",
          "Minnesota",
          "Mississippi",
          "Missouri",
          "Montana",
          "Nebraska",
          "Nevada",
          "New Hampshire",
          "New Jersey",
          "New Mexico",
          "New York",
          "North Carolina",
          "North Dakota",
          "Ohio",
          "Oklahoma",
          "Oregon",
          "Pennsylvania",
          "Rhode Island",
          "South Carolina",
          "South Dakota",
          "Tennessee",
          "Texas",
          "Utah",
          "Vermont",
          "Virginia",
          "Washington",
          "West Virginia",
          "Wisconsin",
          "Wyoming",
        ]
        it.onSelect |b| { echo("# item: $b.sel.item [$b.sel.index]") }
      },
    }
  }

  Elem labels()
  {
    FlowBox
    {
      it.gaps = ["5px"]
      Label  { it.text="Confirm?" },
      Button { it.text="Yes" },
    }
  }

  Elem combos()
  {
    FlowBox
    {
      it.gaps = ["12px"]
      Combo {},
      Combo
      {
        it.items = ["Alpha", "Beta", "Gamma", "Delta"]
        it.field.val = "FooBar"
        it.field.onAction |f| { echo("# combo: $f.val") }
      },
      Combo { it.enabled = false }
    }
  }

  private Obj genItems(Str prefix, Int size)
  {
    items := Obj[,]
    size.times |i| { items.add("${prefix}-${i}") }
    return items
  }

  Elem groups1()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding: 6px 0")
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Group 1" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Group 1" },
        Button { it.text="Group 2" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Group 1" },
        Button { it.text="Group 2" },
        Button { it.text="Group 3" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Group 1" },
        Button { it.text="Group 2" },
        Button { it.text="Group 3" },
        Button { it.text="Group 4" },
      }])
    }
  }

  Elem groups2()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding: 6px 0")
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        TextField {},
        Button { it.text="Right" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        TextField {},
        Button { it.text="Right 1" },
        Button { it.text="Right 2" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Left" },
        TextField {},
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Left 1" },
        Button { it.text="Left 2" },
        TextField {},
      }])
      it.addRow([FlowBox {
        it.gaps = ["-1px"]
        Button { it.text="Left" },
        TextField {},
        Button { it.text="Right" },
      }])
    }
  }

  Elem docDomkit()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding: 10px 0")
      it.addRow([FlowBox {
        it.gaps = ["10px"]
        Button
        {
          it.text = "Press me"
          it.onAction { echo("Pressed!") }
        },
        Button
        {
          onAction { echo("Pressed!") }
          Elem("b") { it.text="Really Press me!" },
        },
      }])
      it.addRow([FlowBox {
        it.gaps = ["10px"]
        ToggleButton { it.text="Toggle Me" },
        ToggleButton { it.text="Toggle Me"; selected=true },
        ToggleButton { it.elemOn="On"; it.elemOff="Off"; selected=false },
        ToggleButton { it.elemOn="On"; it.elemOff="Off"; selected=true },
      }])
    }
  }
}