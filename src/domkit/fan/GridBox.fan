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
** See also: [pod doc]`pod-doc#gridBox`
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

  ** How grid content is aligned against left-over space. Valid
  ** values are "left", "right", "center", or "fill".
  Str align := "left"
  {
    set
    {
      switch (&align = it)
      {
        case "left":   this.style["text-align"] = "left"
        case "center": this.style["text-align"] = "center"
        case "right":  this.style["text-align"] = "right"
        case "fill":   table.style["width"] = "100%"
      }
    }
  }

  **
  ** Set style for cells. Valid values for 'col' and 'row':
  **  - Specific index (0, 1, 2, etc)
  **  - Range of indexes (0..4, 7..<8, etc)
  **  - "all":  apply to all row or columns
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
    return this
  }

  ** Add a new row to grid.
  This addRow(Elem?[] cells, Int[] colspan := Int#.emptyList)
  {
    r  := tbody.children.size
    cx := 0
    tr := Elem("tr")
    cells.each |elem,c|
    {
      td := Elem("td")
      cs := colspan.getSafe(c)
      if (cs != null) td["colspan"] = cs
      applyCellStyle(c+cx, r, td)
      if (elem != null) td.add(elem)
      cx += cs==null ? 0 : cs-1
      tr.add(td)
    }
    tbody.add(tr)
    return this
  }

  ** Find all styles to apply this to cell.
  private Void applyCellStyle(Int c, Int r, Elem td)
  {
    // all
    setCellStyle("all:all", td)

    // even/odd
    calt := c.isOdd ? "odd" : "even"
    ralt := r.isOdd ? "odd" : "even"
    setCellStyle("all:$ralt",   td)
    setCellStyle("$calt:all",   td)
    setCellStyle("$calt:$ralt", td)

    // row index
    setCellStyle("all:$r",   td)
    setCellStyle("$calt:$r", td)

    // col index
    setCellStyle("$c:all",  td)
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
  private Str:Str cstyleMap := [:]
}