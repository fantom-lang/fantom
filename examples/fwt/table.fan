#! /usr/bin/env fan
//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jul 11  Brian Frank  Creation
//

using gfx
using fwt

**
** TableDemo illustrates different features of the Table widget
**
class TableDemo
{
  Void main()
  {
    // model and table
    model := Model()
    table := Table { it.model = model }

    // fields to change model
    headerPrefix := Text { text = model.headerPrefix }
    numCols := Text { text = model.numCols.toStr }
    numRows := Text { text = model.numRows.toStr }
    halign  := Combo { items = [Halign.left, Halign.center, Halign.right] }
    fg      := Combo { items = [Color.black, Color.blue, Color.red, Color.green] }
    show0   := Button { text = "Show Col 0"; mode = ButtonMode.check; selected = true }
    show1   := Button { text = "Show Col 1"; mode = ButtonMode.check; selected = true }
    show2   := Button { text = "Show Col 2"; mode = ButtonMode.check; selected = true }

    // udpate callback maps fields -> model and calls refreshAll
    update := |->|
    {
      echo("Update!")
      model.headerPrefix = headerPrefix.text
      model.numCols      = numCols.text.toInt
      model.numRows      = numRows.text.toInt
      model.halignVal    = halign.selected
      model.fgVal        = fg.selected
      if (model.numCols >= 1) table.setColVisible(0, show0.selected)
      if (model.numCols >= 2) table.setColVisible(1, show1.selected)
      if (model.numCols >= 3) table.setColVisible(2, show2.selected)
      table.refreshAll
    }

    // put together the whole screen and open
    Window
    {
      title = "Table Demo"
      EdgePane
      {
        center = table
        right = InsetPane
        {
          content = GridPane
          {
            it.numCols = 2
            Label { text = "headerPrefix" },  headerPrefix,
            Label { text = "numCols" },       numCols,
            Label { text = "numRows" },       numRows,
            Label { text = "halign" },        halign,
            Label { text = "fg" },            fg,
            show0, Label { text = "" },
            show1, Label { text = "" },
            show2, Label { text = "" },
            Button { text = "refreshAll"; onAction.add(update) },
          }
        }
      },;
      size = Size(800,600)
    }.open
  }
}

class Model : TableModel
{
  Str headerPrefix := "Col-"
  Halign halignVal := Halign.left
  Color fgVal := Color.black
  override Str header(Int col) { headerPrefix + col }
  override Int numRows := 20
  override Int numCols := 3
  override Halign halign(Int col) { halignVal }
  override Color? fg(Int col, Int row) { fgVal }
}

