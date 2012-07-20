//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Feb 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** RowPane lays out rows of widgets into rows and columns.
**
@NoDoc
@Js
class RowPane : Pane
{
  ** Constructor.
  new make(|This| f)
  {
    this.canvas = RowPaneCanvas()
    add(canvas)
    f(this)
  }

  ** Column layouts for pane.
  ColLayout[] cols

  ** Background brush for pane, or null for none.
  Brush? bg := null

  ** Color to use for drawing row borders, or null for none.
  Color? rowBorder := null

  ** Map of row indexes to brushes for overriding row background.
  Int:Brush rowBg := [:]

  ** Return the child widgets for this row.
  Widget[] rowChildren(Int index)
  {
    rowSize := (children.size-1) / cols.size
    if (index < 0 || index >= rowSize) throw IndexErr()

    s := (index * cols.size) + 1
    e := s + cols.size
    return children[s..<e]
  }

  ** Return the row index for the pos relative to this pane, or
  ** null pos is not contained in any rows.
  Int? rowAt(Point pos)
  {
    y := 0
    return canvas.rowHeights.findIndex |h|
    {
      if (pos.y >= y && pos.y <= (y+h)) return true
      y += h
      if (rowBorder != null) y++
      return false
    }
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    if ((children.size-1) % cols.size != 0)
      throw ArgErr("Children must fill columns evenly")

    // num rows/cols
    colSize := cols.size
    rowSize := (children.size-1) / colSize

    // calc prefSizes
    prefs := Size[,]
    children.eachRange(1..-1) |kid| { prefs.add(kid.prefSize) }

    // find column widths and heights
    colw := Int[,].fill(0, colSize)
    rowh := Int[,].fill(0, rowSize)
    offset := 0
    rowSize.times |ri|
    {
      cols.each |col, ci|
      {
        p  := prefs[offset++]
        pw := p.w + (col.insets.left + col.insets.right)
        ph := p.h + (col.insets.top  + col.insets.bottom)
        colw[ci] = colw[ci].max(pw)
        rowh[ri] = rowh[ri].max(ph)
      }
    }

    // find total pref size
    Int pw := colw.reduce(0) |Int v, Int w->Int| { w+v }
    Int ph := rowh.reduce(0) |Int v, Int h->Int| { h+v }
    if (rowBorder != null) ph = (Int)ph + rowSize - 1
    return Size(pw, ph)
  }

  override Void onLayout()
  {
    if ((children.size-1) % cols.size != 0)
      throw ArgErr("Children must fill columns evenly")

    // num rows/cols
    colSize := cols.size
    rowSize := (children.size-1) / colSize

    // calc prefSizes
    prefs := Size[,]
    children.eachRange(1..-1) |kid| { prefs.add(kid.prefSize) }

    // find column widths and heights
    colw := Int[,].fill(0, colSize)
    rowh := Int[,].fill(0, rowSize)
    offset := 0
    rowSize.times |ri|
    {
      cols.each |col, ci|
      {
        p  := prefs[offset++]
        pw := p.w + (col.insets.left + col.insets.right)
        ph := p.h + (col.insets.top  + col.insets.bottom)
        colw[ci] = colw[ci].max(pw)
        rowh[ri] = rowh[ri].max(ph)
      }
    }

    // calculate flex
    maxw := 0
    colw.each |cw| { maxw += cw }
    dw := size.w - maxw
    if (dw != 0)
    {
      cols.each |col,i|
      {
        if (col.flex == 0) return
        colw[i] += (dw.toFloat * col.flex.toFloat / 100f).toInt
      }
    }

    // layout bg
    canvas.bg = bg
    canvas.rowBorder = rowBorder
    canvas.rowHeights = rowh
    canvas.rowBg = rowBg
    canvas.pos  = Point.defVal
    canvas.size = size

    // layout children
    offset = 0
    dy := 0
    rowSize.times |ri|
    {
      dx := 0
      rh := rowh[ri]
      cols.each |col, ci|
      {
        cw := colw[ci]
        p  := prefs[offset]
        w  := children[offset+1]

        // account for insets
        iw := cw - (col.insets.left + col.insets.right)
        ih := rh - (col.insets.top + col.insets.bottom)

        wx := 0   // init to left
        wy := 0   // init to top
        ww := iw.min(p.w)  // init to pref/space avail
        wh := ih.min(p.h)  // init to pref/space avail

        switch (col.halign)
        {
          case Halign.center: wx = (iw - p.w) / 2
          case Halign.right:  wx = iw - p.w
          case Halign.fill:   ww = iw
        }

        switch (col.valign)
        {
          case Valign.center: wy = (ih - p.h) / 2
          case Valign.bottom: wy = ih - p.h
          case Valign.fill:   wh = ih
        }

        // set bounds and advance
        w.bounds = Rect(dx+wx+col.insets.left, dy+wy+col.insets.top, ww, wh)
        dx += cw
        offset++
      }

      dy += rh
      if (rowBorder != null) dy++
    }
  }

  private RowPaneCanvas canvas
}

**************************************************************************
** ColLayout
**************************************************************************
@NoDoc
@Js
class ColLayout
{
  ** Horizontal alignment of widget for this column.
  Halign halign := Halign.left

  ** Vertical alignment of widget for this column.
  Valign valign := Valign.center

  ** If the difference between the preferred width and the available
  ** width is non-zero, then 'flex' is the percetange of that difference
  ** to take or give to widgets in this columm. Use '0' to always use
  ** the preferred width.
  Int flex := 0

  ** Insets around widgets in this column.
  Insets insets := Insets(6)
}

**************************************************************************
** RowPaneCanvas
**************************************************************************
@Js
internal class RowPaneCanvas : Canvas
{
  Brush? bg := null
  Color? rowBorder := null
  Int[] rowHeights := [,]
  Int:Brush rowBg := [:]

  override Void onPaint(Graphics g)
  {
    if (bg != null)
    {
      g.brush = bg
      g.fillRect(0, 0, size.w, size.h)
    }

    rowBg.each |c,i|
    {
      y := 0
      i.times |j|
      {
        y += rowHeights[j]
        if (rowBorder != null) y++
      }
      g.brush = c
      g.fillRect(0, y, size.w, rowHeights[i])
    }

    if (rowBorder != null)
    {
      g.brush = rowBorder
      dy := 0
      rowHeights.each |h|
      {
        g.drawLine(0, dy+h, size.w, dy+h)
        dy += h+1
      }
    }
  }
}