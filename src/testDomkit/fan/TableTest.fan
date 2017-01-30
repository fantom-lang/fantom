//
// Copyright (c) 2015, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   16 Feb 2015  Brian Frank  Creation
//

using dom
using domkit

@Js
class TableTest : DomkitTest
{
  new make()
  {
    table = Table
    {
      it.sel.multi = true
      it.onAction |t| { echo("# action: $t.sel.indexes") }
      it.onSelect |t| { echo("# select: $t.sel.indexes") }
      it.onTableEvent(EventType.mouseDown) |e| { echo("# cell-event $e") }
      // it.onTableEvent(EventType.mouseUp)   |e| { echo(e) }
      // it.onTableEvent("mousemove") |e| { onTestMove(e) }
    }

    add(SashBox
    {
      it.sizes = ["100%"]
      it.style->padding = "10px"
      table,
    })

    update
  }

  override Bool hasOptions() { true }

  override Void onOptions()
  {
    dlg := Dialog { it.title = "Options" }
    dlg.add(GridBox
    {
      it.style->padding = "6px"
      it.cellStyle("all", "all", "padding: 6px")
      it.addRow([Label { it.text="Columns:"           }, cols   ])
      it.addRow([Label { it.text="Rows:"              }, rows   ])
      it.addRow([Label { it.text="Row Height:"        }, rowh   ])
      it.addRow([Label { it.text="Selection Enabled:" }, selOn  ])
      it.addRow([Label { it.text="Mutli-Selection:"   }, multi  ])
      it.addRow([Label { it.text="Pre-select row:"    }, presel ])
      it.addRow([Label { it.text="Show Header:"       }, header ])
      it.addRow([FlowBox {
        it.style->paddingTop = "6px"
        it.halign = Align.right
        it.gaps = ["4px"]
        Button { it.text="Update"; onAction { dlg.close; update }},
        Button { it.text="Cancel"; onAction { dlg.close }},
      }], [2])
    })
    dlg.open
  }

  Void update()
  {
    table.showHeader = this.header.checked
    table.sel.enabled = this.selOn.checked
    table.sel.multi  = this.multi.checked
    table.sel.index  = this.presel.val.toInt(10, false)
    table.model = TestTableModel
    {
      it.cols = this.cols.val.toInt
      it.rows = this.rows.val.toInt
      it.rowh = this.rowh.val.toInt
    }
    table.rebuild
  }

  Table table
  TextField cols   := TextField { it.val="100"  }
  TextField rows   := TextField { it.val="1000" }
  TextField rowh   := TextField { it.val="20" }
  Checkbox selOn   := Checkbox { it.checked=true }
  Checkbox multi   := Checkbox { it.checked=true}
  TextField presel := TextField { it.val="" }
  Checkbox header  := Checkbox { it.checked=true }
}

@Js internal class TestTableModel : TableModel
{
  new make(|This| f)
  {
    f(this)
    this.rpad = rows.toFloat.log10.toInt + 1
  }

  const Int cols
  const Int rows
  const Int rowh := 20
  const Int rpad

  override Int numCols() { cols }
  override Int numRows() { rows }
  override Int rowHeight() { rowh }
  override Int colWidth(Int c) { c % 4 == 0 ? 300 : 100 }
  override Void onHeader(Elem e, Int c) { super.onHeader(e, c) }
  override Void onCell(Elem cell, Int col, Int row, TableFlags flags)
  {
    sel   := flags.selected && flags.focused
    text  := toText(col, row)
    icon  := col % 4 == 0
    color := (flags.selected && flags.focused) ? "white" : "grey"

    cell.style->padding            = icon ? "0 4px 0 22px" : "0 4px"
    cell.style->backgroundImage    = icon ? "url(/pod/testDomkit/res/info-${color}.svg)" : ""
    cell.style->backgroundRepeat   = "no-repeat"
    cell.style->backgroundPosition = "4px center"
    cell.style->backgroundSize     = "14px 14px"

    cell.text = text
  }
  override Int sortCompare(Int c, Int r1, Int r2) { toText(c, r1).localeCompare(toText(c, r2)) }
  private Str toText(Int col, Int row) { "C$col:R" + row.toStr.padl(rpad, '0') }
}

