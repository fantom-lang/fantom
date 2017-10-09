//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Oct 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class RadioButtonTest : DomkitTest
{
  new make()
  {
    this.style->background = "#eee"
    add(GridBox
    {
      it.style->padding = "18px"
      it.cellStyle("*", "*", "padding: 18px; vertical-align: top")
      it.addRow([radios, group])
      it.addRow([docDomkit, Elem {}])
      it.addRow([valign, Elem {}])
    })
  }

  Elem radios()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding-bottom: 12px")
      it.addRow([RadioButton {}.wrap("Radio #1")])
      it.addRow([RadioButton { it.checked=false }.wrap("Radio #2")])
      it.addRow([RadioButton { it.checked=true  }.wrap("Radio #3")])
      it.addRow([RadioButton { it.checked=true; it.enabled=false }.wrap("Radio #4")])
      it.addRow([RadioButton { it.enabled=false }.wrap("Radio #5")])
      it.addRow([RadioButton { it.onAction |cb| { echo("radio: $cb.checked") }}.wrap("Echo onAction")])
    }
  }

  Elem group()
  {
    GridBox
    {
      g := ButtonGroup()
      g.add(RadioButton {})
      g.add(RadioButton {})
      g.add(RadioButton {})
      g.add(RadioButton {})
      g.selIndex = 0

      it.cellStyle("*", "*", "padding-bottom: 12px")
      it.addRow([(g.buttons[0] as RadioButton).wrap("Group-Option #1")])
      it.addRow([(g.buttons[1] as RadioButton).wrap("Group-Option #2")])
      it.addRow([(g.buttons[2] as RadioButton).wrap("Group-Option #3")])
      it.addRow([(g.buttons[3] as RadioButton).wrap("Group-Option #4")])
    }
  }

  Elem docDomkit()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding-bottom: 12px")
      it.addRow([RadioButton {}])
      it.addRow([RadioButton { it.checked=true }])
      it.addRow([RadioButton {}.wrap("You can click here too!")])
    }
  }

  Elem valign()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding-bottom: 12px")
      it.addRow([FlowBox {
        it.gaps = ["4px"]
        RadioButton {}.wrap("RadioButton"),
        Label { it.text="Label" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["6px"]
        RadioButton {},
        Label { it.text="Not Wrapped Align" },
      }])
      it.addRow([FlowBox {
        it.gaps = ["4px"]
        RadioButton {}.wrap("RadioButton"),
        TextField {},
      }])
    }
  }
}