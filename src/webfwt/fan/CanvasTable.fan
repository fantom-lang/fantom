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
abstract class CanvasTable : Canvas
{

//////////////////////////////////////////////////////////////////////////
// Construction
/////////////////////////////////////////////////////////////////////////

  ** Constructor.
  new make(|This|? f)
  {
    if (f != null) f(this)

    this.headerhDef = 22.max(headerFont.height + headerFont.ascent + headerFont.descent)
    this.ay = (headerhDef - 7) / 2 + 1

    this.onKeyDown.add |e| { handleKeyDown(e) }
    this.onMouseMove.add  |e| { handleMouse(e) }
    this.onMouseDown.add  |e| { handleMouse(e) }
    this.onMouseUp.add    |e| { handleMouse(e) }
    this.onMouseWheel.add |e| { handleMouse(e) }
  }

  ** Column names.
  const Str[] colNames := [,]

  ** Column widths. Integer values represent exact widths.  Float
  ** values represent a percentage of remaining space (0..1).
  const Num[] colWidths := [,]

  ** Wrap the column names
  const Bool colNameWrap

  ** Is selection enabled for this table.
  Bool selectionEnabled := true

  ** Selected table index.
  Int[] selected := [,]

  ** Number of pixels to scroll when scrollbar track is paged.
  Int scrollPage := 120

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
    x := rowsetBounds.x - hscroll.cur + pos.x
    y := rowsetBounds.y - vscroll.cur + pos.y
    col.times |i| { x += colw[i] }
    row.times |i| { y += rowb[i].h }
    return Point(x, y)
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  ** Get number of rows in table.
  abstract Int numRows()

  ** Get height for row at given index.
  abstract Int rowHeight(Int i)

  ** Paint the cell at given index.
  abstract Void paintCell(Graphics g, Int col, Int row, Bool selected, Size cellSize)

  ** Paint the cell overlay at given index.
  virtual Void paintCellOverlay(Graphics g, Int col, Int row, Bool selected, Size cellSize) {}

  ** Repaint only the overaly layers.
  Void repaintOverlay() { repaint }

//////////////////////////////////////////////////////////////////////////
// Config
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

  ** Font for header columns.
  private static const Font defHeaderFont
  static
  {
    if ("js" === Env.cur.runtime) defHeaderFont = Desktop.sysFontSmall.toBold
    else defHeaderFont = Font("bold 8pt Helvetica")
  }
  const Font headerFont := defHeaderFont
  
//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  @NoDoc Void onLayout()
  {
    // layout header assuming no wrap
    headerh = headerhDef
    dw := layoutHeader

    // if we have a wrap, then we need to compute how col names fit
    colText = Str[][,]
    if (colNameWrap)
    {
      // compute each column
      maxLines := 1
      colNames.each |colName, i|
      {
        lines := wrapCol(colName, colw[i])
        maxLines = maxLines.max(lines.size)
        colText.add(lines)
      }

      // update heaederh and relayout header
      headerh = headerhDef + (maxLines-1) * headerFont.height
      dw = layoutHeader
    }

    // if no wrap, then we have one line per column
    else
    {
      colNames.each |n| { colText.add([n]) }
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

    // max scroll bounds
    vscroll.max = dy - rowsetBounds.h - 1; vscroll.layout
    hscroll.max = dw - rowsetBounds.w - 1; hscroll.layout
  }

  private Int layoutHeader()
  {
    w := size.w-1
    h := size.h-1
    headerBounds   = Rect(0, 0, w, headerh)
    vscroll.bounds = Rect(w-scrollsz, headerh+1, scrollsz, h-headerh-scrollsz-2)
    hscroll.bounds = Rect(0, h-scrollsz, w-scrollsz-1, scrollsz)
    rowsetBounds   = Rect(0, headerh+1, w-scrollsz-1, h-headerh-scrollsz-2)

    // layout cols
    cs := (Int)colWidths.reduce(0) |Int v,c| { v + (c as Int ?: 0) }
    rw := rowsetBounds.w - cs
    dw := 0
    fc := false
    colw.clear
    colWidths.each |c,i|
    {
      cw := 0
      if (c is Int) cw = c
      else { cw = (rw * c.toFloat).toInt; fc=true }
      if (fc && i == colWidths.size-1) cw = rowsetBounds.w - dw + 1
      colw.add(cw)
      dw += cw
    }

    return dw
  }

  private Str[] wrapCol(Str colName, Int colw)
  {
    colw = colw - 8 // margin is 4
    words := colName.split(' ')
    first := words.first

    // first word goes on first line
    cur := StrBuf().add(first)
    curw := headerFont.width(first)
    spacew := headerFont.width(" ")

    // add rest of the words
    lines := Str[,]
    for (i:=1; i<words.size; ++i)
    {
      word := words[i]
      wordw := headerFont.width(word)
      neww := curw + spacew + wordw
      if (neww <= colw)
      {
        // fits on current line
        cur.add(" ").add(word)
        curw = neww
      }
      else
      {
        // wrap to next line
        lines.add(cur.toStr)
        cur = StrBuf().add(word)
        curw = wordw
      }
    }
    lines.add(cur.toStr)
    return lines
  }

//////////////////////////////////////////////////////////////////////////
// Render
//////////////////////////////////////////////////////////////////////////

  override Void onPaint(Graphics g)
  {
    if (!repaintNoLayout) onLayout
    repaintNoLayout = false

    g.brush = Color.white
    g.fillRect(0, 0, size.w, size.h)

    paintHeader(g)
    paintScrollBars(g)

    g.push
    clip(g, rowsetBounds)
    g.translate(0, headerh+1)

    nrows := numRows
    rx := -hscroll.cur
    ry := -vscroll.cur
    g.translate(rx, ry)

    for (r:=0; r<nrows; r++)
    {
      rh := rowHeight(r)
      if (ry + rh > 0) paintRow(g, r, rh, nrows)

      ry += rh
      if (ry > rowsetBounds.h) break
      g.translate(0, rh)
    }

    g.pop
    g.brush = border
    g.drawRect(0, 0, size.w-1, size.h-1)
  }

  ** Paint column headers.
  private Void paintHeader(Graphics g)
  {
    g.font = headerFont
    w  := size.w
    h  := headerBounds.h
    dx := 0

    // header background
    // TODO: cache brush based on size
    g.brush = Gradient { x1=0; y1=0; x2=0; y2=h; stops=headerStops }
    g.fillRect(0, 0, w, h)

    // cols
    g.push
    g.translate(-hscroll.cur, 0)
    colw.each |cw,i|
    {
      tx := dx+4+(i==0?1:0)
      ty := (headerhDef - headerFont.height) / 2

      sort := sortCol == i

      g.brush = Color.black
      g.push
      g.clip(Rect(dx, 0, sort ? cw-16 : cw, h))
      colLines := colText[i]
      colLines.each |line, j|
      {
        g.drawText(line, tx, ty)
        ty += headerFont.height
      }
      g.pop

      if (sort)
      {
        ax := dx + cw - 12
        g.brush = headerArrow
        g.translate(ax, ay)
        g.fillPolygon(sortMode == SortMode.up ? upArrow : downArrow)
        g.translate(-ax, -ay)
      }

      dx += cw
      if (i < colw.size-1)
      {
        g.brush = headerBorder
        g.drawLine(dx-1, 0, dx-1, h)
      }
    }
    g.pop

    // border
    g.brush = border
    g.drawRect(0, 0, w-1, h)  // hide bottom
  }

  ** Paint scrollbars.
  private Void paintScrollBars(Graphics g)
  {
    vb := vscroll.bounds
    hb := hscroll.bounds
    g.brush = scrollBoxBg
    g.fillRect(vb.x, hb.y, vb.w, hb.h)

    // vert
    g.brush = Gradient { x1=vb.x+1; y1=0; x2=vb.x+vb.w-2; y2=0; stops=scrollTrackStops }
    g.fillRect(vb.x, vb.y, vb.w, vb.h+1)

    if (vscroll.max > 0)
    {
      tb := vscroll.thumb
      ty := tb.y + (tb.h / 2)
      g.brush = Gradient { x1=vb.x+1; y1=0; x2=vb.x+vb.w-2; y2=0; stops=scrollThumbStops }
      g.fillRoundRect(vb.x+1, vb.y+ty+1, vb.w-1, tb.h-2, 5, 5)
    }

    g.brush = border
    g.drawLine(vb.x, vb.y, vb.x, size.h)

    // horiz
    g.brush = Gradient { x1=0; y1=hb.y+1; x2=0; y2=hb.y+hb.h-2; stops=scrollTrackStops }
    g.fillRect(hb.x, hb.y, hb.w+1, hb.h)

    if (hscroll.max > 0)
    {
      tb := hscroll.thumb
      tx := tb.x + (tb.w / 2)
      g.brush = Gradient { x1=0; y1=hb.y+1; x2=0; y2=hb.y+hb.h-2; stops=scrollThumbStops }
      g.fillRoundRect(hb.x+tx+2, hb.y+1, tb.w-3, hb.h-1, 5, 5)
    }

    g.brush = border
    g.drawLine(hb.x, hb.y, size.w+1, hb.y)
  }

  ** Paint given row.
  private Void paintRow(Graphics g, Int r, Int rowh, Int nrows)
  {
    sel := r == selected.first
    w := rowsetBounds.w + hscroll.max + 1
    h := rowh

    g.push
    g.clip(Rect(0, 0, w, h))

    // background
    g.brush = sel ? rowSelectedBg : (r.isOdd ? rowOddBg : rowEvenBg)
    g.fillRect(0, 0, w, h)

    // paint cells
    dx := 0
    colw.each |cw, c|
    {
      // skip if not visible
      if (dx-hscroll.cur > rowsetBounds.w) return

      // paint cell if visible
      if (dx+cw > hscroll.cur)
      {
        g.push
        g.translate(dx, 0)
        g.clip(Rect(0, 0, cw, h))
        csz := Size(cw, h)
        paintCell(g, c, r, sel, csz)
        paintCellOverlay(g, c, r, sel, csz)

        // border
        if (c < colw.size-1)
        {
          g.brush = sel ? cellSelectedBorder : cellBorder
          g.drawLine(cw-1, 0, cw-1, h-1)
        }
        g.pop
      }

      // advance col
      dx += cw
    }

    // border
    if (r < nrows-1 || vscroll.max == 0)
    {
      g.brush = rowBorder
      g.drawLine(0, h-1, w, h-1)
    }
    g.pop
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  private Void handleMouse(Event e)
  {
    switch (e.id)
    {
      case EventId.mouseWheel:
        if (e.delta.x == 0) vscroll.scroll(e.delta.y)
        else hscroll.scroll(e.delta.x)
        e.consumed = true

      case EventId.mouseMove:
        if (vscroll.dragDelta != null) mouseDragVScroll(e)
        else if (hscroll.dragDelta != null) mouseDragHScroll(e)
        else if (contains(rowsetBounds, e.pos)) mouseMoveRowset(e)

      case EventId.mouseDown:
        if (contains(vscroll.bounds, e.pos)) mouseDownVScroll(e)
        else if (contains(hscroll.bounds, e.pos)) mouseDownHScroll(e)
        else if (contains(headerBounds, e.pos)) mouseDownHeader(e)
        else if (contains(rowsetBounds, e.pos)) mouseDownRowset(e)

      case EventId.mouseUp:
        if (vscroll.dragDelta != null) vscroll.dragDelta = null
        else if (hscroll.dragDelta != null) hscroll.dragDelta = null
        else if (contains(headerBounds, e.pos)) mouseUpHeader(e)
        else if (contains(rowsetBounds, e.pos)) mouseUpRowset(e)
    }
  }

  private Void handleKeyDown(Event e)
  {
    switch (e.key)
    {
      case Key.up:
        i := ((selected.first ?: 1) - 1).max(0)
        updateSelected(i)
        e.consume

      case Key.down:
        i := ((selected.first ?: -1) + 1).min(numRows-1)
        updateSelected(i)
        e.consume

      case Key.space: fireAction
    }
  }

//////////////////////////////////////////////////////////////////////////
// Scroll Events
//////////////////////////////////////////////////////////////////////////

  private Void mouseDownVScroll(Event e)
  {
    pos := vscroll.toPos(e.pos.y, true)
    cy  := vscroll.bounds.y + vscroll.thumb.y + vscroll.thumb.h
    if (pos != null) vscroll.dragDelta = e.pos.y - cy
    else vscroll.scroll(e.pos.y < cy ? -scrollPage : scrollPage)
    e.consumed = true
  }

  private Void mouseDragVScroll(Event e)
  {
    pos := vscroll.toPos(e.pos.y - vscroll.dragDelta)
    vscroll.pos(pos)
    e.consumed = true
  }

  private Void mouseDownHScroll(Event e)
  {
    pos := hscroll.toPos(e.pos.x, true)
    cx  := hscroll.bounds.x + hscroll.thumb.x + hscroll.thumb.w
    if (pos != null) hscroll.dragDelta = e.pos.x - cx
    else hscroll.scroll(e.pos.x < cx ? -scrollPage : scrollPage)
    e.consumed = true
  }

  private Void mouseDragHScroll(Event e)
  {
    pos := hscroll.toPos(e.pos.x - hscroll.dragDelta)
    hscroll.pos(pos)
    e.consumed = true
  }

//////////////////////////////////////////////////////////////////////////
// Header
//////////////////////////////////////////////////////////////////////////

  private Void mouseDownHeader(Event e)
  {
  }

  private Void mouseUpHeader(Event e)
  {
    col := toColIndex(e.pos.x)
    sortMode = sortCol==col ? sortMode.toggle : SortMode.up
    sortCol = col
    onSort(col, sortMode)
    relayout
  }

//////////////////////////////////////////////////////////////////////////
// Rowset
//////////////////////////////////////////////////////////////////////////

  private Void mouseMoveRowset(Event e)
  {
    row := toRowIndex(e)
    if (row == null) return

    col  := toColIndex(e.pos.x)
    pos  := toCellPos(e.pos, col, row)
    size := toCellSize(col, row)
    onCellMoved(e, col, row, pos, size)
  }

  private Void mouseDownRowset(Event e)
  {
    if (e.count == 2) fireAction
  }

  private Void mouseUpRowset(Event e)
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
      col  := toColIndex(e.pos.x)
      pos  := toCellPos(e.pos, col, row)
      size := toCellSize(col, row)
      onCellPressed(e, col, row, pos, size)
    }
  }

  private Void updateSelected(Int? newSelected)
  {
    if (!selectionEnabled) return
    if (selected.first == newSelected) return
    selected = newSelected==null ? [,] : [newSelected]
    repaintNoLayout = true
    repaint
  }

  private Void fireAction()
  {
    i := selected.first
    if (i == null) return
    onAction.fire(Event { id=EventId.action; widget=this; index=i })
  }

  private Int? toRowIndex(Event e)
  {
    my := vscroll.cur + e.pos.y - rowsetBounds.y + 2
    return rowb.findIndex |r| { r.contains(0, my) }
  }

  private Int? toColIndex(Int x)
  {
    dx := 0
    x += hscroll.cur
    c := colw.findIndex |w|
    {
      dx += w
      return x < dx
    }
    return c==null ? colw.size-1 : c
  }

  private Point toCellPos(Point p, Int col, Int row)
  {
    x := rowsetBounds.x - hscroll.cur
    y := rowsetBounds.y - vscroll.cur
    col.times |i| { x += colw[i] }
    row.times |i| { y += rowb[i].h }
    return Point(p.x-x, p.y-y)
  }

  private Size toCellSize(Int col, Int row)
  {
    Size(colw[col], rowHeight(row))
  }

//////////////////////////////////////////////////////////////////////////
// GxUtil
//////////////////////////////////////////////////////////////////////////

  ** Clip graphics cx to allow for full Rect bounds.
  private Void clip(Graphics g, Rect r)
  {
    g.clip(Rect(r.x, r.y, r.w+1, r.h+1))
  }

  ** Returns true of Rect contains Point.
  private Bool contains(Rect r, Point p)
  {
    r.contains(p.x, p.y)
  }

//////////////////////////////////////////////////////////////////////////
// Constants
//////////////////////////////////////////////////////////////////////////

  private static const Color border := Color("#9f9f9f")

  private static const Color headerBorder := Color("#bdbdbd")
  private static const Color headerArrow  := Color("#666")
  private static const GradientStop[] headerStops := [
    GradientStop(Color("#f9f9f9"), 0f),
    GradientStop(Color("#eee"),    0.5f),
    GradientStop(Color("#e1e1e1"), 0.5f),
    GradientStop(Color("#f5f5f5"), 1f),
  ]

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

  private static const Int scrollsz := 12
  private static const Color scrollBoxBg := Color("#eee")
  private static const GradientStop[] scrollTrackStops := [
    GradientStop(Color("#eaeaea"), 0f),
    GradientStop(Color("#f8f8f8"), 1f)
  ]
  private static const Color scrollThumbBorder := Color("#848fa6")
  private static const GradientStop[] scrollThumbStops := [
    GradientStop(Color("#b5bfcd"), 0f),
    GradientStop(Color("#8b99b2"), 1f)
  ]

//////////////////////////////////////////////////////////////////////////
// HTML
//////////////////////////////////////////////////////////////////////////

  ** Write HTML markup for this cell.
  virtual Void writeHtml(WebOutStream out, Int col, Int row) {}

  ** Render cell as PNG image encoded as Base64 and write to HTML.
  Void writePng(WebOutStream out, Int col, Int row)
  {
    if ("js" === Env.cur.runtime) ColUtil.writePng(this, out, col, row)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const private Int headerhDef
  const private Int ay

  private Int[] colw := [,]
  private Rect[] rowb := [,]
  private Int? sortCol := null
  private SortMode sortMode := SortMode.up

  private Rect headerBounds   := Rect.defVal
  internal Rect rowsetBounds  := Rect.defVal
  private CTScrollBar vscroll := CTScrollBar { table=this }
  private CTScrollBar hscroll := CTScrollBar { table=this; orient=Orientation.horizontal }
  private Int headerh       // header height with wrap applied
  private Str[][]? colText  // col name lines with wrap applied

  // repaint with no relayout
  internal Bool repaintNoLayout := false
}

**************************************************************************
** CTScrollBar
**************************************************************************
@Js
internal class CTScrollBar
{
  Void scroll(Int ds)
  {
    // short-circuit if not scrollable, or if already at min/max
    if (max < 0) return
    if (cur == 0 && ds < 0) return
    if (cur == max && ds > 0) return

    cur += ds
    cur = cur.max(0).min(max)
    layout
    table.repaintNoLayout = true
    table.repaint
  }

  Int? toPos(Int pixel, Bool inThumb := false)
  {
    if (isVert)
    {
      dy := pixel - bounds.y - thumb.h / 2
      if (inThumb && !thumb.contains(0, dy)) return null
      return (dy.toFloat / (table.rowsetBounds.h - thumb.h).toFloat * max).toInt
    }
    else
    {
      dx := pixel - bounds.x - thumb.w / 2
      if (inThumb && !thumb.contains(dx, 0)) return null
      return (dx.toFloat / (table.rowsetBounds.w - thumb.w).toFloat * max).toInt
    }
  }

  Void pos(Int p)
  {
    // short-ciruct if not scrollbale, or if already at min/max
    if (max < 0) return
    if (cur == 0 && p < 0) return
    if (cur == max && p > max) return

    cur = p.max(0).min(max)
    layout
    table.repaintNoLayout = true
    table.repaint
  }

  Bool isVert() { orient == Orientation.vertical }

  Void layout()
  {
    if (isVert)
    {
      rh := table.rowsetBounds.h
      vh := (rh.toFloat / (rh + max).toFloat * rh).toInt.max(20)
      vy := (cur.toFloat / max.toFloat * (rh-vh)).toInt.max(0) - (vh / 2)
      thumb = Rect(0, vy, bounds.w, vh)
    }
    else
    {
      rw := table.rowsetBounds.w
      hw := (rw.toFloat / (rw + max).toFloat * rw).toInt.max(20)
      hx := (cur.toFloat / max.toFloat * (rw-hw)).toInt.max(0) - (hw / 2)
      thumb = Rect(hx, 0, hw, bounds.h)
    }
  }

  CanvasTable? table
  Orientation orient := Orientation.vertical
  Rect bounds := Rect.defVal  // scrollbar bounds
  Rect thumb  := Rect.defVal  // thumb bounds
  Int cur := 0                // cur scroll pos
  Int max := 0                // max scroll pos
  Int? dragDelta              // if dragging delta to apply
}

**************************************************************************
** ColUtil
**************************************************************************
@Js
internal final class ColUtil
{
  native static Void writePng(CanvasTable table, WebOutStream out, Int col, Int row)
}
