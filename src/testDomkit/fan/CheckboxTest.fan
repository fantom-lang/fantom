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
class CheckboxTest : DomkitTest
{
  new make()
  {
    add(GridBox
    {
      it.style->padding = "18px"
      it.cellStyle("*", "*", "padding: 18px")
      it.addRow([checks])
    })
  }

  Elem checks()
  {
    GridBox
    {
      it.cellStyle("*", "*", "padding-bottom: 12px")
      it.addRow([Checkbox {}.wrap("Checkbox #1")])
      it.addRow([Checkbox { it.checked=false }.wrap("Checkbox #2")])
      it.addRow([Checkbox { it.checked=true  }.wrap("Checkbox #3")])
      it.addRow([Checkbox { it.checked=true; it.enabled=false }.wrap("Checkbox #4")])
      it.addRow([Checkbox { it.enabled=false }.wrap("Checkbox #5")])
      it.addRow([Checkbox { it.onAction |cb| { echo("checkbox: $cb.checked") }}.wrap("Echo onAction")])
    }
  }
}