//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

using gfx

**
** GridPane is a container which lays out its children in a grid
** from left to right with a new row started based on 'numCols'.
**
** TODO: this API going to change, most likely there will be a
**   switch to per col/per row configuration
**
@Js
@Serializable { collection = true }
class GridPane : Pane
{

  **
  ** Number of columns before wrapping to a new row.
  ** Default is 1.
  **
  Int numCols := 1

  **
  ** Horizontal gap is number of pixels between left and
  ** right edges of adjacent cells.  Default is 4.
  **
  Int hgap := 4

  **
  ** Vertical gap is number of pixels between bottom and
  ** top edges of adjacent cells.  Default is 4.
  **
  Int vgap := 4

  **
  ** Horizontal alignment of the individual cells.  Defaults to left.
  **
  Halign halignCells := Halign.left

  **
  ** Vertical alignment of the individual cells.  Defaults to center.
  **
  Valign valignCells := Valign.center

  **
  ** Horizontal alignment of the entire pane - this defines where
  ** the extra horizontal space beyond the preferred width goes.
  ** This field only makes sense when `expandCol` is null.
  ** Defaults to left.
  **
  Halign halignPane := Halign.left

  **
  ** Vertial alignment of the entire pane - this defines where
  ** the extra vertial space beyond the preferred height goes.
  ** This field only makes sense when `expandRow` is null.
  ** Defaults to top.
  **
  Valign valignPane := Valign.top

  **
  ** If non-null, then this is a zero based row number to assign
  ** any extra height available beyond the preferred height.  A
  ** negative number indexes from the last row.  Default is null.
  **
  Int? expandRow := null

  **
  ** If non-null, then this is a zero based column number to assign
  ** any extra width available beyond the preferred width.  A
  ** negative number indexes from the last column.  Default is null.
  **
  Int? expandCol := null

  **
  ** If true, then all columns are given a uniform width which
  ** is computed from the widest column.  If false then columns
  ** might be laid out with variable widths based on the width
  ** of the cells.  Default is false.
  **
  Bool uniformCols := false

  **
  ** If true, then all rows are given a uniform height which
  ** is computed from the highest row.  If false then rows
  ** might be laid out with variable heights based on the highest
  ** of the cells.  Default is false.
  **
  Bool uniformRows:= false

  override Size prefSize(Hints hints := Hints.defVal)
  {
    return GridPaneSizes(this, children).prefPane
  }

  override Void onLayout()
  {
    // compute max width of each column, and max height of each row
    kids := children
    sizes := GridPaneSizes(this, kids)
    psize := this.size
    actualw := psize.w; actualh := psize.h
    prefw := sizes.prefPane.w; prefh := sizes.prefPane.h

    // compute expand row/col
    expandRow := this.expandRow
    expandCol := this.expandCol
    if (expandRow != null && expandRow < 0) expandRow  = sizes.numRows+expandRow
    if (expandCol != null && expandCol < 0) expandCol  = numCols+expandCol
    expandRowh := 0.max(actualh-prefh)
    expandColw := 0.max(actualw-prefw)

    // compute left hand corner of grid pane
    startx := 0; starty := 0
    if (expandCol == null)
      switch (halignPane)
      {
        case Halign.center: startx = expandColw/2
        case Halign.right:  startx = expandColw
      }
    if (expandRow == null)
      switch (valignPane)
      {
        case Valign.center: starty = expandRowh/2
        case Valign.bottom: starty = expandRowh
      }

    // layout children
    col := 0; row := 0
    x := startx; y := starty
    kids.each |Widget kid, Int i|
    {
      pref := sizes.prefs[i]
      kx := x
      ky := y
      kw := pref.w
      kh := pref.h
      rowh := sizes.rowh[row]
      colw := sizes.colw[col]

      if (row == expandRow) rowh += expandRowh
      if (col == expandCol) colw += expandColw

      switch (halignCells)
      {
        case Halign.center: kx = x + (colw-kw)/2
        case Halign.right:  kx = x + (colw-kw)
        case Halign.fill:   kw = colw
      }

      switch (valignCells)
      {
        case Valign.center: ky = y + (rowh-kh)/2
        case Valign.bottom: ky = y + (rowh-kh)
        case Valign.fill:   kh = rowh
      }

      kid.pos = Point(kx,ky)
      kid.size = Size(kw,kh)

      if (++col >= numCols) { x = startx; y += rowh + vgap; col = 0; row++ }
      else { x += colw + hgap }
    }
  }
}

@Js
internal class GridPaneSizes
{
  new make(GridPane grid, Widget[] kids)
  {
    // short-circuit if no kids
    if (kids.isEmpty)
    {
      prefPane = Size.defVal
      return
    }

    // compute colw and rowh lists
    col := 0; row := 0
    kids.each |Widget kid|
    {
      pref := kid.visible ? kid.prefSize : Size.defVal
      prefs.add(pref)

      if (col >= colw.size) colw.add(pref.w)
      else colw[col] = colw[col].max(pref.w)

      if (row >= rowh.size) rowh.add(pref.h)
      else rowh[row] = rowh[row].max(pref.h)

      if (++col >= grid.numCols) { col = 0; row++ }
    }

    // if uniform rows/cols
    if (grid.uniformCols) { max := colw.max; colw.size.times |Int i| { colw[i] = max } }
    if (grid.uniformRows) { max := rowh.max; rowh.size.times |Int i| { rowh[i] = max } }

    // compute prefw
    prefw := (grid.numCols - 1) * grid.hgap
    grid.numCols.times |Int c| { prefw += colw[c] }

    // compute prefh
    prefh := (numRows - 1) * grid.vgap
    numRows.times |Int r| { prefh += rowh[r] }

    // prefPane
    prefPane = Size(prefw, prefh)
  }

  Int numRows() { return rowh.size }

  Int[] colw := Int[,]     // widths of each column
  Int[] rowh := Int[,]     // heights of each row
  Size[] prefs := Size[,]  // calcualted prefSize of each widget
  Size prefPane            // pref size of whole grid
}