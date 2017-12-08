//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Feb 2015  Andy Frank  Creation
//

using dom

**
** GridBox lays its children out in a two dimensional grid.
**
** See also: [docDomkit]`docDomkit::Layout#gridBox`
**
@Js class GridBox : Box
{
  new make()
  {
    this.table = Elem("table")
    this.tbody = Elem("tbody")
    table.add(tbody)

    this.style.addClass("domkit-GridBox")
    this.add(table)
  }

  ** How grid content is aligned horizontally against left-over
  ** space. Valid values are 'left', 'right', 'center', or 'fill'.
  Align halign := Align.left
  {
    set
    {
      switch (&halign = it)
      {
        case Align.left:   table.style->margin = null
        case Align.center: table.style->margin = "0 auto"
        case Align.right:  table.style->margin = "0 0 0 auto"
        case Align.fill:   table.style->width  = "100%"
      }
    }
  }

  **
  ** Set style for cells. Valid values for 'col' and 'row':
  **  - Specific index (0, 1, 2, etc)
  **  - Range of indexes (0..4, 7..<8, etc)
  **  - "*":    apply to all row or columns
  **  - "even": apply only to even row or columns indexes
  **  - "odd":  apply only to odd row or column indexes
  **
  This cellStyle(Obj col, Obj row, Str style)
  {
    if (col is Range && row is Range)
    {
      ((Range)row).each |r| {
        ((Range)col).each |c| {
          cstyleMap["$c:$r"] = style
        }
      }
    }
    else if (col is Range) ((Range)col).each |c| { cstyleMap["$c:$row"] = style }
    else if (row is Range) ((Range)row).each |r| { cstyleMap["$col:$r"] = style }
    else cstyleMap["$col:$row"] = style
    if (!init) updateCellStyle
    return this
  }

  ** The number of rows in this GridBox.
  Int numRows() { tbody.children.size }

  ** Add a new row to grid.
  This addRow(Elem?[] cells, Int[] colspan := Int#.emptyList)
  {
    _addRow(null, cells, colspan)
  }

  ** Insert row before given index.
  This insertRowBefore(Int index, Elem?[] cells, Int[] colspan := Int#.emptyList)
  {
    _addRow(index, cells, colspan)
  }

  ** Add a new row to grid.
  private This _addRow(Int? at, Elem?[] cells, Int[] colspan := Int#.emptyList)
  {
    r  := tbody.children.size
    cx := 0
    tr := Elem("tr")

    cells.each |elem,c|
    {
      td := Elem("td")
      cs := colspan.getSafe(c)
      if (cs != null) td["colspan"] = cs.toStr
      applyCellStyle(c+cx, r, td)
      if (elem != null) td.add(elem)
      cx += cs==null ? 0 : cs-1
      tr.add(td)
    }

    if (at == null) tbody.add(tr)
    else tbody.insertBefore(tr, tbody.children[at])

    init = false
    return this
  }

  ** Return the row index that this child exists under, or
  ** 'null' if child was not found in this GridBox.
  Int? rowIndexOf(Elem child)
  {
    tbody.children.findIndex |row|
    {
      row.containsChild(child)
    }
  }

  ** Remove the row of cells at given index.
  This removeRow(Int index)
  {
    row := tbody.children.getSafe(index)
    if (row != null) tbody.removeChild(row)
    return this
  }

  ** Remove all rows of cells for this GridBox.
  This removeAllRows()
  {
    tbody.removeAll
    return this
  }

  ** Update cell styles on existing children.
  private Void updateCellStyle()
  {
    tbody.children.each |tr,r|
    {
      tr.children.each |td,c| { applyCellStyle(c, r, td) }
    }
  }

  ** Find all styles to apply this to cell.
  private Void applyCellStyle(Int c, Int r, Elem td)
  {
    // all
    setCellStyle("*:*", td)

    // even/odd
    calt := c.isOdd ? "odd" : "even"
    ralt := r.isOdd ? "odd" : "even"
    setCellStyle("*:$ralt",   td)
    setCellStyle("$calt:*",   td)
    setCellStyle("$calt:$ralt", td)

    // row index
    setCellStyle("*:$r",   td)
    setCellStyle("$calt:$r", td)

    // col index
    setCellStyle("$c:*",  td)
    setCellStyle("$c:$ralt", td)

    // cell index
    setCellStyle("$c:$r", td)
  }

  ** Set cell style key on element.
  private Void setCellStyle(Str key, Elem td)
  {
    s := cstyleMap[key]
    if (s != null) td.style.setCss(s)
  }

  private Elem table
  private Elem tbody
  private Bool init := true
  private Str:Str cstyleMap := [:]
}