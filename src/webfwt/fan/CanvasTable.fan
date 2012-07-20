//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Oct 2011  Andy Frank  Creation
//

using fwt
using gfx
using web

**
** CanvasTable renders an entire table in an Canvas widget, allowing
** each cell to be fully customized by painting with a Graphics
** context.
**
@Js
abstract class CanvasTable : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Construction
/////////////////////////////////////////////////////////////////////////

  ** Constructor.
  new make(|This|? f)
  {
    if (f != null) f(this)
    this.onKeyDown.add |e| { handleKeyDown(e) }
    this.content = EdgePane
    {
      top = headerCanvas
      center = WebScrollPane
      {
        hpolicy = WebScrollPane.auto
        vpolicy = WebScrollPane.on
        onScroll.add |e| { handleScroll(e) }
        RowOverlayPane(rowCanvas, rowOverlayCanvas),
      }
    }
  }

  ** Column names.
  const Str[] colNames

  ** Column widths. Integer values represent exact widths.  Float
  ** values represent a percentage of remaining space (0..1).
  const Num[] colWidths

  ** Is selection enabled for this table.
  Bool selectionEnabled := true

  ** Selected table index.
  Int[] selected := [,]

  ** Callback when a row is double clicked or Space is pressed.
  **  - id: EventId.action
  **  - index: the row index
  once EventListeners onAction()  { EventListeners() }

  ** Callback when a column is sorted.
  virtual Void onSort(Int col, SortMode mode) {}

  ** Callback when mouse moved in cell.
  virtual Void onCellMoved(Event e, Int col, Int row, Point pos, Size cellSize) {}

  ** Callback when mouse pressed in cell.
  virtual Void onCellPressed(Event e, Int col, Int row, Point pos, Size cellSize) {}

  ** Get cell position relative to table.
  Point cellPosToTable(Point pos, Int col, Int row)
  {
    // offset in table
    x := pos.x
    y := pos.y
    col.times |i| { x += colw[i] }
    row.times |i| { y += rowb[i].h }

    // offset in scrollpane
    pane := (WebScrollPane)content->center
    x -= pane.scrollX
    y -= pane.scrollY
    return Point(x, y).translate(pane.pos)
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Void onLayout()
  {
    // layout cols
    cw := (Int)colWidths.reduce(0) |Int v,c| { v + (c as Int ?: 0) }
    rw := size.w - cw - 10  // -10 for WebScrollPane scrollbar
    dw := 0
    fc := false
    colw.clear
    colWidths.each |c,i|
    {
      w := 0
      if (c is Int) w = c
      else { w = (rw * c.toFloat).toInt; fc=true }
      if (fc && i == colWidths.size-1) w = size.w - dw - 10
      colw.add(w)
      dw += w
    }

    // layout rows
    dy := 0
    rowb.clear
    numRows.times |r|
    {
      dh := rowHeight(r)
      rowb.add(Rect(0, dy, size.w, dh))
      dy += dh
    }

    super.onLayout
  }

  ** Get number of rows in table.
  abstract Int numRows()

  ** Get height for row at given index.
  abstract Int rowHeight(Int i)

  ** Paint the cell at given index.
  abstract Void paintCell(Graphics g, Int col, Int row, Bool selected, Size cellSize)

  ** Paint the cell overlay at given index.
  virtual Void paintCellOverlay(Graphics g, Int col, Int row, Bool selected, Size cellSize) {}

  ** Repaint only the overaly layers.
  Void repaintOverlay() { rowOverlayCanvas.repaint }

//////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////

  ** Write HTML markup for this cell.
  virtual Void writeHtml(WebOutStream out, Int col, Int row) {}

  ** Render cell as PNG image encoded as Base64 and write to HTML.
  native Void writePng(WebOutStream out, Int col, Int row)

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  private Void handleScroll(Event e)
  {
    x := e.pos.x
    if (headerCanvas.scrollX != x)
    {
      headerCanvas.scrollX = x
      headerCanvas.repaint
    }
  }

  private Void handleKeyDown(Event e)
  {
    switch (e.key)
    {
      case Key.up:
        i := ((selected.first ?: 1) - 1).max(0)
        rowCanvas.updateSelected(i)
        e.consume

      case Key.down:
        i := ((selected.first ?: -1) + 1).min(numRows-1)
        rowCanvas.updateSelected(i)
        e.consume

      case Key.space: fireAction
    }
  }

  internal Void fireAction()
  {
    i := selected.first
    if (i == null) return
    onAction.fire(Event { id=EventId.action; widget=this; index=i })
  }

  internal Int? toColIndex(Int x)
  {
    dx := 0
    x += headerCanvas.scrollX
    c := colw.findIndex |w|
    {
      dx += w
      return x < dx
    }
    return c==null ? colw.size-1 : c
  }

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  ** Background color of odd rows.
  const Color rowOddBg := Color.white

  ** Background color of even rows.
  const Color rowEvenBg := Color("#f1f5fa")

  ** Background color of selected row.
  const Color rowSelectedBg := Color("#3d80df")

  ** Color of border between rows.
  const Color rowBorder := Color("#bbb")

  ** Color of border between cells.
  const Color cellBorder := Color("#d9d9d9")

  ** Color of border between cells when row is selected.
  const Color cellSelectedBorder := Color("#346dbe")

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private HeaderCanvas headerCanvas := HeaderCanvas(this)
  private RowCanvas rowCanvas := RowCanvas(this)
  private RowOverlayCanvas rowOverlayCanvas := RowOverlayCanvas(this)

  internal Int[] colw := [,]
  internal Rect[] rowb := [,]
  internal Int? sortCol := null
  internal SortMode sortMode := SortMode.up
}

**************************************************************************
** RowOverlayPane
**************************************************************************
@Js
internal class RowOverlayPane : Pane
{
  new make(RowCanvas canvas, RowOverlayCanvas overlay)
  {
    add(this.canvas = canvas)
    add(this.overlay = overlay)

    this.onMouseDown.add  |e| { canvas.handleMouseDown(e) }
    this.onMouseUp.add    |e| { canvas.handleMouseUp(e) }
    this.onMouseMove.add |e|  { canvas.handleMouseMove(e) }
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    canvas.prefSize(hints)
  }

  override Void onLayout()
  {
    children.each |kid|
    {
      kid.pos = Point.defVal
      kid.size = size
    }
  }

  private RowCanvas canvas
  private RowOverlayCanvas overlay
}

**************************************************************************
** HeaderCanvas
**************************************************************************
@Js
internal class HeaderCanvas : Canvas
{
  new make(CanvasTable table)
  {
    this.table = table
    this.onMouseUp.add |e| { handleMouseUp(e) }
  }

  ** Horizontal scroll offset.
  Int scrollX := 0

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(600, rowh)
  }

  override Void onPaint(Graphics g)
  {
    g.font = font
    ty := (rowh - font.height) / 2
    dx := 1

    // background
    g.brush = whiteGlossBg
    g.fillRect(0, 0, size.w, size.h)

    // cols
    g.translate(-scrollX, 0)
    table.colw.each |cw,i|
    {
      sort := table.sortCol == i

      g.brush = Color.black
      g.push
      g.clip(Rect(dx, 0, sort ? cw-16 : cw, rowh))
      g.drawText(table.colNames[i], dx+4, ty)
      g.pop

      if (sort)
      {
        ax := dx + cw - 12
        g.brush = arrow
        g.translate(ax, ay)
        g.fillPolygon(table.sortMode == SortMode.up ? upArrow : downArrow)
        g.translate(-ax, -ay)
      }

      dx += cw
      if (i < table.colw.size-1)
      {
        g.brush = border
        g.drawLine(dx-1, 0, dx-1, rowh)
      }
    }

    g.translate(scrollX, 0)
    g.brush = outer
    g.drawRect(0, 0, size.w-1, size.h) // hide bottom
  }

  private Void handleMouseUp(Event e)
  {
    col := table.toColIndex(e.pos.x)
    if (col != null)
    {
      table.sortMode = table.sortCol == col
        ? table.sortMode.toggle
        : SortMode.up
      table.sortCol = col
      table.onSort(col, table.sortMode)
      table.relayout
    }
  }

  private static const Int rowh     := 22
  private static const Font font    := Desktop.sysFontSmall.toBold
  private static const Color border := Color("#bdbdbd")
  private static const Color outer  := Color("#9f9f9f")
  private static const Color arrow  := Color("#666")
  private static const Gradient whiteGlossBg :=
    Gradient("0% 0%, 0% 100%, #f9f9f9, #eee 0.5, #e1e1e1 0.5, #f5f5f5")

  private static const Int ay := (rowh - 7) / 2 + 1
  private static const Point[] upArrow := [
    Point(0, 7),
    Point(4, 0),
    Point(8, 7)
  ]
  private static const Point[] downArrow := [
    Point(0, 0),
    Point(4, 7),
    Point(8, 0)
  ]

  private CanvasTable table
}

**************************************************************************
** RowCanvas
**************************************************************************
@Js
internal class RowCanvas : WebCanvas
{
  new make(CanvasTable table)
  {
    this.table = table
    this.clearOnRepaint = false
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    pw := 10  // +10 for WebScrollPane scrollbar
    ph := 0
    table.colWidths.each |cw| { pw += (cw as Int) ?: 0 }
    table.numRows.times |i| { ph += table.rowHeight(i) }
    return Size(pw, ph)
  }

  override Void onPaint(Graphics g)
  {
    // only repaint selected row
    if (repaintSelected != null)
    {
      // clear old selection
      if (repaintSelected >= 0)
        paintRow(g, repaintSelected, table.rowb[repaintSelected])

      // paint new selection
      if (!table.selected.isEmpty)
        paintRow(g, table.selected.first, table.rowb[table.selected.first])

      // reset and bail
      repaintSelected = null
      return
    }

    // paint every row
    table.rowb.each |b,r| { paintRow(g, r, b) }
  }

  ** Paint row.
  private Void paintRow(Graphics g, Int r, Rect bounds)
  {
    sel := r == table.selected.first

    g.push
    g.translate(0, bounds.y)
    g.clip(Rect(0, 0, size.w, bounds.h))

    // background
    g.brush = sel
      ? table.rowSelectedBg
      : (r.isOdd ? table.rowOddBg : table.rowEvenBg)
    g.fillRect(0, 0, size.w, bounds.h)

    // paint cells
    dx := 0
    table.colw.each |cw, c|
    {
      // paint cell
      g.push
      g.translate(dx, 0)
      g.clip(Rect(0, 0, cw, bounds.h))
      table.paintCell(g, c, r, sel, Size(cw, bounds.h))

      // border
      if (c < table.colw.size-1)
      {
        g.brush = sel ? table.cellSelectedBorder : table.cellBorder
        g.drawLine(cw-1, 0, cw-1, bounds.h-1)
      }

      // advance col
      dx += cw
      g.pop
    }

    // border
    g.brush = table.rowBorder
    g.drawLine(0, bounds.h-1, size.w, bounds.h-1)
    g.pop
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  internal Void handleMouseDown(Event e)
  {
    if (e.count == 2)
    {
      table.fireAction
      return
    }
  }

  internal Void handleMouseUp(Event e)
  {
    row := toRowIndex(e)
    if (row == null)
    {
      // clear selection
      updateSelected(null)
    }
    else
    {
      updateSelected(row)

      // pos relative to cell
      col  := table.toColIndex(e.pos.x)
      pos  := toCellPos(e.pos, col, row)
      size := toCellSize(col, row)
      table.onCellPressed(e, col, row, pos, size)
    }
  }

  internal Void handleMouseMove(Event e)
  {
    row := toRowIndex(e)
    if (row == null) return

    col  := table.toColIndex(e.pos.x)
    pos  := toCellPos(e.pos, col, row)
    size := toCellSize(col, row)
    table.onCellMoved(e, col, row, pos, size)
  }

  internal Void updateSelected(Int? newSelected)
  {
    if (!table.selectionEnabled) return
    repaintSelected = table.selected.first ?: -1
    table.selected = newSelected==null ? [,] : [newSelected]
    repaint
  }

  private Int? toRowIndex(Event e)
  {
    table.rowb.findIndex |r| { r.contains(0, e.pos.y) }
  }

  private Point toCellPos(Point p, Int col, Int row)
  {
    x := 0
    y := 0
    col.times |i| { x += table.colw[i] }
    row.times |i| { y += table.rowb[i].h }
    return Point(p.x-x, p.y-y)
  }

  private Size toCellSize(Int col, Int row)
  {
    Size(table.colw[col], table.rowHeight(row))
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private CanvasTable table
  private Int? repaintSelected
}

**************************************************************************
** RowOverlayCanvas
**************************************************************************
@Js
internal class RowOverlayCanvas : WebCanvas
{
  new make(CanvasTable table)
  {
    this.table = table
  }

  override Void onPaint(Graphics g)
  {
    table.rowb.each |bounds, r|
    {
      sel := r == table.selected.first

      g.push
      g.translate(0, bounds.y)
      g.clip(Rect(0, 0, size.w, bounds.h))

      dx := 0
      table.colw.each |cw, c|
      {
        // paint cell overlay
        g.push
        g.translate(dx, 0)
        g.clip(Rect(0, 0, cw, bounds.h))
        table.paintCellOverlay(g, c, r, sel, Size(cw, bounds.h))

        // advance col
        dx += cw
        g.pop
      }

      g.pop
    }
  }

  private CanvasTable table
}