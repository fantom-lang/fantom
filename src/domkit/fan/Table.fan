//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Sep 2015  Andy Frank  Creation
//

using dom
using graphics

**
** Table displays a grid of rows and columns.
**
** See also: [docDomkit]`docDomkit::Controls#table`
**
@Js class Table : Elem
{
  ** Constructor.
  new make() : super("div")
  {
    this->tabIndex = 0
    this.view = TableView(this)
    this.sel  = TableSelection(view)
    this.style.addClass("domkit-Table").addClass("domkit-border")
    this.onEvent("wheel", false) |e|
    {
      // don't consume vertical scroll if not required; this
      // allows the parent container to scroll the table within
      // its own viewport; this is a little tricky without
      // consume horiz events, so for now just assume it was a
      // "vertical" event if y-delta is greater than x-delta
      if (!hasScrolly && e.delta != null && e.delta.y.abs > e.delta.x.abs) return

      onScroll(e.delta)
      e.stop
    }
    this.onEvent("mousedown", false) |e| { onMouseEvent(e) }
    this.onEvent("mouseup",   false) |e| { onMouseEvent(e) }
    this.onEvent("mousemove", false) |e| { onMouseEvent(e) }
    this.onEvent("dblclick",  false) |e| { onMouseEvent(e) }
    this.onEvent("keydown",   false) |e| { onKeyEvent(e) }

    // manually track focus so we can detect when
    // the browser window becomes unactive while
    // maintaining focus internally in document
    this.onEvent("focus", false) |e| { if (!manFocus) { manFocus=true; refresh }}
    this.onEvent("blur",  false) |e| { manFocus=false; refresh }

    // rebuild if size changes
    DomListener.cur.onResize(this) { rebuild }
  }

  ** Model for this table.
  TableModel model := TableModel()
  {
    set { &model=it; view.refresh }
  }

  ** Is the table header visible.
  Bool showHeader := true

  ** List of CSS classes applied to rows in sequence, looping as required.
  Str[] stripeClasses := ["even", "odd"]

  ** Callback to display header popup.  When non-null, a button will be
  ** placed on the right-hand side of the table header to indicate the
  ** popup is available.
  Void onHeaderPopup(|Table->Popup| f) { this.cbHeaderPopup = f }

  ** The view wraps the table model to implement the row/col mapping
  ** from the view coordinate space to the model coordinate space based
  ** on column visibility and row sort order.
  @NoDoc TableView view { private set }

  ** The column index by which the table is currently sorted, or null
  ** if the table is not currently sorted by a column.  See `sort`.
  Int? sortCol() { view.sortCol }

  ** Return if the table is currently sorting up or down.  See `sort`.
  Dir sortDir() { view.sortDir }

  ** Sort a table by the given column index. If col is null, then
  ** the table is ordered by its natural order of the table model.
  ** Sort order is determined by `TableModel.sortCompare`.  Sorting
  ** does not modify the indexing of TableModel, it only changes how
  ** the model is viewed.  Also see `sortCol` and `sortDir`.  Table
  ** automatically refreshed.
  Void sort(Int? col, Dir dir := Dir.up)
  {
    pivot = null
    view.sort(col, dir)
    model.onSort(col, dir)
    refresh
    cbSort?.call(this)
  }

  ** Scroll to the given row and column in table.  Pass 'null' to
  ** maintain the current scroll position for that axis.
  Void scrollTo(Int? col, Int? row)
  {
    // force viewport bounds
    if (numCols == 0 || colx.last + colw.last <= tbodyw) col = null
    if (numRows < numVisRows) row = null

    // update horiz scroll and row position
    if (col != null)
    {
      col = col.max(0).min(numCols-1)
      rx   := colx[col]
      rw   := colw[col]
      maxx := maxScrollx - tbodyw
      if (hasScrolly) maxx += overScroll
// echo("# scollTo: $col -> $rx:$rw $maxx [$scrollx:$maxScrollx]")
      col = col.min(numCols - numVisCols).max(0)
      scrollx = rx.min(maxx)
    }

    // update vert scroll and row position
    if (row != null)
    {
      row = row.max(0).min(numRows-1)
      ry   := row * rowh
      miny := scrolly
      maxy := scrolly + tbodyh - rowh
      if (hasScrollx) maxy -= overScroll
// echo("# scollTo: $row -> $ry min:$miny max:$maxy [$scrolly]")
      if (ry >= miny && ry <= maxy)
      {
        // already in view
        row = null
      }
      else if (ry < scrolly)
      {
        // scroll row into view
        scrolly = ry
      }
      else
      {
        // set first visible row, scroll last row into view
        scrolly = scrolly + (ry - maxy)
        row = (scrolly / rowh).min(numRows - numVisRows).max(0)
      }
    }

    // update content
    onUpdate(col ?: firstVisCol, row ?: firstVisRow)
  }

  ** Selection for table
  Selection sel { private set }

  ** Callback when selection has changed but before taking effect.
  @NoDoc Void onBeforeSelect(|Int[]->Bool| f) { cbBeforeSelect = f }

  ** Callback when selection has changed.
  Void onSelect(|This| f) { cbSelect = f }

  ** Callback when row is double-clicked.
  Void onAction(|This| f) { cbAction = f }

  ** Callback when table is sorted by a column
  Void onSort(|This| f) { cbSort = f }

  ** Callback when a key is pressed in table.
  // TODO: need to fix to take |This,Event| arg...
  @NoDoc Void onKeyDown(|Event| f) { cbKeyDown = f }

  ** Callback when a event occurs inside a table cell.
  Void onTableEvent(Str type, |TableEvent| f) { cbTableEvent[type] = f }

//////////////////////////////////////////////////////////////////////////
// Update
//////////////////////////////////////////////////////////////////////////

  ** Subclass hook to run when `rebuild` is invoked.
  @NoDoc protected virtual Void onBeforeRebuild() {}

  ** Rebuild table layout.
  Void rebuild()
  {
    if (this.size.w > 0f) doRebuild
    else Win.cur.setTimeout(16ms) |->| { rebuild }
  }

  ** Refresh table cell content.
  Void refresh()
  {
    refreshHeaders
    numVisRows.times |r|
    {
      row := firstVisRow + r
      refreshRow(row)
    }
  }

  ** Refresh all header content.
  private Void refreshHeaders()
  {
    numVisCols.times |c|
    {
      col    := firstVisCol + c
      header := headers[col]
      if (header == null) return
      refreshHeader(header, col)
    }
  }

  ** Refresh single header content.
  private Void refreshHeader(Elem? header, Int col)
  {
    header = header ?: headers[col]
    if (header == null) throw Err("Header not found: $col")

    // update static style
    header.style.removeClass("last")
    if (col == numCols-1) header.style.addClass("last")

    // update sort icon
    if (col < numCols && view.colViewToModel(col) == view.sortCol)
    {
      header.style
        .addClass("domkit-Table-header-sort")
        .removeClass("down up popup")
        .addClass(sortDir == Dir.up ? "up" : "down")
      if (col == numCols-1 && hasHpbut) header.style.addClass("popup")
    }
    else
    {
      header.style
        .removeClass("domkit-Table-header-sort")
        .removeClass("down up popup")
    }

    // update model content
    if (col < numCols) view.onHeader(header, col)
  }

  ** Refresh single row content.
  internal Void refreshRow(Int row)
  {
    // short-circuit if not in view
    if (row < firstVisRow || row > firstVisRow + numVisRows) return

    numVisCols.times |c|
    {
      col  := firstVisCol + c
      pos  := TablePos(col, row)
      cell := cells[pos]
      if (cell == null) return
      refreshCell(cell, pos.col, pos.row)
    }
  }

  ** Refresh single cell content.
  private Void refreshCell(Elem? cell, Int col, Int row)
  {
    // get cell
    cell = cell ?: cells[TablePos(col, row)]
    if (cell == null) throw Err("Cell not found: $col,$row")

    // update static view style
    cell.style.removeClass("last").removeClass("domkit-sel")
    if (stripeClasses.size > 0)
    {
      stripeClasses.each |c| { cell.style.removeClass(c) }
      cell.style.addClass(stripeClasses[row % stripeClasses.size])
    }
    if (col == numCols-1) cell.style.addClass("last")

    // update model content
    if (col < numCols && row < numRows)
    {
      rowSel := sel.indexes.binarySearch(view.rowViewToModel(row)) >= 0
      if (rowSel) cell.style.addClass("domkit-sel")

      flags := TableFlags
      {
        it.focused  = manFocus
        it.selected = rowSel
      }

      view.onCell(cell, col, row, flags)
    }
  }

  ** Callback from refresh with valid layout dimensions.
  private Void doRebuild()
  {
    // subclass rebuild hook
    onBeforeRebuild

    // update view first so downstream checks work properly
    view.refresh
    view.sort(view.sortCol, view.sortDir)
    this.numCols = view.numCols
    this.numRows = view.numRows

    // refresh sel and reset dom caches
    sel.refresh
    headers.clear
    cells.clear

    // get container dims
    tbodysz := this.size
    this.theadh  = showHeader ? view.headerHeight : 0
    this.tbodyw  = tbodysz.w.toInt
    this.tbodyh  = tbodysz.h.toInt - theadh

    // cache layout vars
    cx := 0
    this.colx.clear
    this.colw.clear
    this.numCols.times |c|
    {
      cw := ucolw[c] ?: view.colWidth(c)
      if (c == numCols-1 && hasHpbut) cw += hpbutw + 4
      this.colx.add(cx)
      this.colw.add(cw)
      cx += cw
    }
    this.rowh    = view.rowHeight
    this.numVisCols = findMaxVisCols + 2
    this.numVisRows = tbodyh / rowh + 2

    // setup scrollbox
    this.scrollx = 0
    this.scrolly = 0
    this.maxScrollx = colw.reduce(0) |Int r, Int w->Int| { r + w }
    this.maxScrolly = numRows * rowh
    this.firstVisCol = 0
    this.firstVisRow = 0

    // setup scrollbars
    this.hasScrollx = maxScrollx > tbodyw
    this.hasScrolly = maxScrolly > tbodyh
    this.hbar = makeScrollBar(Dir.right)
    this.vbar = makeScrollBar(Dir.down)

    // expand to table width if needed
    if (maxScrollx <= tbodyw)
    {
      if (numCols == 0) this.numVisCols = 0
      else
      {
        this.numVisCols = numCols
        this.colw[-1] = tbodyw - colx.last
      }
    }
    else if (hasScrolly)
    {
      this.colw[-1] += overScroll
    }

    // // debug
    // echo("# Table.refresh
    //       #    tbodyw:      $tbodyw
    //       #    tbodyh:      $tbodyh
    //       #    numCols:     $numCols
    //       #    numRows:     $numRows
    //       #    rowh:        $rowh
    //       #    numVisCols:  $numVisCols
    //       #    numVisRows:  $numVisRows
    //       #    maxScrollx:  $maxScrollx
    //       #    maxScrolly:  $maxScrolly
    //       ")

    // setup thead
    this.thead = Elem
    {
      it.style.addClass("domkit-Table-thead")
      it.style->height = "${theadh}px"
      if (theadh == 0) it.style->display = "none"
    }
    numVisCols.times |c|
    {
      header := Elem
      {
        it.style.addClass("domkit-Table-header")
        it.style->width  = "${colwSafe(c)}px"
        it.style->lineHeight = "${theadh+1}px"
        if (c == numCols-1) it.style.addClass("last")
      }
      headers[c] = header
      refreshHeader(header, c)
      thead.add(header)
    }

    // setup header popup
    if (cbHeaderPopup == null)
    {
      this.hpbut = null
      this.hasHpbut = false
    }
    else
    {
      this.hpbut = Elem
      {
        mtop := ((theadh-21) / 2) + 3
        it.style.addClass("domkit-Table-header-popup")
        it.style->height = "${theadh}px"
        it.add(Elem { it.style->marginTop="${mtop}px" })
        it.add(Elem {})
        it.add(Elem {})
      }
      this.hasHpbut = true
      thead.add(hpbut)
    }

    // setup tbody
    this.tbody = Elem
    {
      it.style.addClass("domkit-Table-tbody")
      it.style->top = "${theadh}px"
    }
    numVisRows.times |r|
    {
      numVisCols.times |c|
      {
        // TODO FIXIT: seems like an awful lot of overlap of
        // refreshCell - should look at collapsing behavoir here
        rowSel := false
        cell := Elem
        {
          it.style.addClass("domkit-Table-cell")
          if (stripeClasses.size > 0)
            it.style.addClass(stripeClasses[r % stripeClasses.size])
          if (c == numCols-1) it.style.addClass("last")
          if (c < numCols && r < numRows)
          {
            if (sel.indexes.binarySearch(view.rowViewToModel(r)) >= 0)
            {
              it.style.addClass("domkit-sel")
              rowSel = true
            }
          }
          it.style->width = "${colwSafe(c)}px"
          it.style->height = "${rowh}px"
          it.style->lineHeight = "${rowh+1}px"
        }
        flags := TableFlags
        {
          it.focused  = manFocus
          it.selected = rowSel
        }
        cells[TablePos(c, r)] = cell
        if (c < numCols && r < numRows) view.onCell(cell, c, r, flags)
        tbody.add(cell)
      }
    }

    // update dom
    removeAll
    add(thead)
    add(tbody)
    add(hbar)
    add(vbar)
    onUpdate(0,0)
  }

  ** Create scrollbar
  private Elem makeScrollBar(Dir dir)
  {
    Elem
    {
      xsz := sbarsz - thumbMargin - thumbMargin - 1
      it.style.addClass("domkit-Table-scrollbar")
      if (dir == Dir.right)
      {
        if (!hasScrollx) it.style->visibility = "hidden"
        this.htrackw = tbodyw - (hasScrolly ? sbarsz : 0) - 2
        this.hthumbw = (tbodyw.toFloat / maxScrollx.toFloat * htrackw.toFloat).toInt.max(xsz)

        it.style->left   = "0px"
        it.style->bottom = "0px"
        it.style->width  = "${htrackw}px"
        it.style->height = "${sbarsz}px"
        it.style->borderTopWidth = "1px"
        it.onEvent("dblclick",  false) |e| { e.stop }
        it.onEvent("mouseup",   false) |e| { hbarPageId = stopScrollPage(hbarPageId) }
        it.onEvent("mouseout",  false) |e| { hbarPageId = stopScrollPage(hbarPageId) }
        it.onEvent("mousedown", false) |e| {
          e.stop
          p := e.target.relPos(e.pagePos)
          thumb := e.target.firstChild
          if (p.x < thumb.pos.x) hbarPageId = startScrollPage(Point(-tbodyw, 0))
          else if (p.x > thumb.pos.x + thumb.size.w.toInt) hbarPageId = startScrollPage(Point(tbodyw, 0))
        }

        Elem {
          it.style->margin = "${thumbMargin}px"
          it.style->top    = "0px"
          it.style->left   = "0px"
          it.style->width  = "${hthumbw}px"
          it.style->height = "${xsz}px"
          it.onEvent("dblclick",  false) |e| { e.stop }
          it.onEvent("mousedown", false) |e| {
            e.stop
            hthumbDragOff = hbar.firstChild.relPos(e.pagePos).x.toInt

            doc := Win.cur.doc
            Obj? fmove
            Obj? fup

            fmove = doc.onEvent("mousemove", true) |de| {
              dx := hbar.relPos(de.pagePos).x - hthumbDragOff
              sx := (dx.toFloat / htrackw.toFloat * maxScrollx).toInt
              onScroll(Point.makeInt(sx - scrollx, 0))
            }

            fup = doc.onEvent("mouseup", true) |de| {
              de.stop
              hthumbDragOff = null
              doc.removeEvent("mousemove", true, fmove)
              doc.removeEvent("mouseup",   true, fup)
            }
          }
        },
      }
      else
      {
        if (!hasScrolly) it.style->visibility = "hidden"
        this.vtrackh = tbodyh - (hasScrollx ? sbarsz : 0) - 2
        this.vthumbh = (tbodyh.toFloat / maxScrolly.toFloat * vtrackh.toFloat).toInt.max(xsz)

        it.style->top    = "${theadh}px"
        it.style->right  = "0px"
        it.style->width  = "${sbarsz}px"
        it.style->height = "${vtrackh}px"
        it.style->borderLeftWidth = "1px"
        it.onEvent("dblclick",  false) |e| { e.stop }
        it.onEvent("mouseup",   false) |e| { vbarPageId = stopScrollPage(vbarPageId) }
        it.onEvent("mouseout",  false) |e| { vbarPageId = stopScrollPage(vbarPageId) }
        it.onEvent("mousedown", false) |e| {
          e.stop
          p := e.target.relPos(e.pagePos)
          thumb := e.target.firstChild
          if (p.y < thumb.pos.y) vbarPageId = startScrollPage(Point(0, -tbodyh))
          else if (p.y > thumb.pos.y + thumb.size.h.toInt) vbarPageId = startScrollPage(Point(0, tbodyh))
        }

        Elem {
          it.style->margin = "${thumbMargin}px"
          it.style->top    = "0px"
          it.style->left   = "0px"
          it.style->width  = "${xsz}px"
          it.style->height = "${vthumbh}px"
          it.onEvent("dblclick",  false) |e| { e.stop }
          it.onEvent("mousedown", false) |e| {
            e.stop
            vthumbDragOff = vbar.firstChild.relPos(e.pagePos).y.toInt

            doc := Win.cur.doc
            Obj? fmove
            Obj? fup

            fmove = doc.onEvent("mousemove", true) |de| {
              dy := vbar.relPos(de.pagePos).y - vthumbDragOff
              sy := (dy.toFloat / vtrackh.toFloat * maxScrolly).toInt
              onScroll(Point.makeInt(0, sy - scrolly))
            }

            fup = doc.onEvent("mouseup", true) |de| {
              de.stop
              vthumbDragOff = null
              doc.removeEvent("mousemove", true, fmove)
              doc.removeEvent("mouseup",   true, fup)
            }
          }
        },
      }
    }
  }

  ** Start scroll page event.
  private Int? startScrollPage(Point delta)
  {
    onScroll(delta)
    return Win.cur.setInterval(scrollPageFreq) { onScroll(delta) }
  }

  ** Cancel scroll page event.
  private Int? stopScrollPage(Int? fid)
  {
    if (fid != null) Win.cur.clearInterval(fid)
    return null
  }

  ** Pulse scrollbar.
  private Void pulseScrollBar(Dir dir)
  {
    if (dir == Dir.right)
    {
      hbar.style.addClass("active")
      if (hbarPulseId != null) Win.cur.clearTimeout(hbarPulseId)
      hbarPulseId = Win.cur.setTimeout(scrollPulseDir) { hbar.style.removeClass("active") }
    }
    else
    {
      vbar.style.addClass("active")
      if (vbarPulseId != null) Win.cur.clearTimeout(vbarPulseId)
      vbarPulseId = Win.cur.setTimeout(scrollPulseDir) { vbar.style.removeClass("active") }
    }
  }

  ** Callback to update table to given starting cell position.
  private Void onUpdate(Int col, Int row)
  {
// echo("# onUpdate($col, $row)")

    // no-op if no cols
    if (numCols == 0) return

    // update scrollbars
    if (hasScrollx)
    {
      sw := maxScrollx - tbodyw + (hasScrolly ? overScroll : 0)
      sp := scrollx.toFloat / sw.toFloat
      hw := htrackw - hthumbw - (thumbMargin * 2)
      hx := (sp * hw.toFloat).toInt
      ox := hbar.firstChild.style->left.toStr[0..-3].toInt
// echo("# $scrollx:$sw @ $sp -- $hx:$hw [$ox]")
      if (ox != hx)
      {
        pulseScrollBar(Dir.right)
        hbar.firstChild.style->left = "${hx}px"
      }
    }
    if (hasScrolly)
    {
      sh := maxScrolly - tbodyh + (hasScrollx ? overScroll : 0)
      sp := scrolly.toFloat / sh.toFloat
      vh := vtrackh - vthumbh - (thumbMargin * 2)
      vy := (sp * vh.toFloat).toInt
      oy := vbar.firstChild.style->top.toStr[0..-3].toInt
// echo("# $scrolly:$sh @ $sp -- $vy:$vh [$oy]")
      if (oy != vy)
      {
        pulseScrollBar(Dir.down)
        vbar.firstChild.style->top = "${vy}px"
      }
    }

    // update cells
    thead.style->display = "none"
    tbody.style->display = "none"
    onMoveX(col)
    onMoveY(row)
    thead.style->display = theadh==0 ? "none" : ""
    tbody.style->display = ""

    // update transforms
    headers.each |h,c| {
      tx := colxSafe(c) - scrollx
      h.style->transform = "translate(${tx}px, 0)"
    }
    cells.each |c,p| {
      tx := colxSafe(p.col) - scrollx
      ty := (p.row * rowh) - scrolly
      c.style->transform = "translate(${tx}px, ${ty}px)"
    }
  }

  ** Callback to move table to given starting column.
  private Void onMoveX(Int col)
  {
    // short-circuit if nothing todo
    if (firstVisCol == col) return

    oldFirstCol := firstVisCol
    delta := col - oldFirstCol           // delta b/w old and new first col
    shift := delta.abs.max(numVisCols)   // offset to shift cols when delta > 0
    count := delta.abs.min(numVisCols)   // num of cols to move

// echo("# onMoveX
//       #   oldFirstCol: $oldFirstCol
//       #   col:         $col
//       #   delta:       $delta
//       #   shift:       $shift
//       #   count:       $count
//       ")

    count.abs.times |c|
    {
      oldCol  := delta > 0 ? oldFirstCol + c         : oldFirstCol + numVisCols - c - 1
      newCol  := delta > 0 ? oldFirstCol + shift + c : oldFirstCol + delta + c
      newColw := "${colwSafe(newCol)}px"

// echo("#  $oldCol => $newCol")

      header := headers.remove(oldCol)
      header.style->width = newColw
      headers[newCol] = header
      refreshHeader(header, newCol)

      numVisRows.times |r|
      {
        row  := r + firstVisRow
        op   := TablePos(oldCol, row)
        cell := cells.remove(op)
        cell.style->width = newColw
        cells[TablePos(newCol, row)] = cell
        refreshCell(cell, newCol, row)
      }
    }

// echo("# >>> firstVisCol: $col")
    firstVisCol = col
  }

  ** Callback to move table to given starting row.
  private Void onMoveY(Int row)
  {
    // short-circuit if nothing todo
    if (firstVisRow == row) return

    oldFirstRow := firstVisRow
    delta := row - oldFirstRow           // delta b/w old and new first row
    shift := delta.abs.max(numVisRows)   // offset to shift rows when delta > 0
    count := delta.abs.min(numVisRows)   // num of rows to move

// echo("# onMoveY
//       #   oldFirstRow: $oldFirstRow
//       #   row:         $row
//       #   delta:       $delta
//       #   shift:       $shift
//       #   count:       $count
//       ")

    count.abs.times |r|
    {
      oldRow := delta > 0 ? oldFirstRow + r         : oldFirstRow + numVisRows - r - 1
      newRow := delta > 0 ? oldFirstRow + shift + r : oldFirstRow + delta + r

// echo("#  $oldRow => $newRow")
      numVisCols.times |c|
      {
        col  := c + firstVisCol
        op   := TablePos(col, oldRow)
        cell := cells.remove(op)
        cells[TablePos(col, newRow)] = cell
        refreshCell(cell, col, newRow)
      }
    }

// echo("# >>> firstVisRow: $row")
    firstVisRow = row
  }

  private Int findMaxVisCols()
  {
    vis := 0
    colw.each |w,i|
    {
      dw := 0
      di := i
      while (dw < tbodyw && di < colw.size) dw += colw[di++]
      vis = vis.max(di-i)
    }
    return vis
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Callback to display header popup.
  private Void openHeaderPopup(Elem button, Popup popup)
  {
    x := button.pagePos.x
    y := button.pagePos.y + button.size.h.toInt
    w := button.size.w.toInt

    // // adjust popup origin if haligned
    // switch (popup.halign)
    // {
    //   case Align.center: x += w / 2
    //   case Align.right:  x += w
    // }

    popup.open(x, y)
  }

  ** Callback to handle scroll event.
  private Void onScroll(Point? delta)
  {
    // short-circuit if no data
    if (delta == null) return

    // find scroll bounds
    scrollBoundx := maxScrollx - tbodyw
    scrollBoundy := maxScrolly - tbodyh
    if (hasScrollx && hasScrolly)
    {
      scrollBoundx += overScroll
      scrollBoundy += overScroll
    }

    // update scroll offset
    scrollx = (scrollx + delta.x.toInt).min(scrollBoundx).max(0)
    scrolly = (scrolly + delta.y.toInt).min(scrollBoundy).max(0)

    // update content
    col := (colx.binarySearch(scrollx).not - 1).max(0).min(numCols - numVisCols).max(0)
    row := (scrolly / rowh).min(numRows - numVisRows).max(0)

    onUpdate(col, row)
  }

  ** Callback to handle mouse events.
  private Void onMouseEvent(Event e)
  {
    if (numCols == 0) return

    p  := this.relPos(e.pagePos)
    mx := p.x.toInt + scrollx
    my := p.y.toInt + scrolly - theadh
    this.style->cursor = null

    if (mx > colx.last + colw.last) return
    col := colx.binarySearch(mx)
    if (col < 0) col = col.not - 1

    cx := mx - colx[col]
    canResize := (col > 0 && cx < 5) || (col < numCols-1 && colw[col]-cx < 5)

    if (p.y.toInt < theadh)
    {
      if (e.type == "mousemove")
      {
        if (canResize) this.style->cursor = "col-resize"
      }
      else if (e.type == "mousedown")
      {
        if (canResize)
        {
          this.resizeCol = cx < 5 ? col-1 : col
          this.style->cursor = "col-resize"
          this.add(resizeElem = Elem { it.style.addClass("domkit-resize-splitter") }
          {
            it.style->left = "${p.x-2}px"
            it.style->width  = "5px"
            it.style->height = "100%"
          })

          doc := Win.cur.doc
          Obj? fmove
          Obj? fup

          fmove = doc.onEvent("mousemove", true) |de| {
            de.stop
            dex := this.relPos(de.pagePos).x.toInt
            resizeElem.style->left = "${dex-2}px"
          }

          fup = doc.onEvent("mouseup", true) |de| {
            // register user colw and cache scroll pos
            demx := this.relPos(de.pagePos).x.toInt + scrollx
            ucolw[resizeCol] = 20.max(demx - colx[resizeCol])
            oldscroll := Point(scrollx, scrolly)

            // remove splitter
            this.remove(resizeElem)
            resizeElem = null

            // rebuild table and restore scrollpos
            doRebuild
            onScroll(oldscroll)

            de.stop
            doc.removeEvent("mousemove", true, fmove)
            doc.removeEvent("mouseup",   true, fup)
          }
        }
        else if (hasHpbut && p.x.toInt > tbodyw-hpbutw)
        {
          // header popup
          Popup hp := cbHeaderPopup.call(this)
          openHeaderPopup(hpbut, hp)
        }
        else
        {
          // sort column
          col = view.colViewToModel(col)
          sort(col, sortCol==col ? (sortDir==Dir.up ? Dir.down : Dir.up) : Dir.up)
        }
      }
    }
    else
    {
      // short-circuit if out of bounds
      row := my / rowh
      if (row >= numRows)
      {
        // click in backbground clears selection
        if (e.type == "mousedown") updateSel(Int[,])
        return
      }

      // find pos relative to cell (cx calc above)
      cy := my - (row * rowh)

      // map to model rows
      vcol := col
      vrow := row
      col = view.colViewToModel(col)
      row = view.rowViewToModel(row)

      // check selection
      if (e.type == "mousedown") onMouseEventSelect(e, row, vrow)

      // check action
      if (e.type == "dblclick") cbAction?.call(this)

      // delegate to cell handlers
      cb := cbTableEvent[e.type]
      if (cb != null)
      {
        cb.call(TableEvent(this) {
          it.type    = e.type
          it.col     = col
          it.row     = row
          it.pagePos = e.pagePos
          it.cellPos = Point(cx, cy)
          it.size    = Size(colw[vcol], rowh)
          it._event  = e
        })
      }
    }
  }

  ** Callback to handle selection changes from a mouse event.
  private Void onMouseEventSelect(Event e, Int row, Int vrow)
  {
    // always force focus for mousedown
    manFocus = true

    // short-circuit if we initiated a hyperlink so that
    // the event can bubble properly down to the <a> tag
    if (e.target.tagName == "a")
    {
      // Chrome seems to be doing some weird stuff here; forcing
      // an onblur call on the Table <div> inbetween firing the
      // hyperlink. Technically that might be correct but complicates
      // how we manage focus.  So if we detect this manually invoke
      // the click to skip over that behavoir
      e.target->click
      e.stop
      return
    }

    cur := sel.indexes
    newsel := cur.dup

    // check multi-selection
    if (e.shift && pivot != null)
    {
      if (vrow < pivot)
      {
        (vrow..pivot).each |i| { newsel.add(view.rowViewToModel(i)) }
        newsel = newsel.unique.sort
      }
      else if (vrow > pivot)
      {
        (pivot..vrow).each |i| { newsel.add(view.rowViewToModel(i)) }
        newsel = newsel.unique.sort
      }
    }
    else if (e.meta || e.ctrl)
    {
      if (cur.contains(row)) newsel.remove(row)
      else newsel.add(row).sort
      pivot = view.rowModelToView(row)
    }
    else
    {
      newsel = [row]
      pivot = view.rowModelToView(row)
    }

    updateSel(newsel)
  }

  ** Callback to handle key events.
  private Void onKeyEvent(Event e)
  {
    // just handle keydown for now
    if (e.type != "keydown") return

    // short-circuit if no cells
    if (numCols==0 || numRows==0) return

    // updateSel takes model rows; but scrollTo takes view rows, so
    // pre-map some of the selection indexs here to simplify things
    selTop      := view.rowViewToModel(0)
    selBottom   := view.rowViewToModel(numRows-1)
    selFirstVis := view.rowViewToModel(firstVisRow)
    pivot       := view.rowModelToView(sel.indexes.first ?: selTop)

    // page commands
    if (e.meta)
    {
      if (e.key == Key.up)    { e.stop; updateSel([selTop]);    scrollTo(null, 0); return }
      if (e.key == Key.down)  { e.stop; updateSel([selBottom]); scrollTo(null, numRows-1); return }
      if (e.key == Key.left)  { e.stop; scrollTo(0,         null); return }
      if (e.key == Key.right) { e.stop; scrollTo(numCols-1, null); return }
    }

    // page up/down
    if (e.key == Key.pageUp)
    {
      e.stop
      prev := (pivot - (numVisRows-3)).max(0)
      updateSel([view.rowViewToModel(prev)])
      scrollTo(null, prev)
      return
    }
    if (e.key == Key.pageDown)
    {
      e.stop
      next := (pivot + (numVisRows-3)).max(0).min(numRows-1)
      updateSel([view.rowViewToModel(next)])
      scrollTo(null, next)
      return
    }

    // selection commands
    switch (e.key)
    {
      case Key.left:
        cur := colx.binarySearch(scrollx)
        if (cur < 0) cur = cur.not - 1
        pre := colx[cur] == scrollx ? cur-1 : cur
        scrollTo(0.max(pre), null)
        return

      case Key.right:
        cur := colx.binarySearch(scrollx)
        if (cur < 0) cur = cur.not - 1
        scrollTo((numCols-1).min(cur+1), null)
        return

      case Key.up:
        if (sel.indexes.isEmpty)
        {
          updateSel([selFirstVis])
          scrollTo(null, firstVisRow)
          return
        }
        else
        {
          if (pivot == 0) return scrollTo(null, 0)
          prev := pivot - 1
          updateSel([view.rowViewToModel(prev)])
          scrollTo(null, prev)
          return
        }

      case Key.down:
        if (sel.indexes.isEmpty)
        {
          updateSel([selFirstVis])
          scrollTo(null, firstVisRow)
          return
        }
        else
        {
          if (pivot == numRows-1) return scrollTo(null, numRows-1)
          next := pivot + 1
          updateSel([view.rowViewToModel(next)])
          scrollTo(null, next)
          return
        }
    }

    // onAction
    if (e.key == Key.space || e.key == Key.enter)
    {
      cbAction?.call(this)
      return
    }

    // else bubble up to callback
    if (e.type == "keydown") return cbKeyDown?.call(e)
  }

  @NoDoc Void updateSel(Int[] newsel)
  {
    if (!sel.enabled) return
    if (sel.indexes == newsel) return
    if (cbBeforeSelect?.call(newsel) == false) return
    sel.indexes = newsel
    cbSelect?.call(this)
  }

  private Int colxSafe(Int c) { colx.getSafe(c) ?: colx.last + colw.last + ((c-colx.size+1) * 100)}
  private Int colwSafe(Int c) { colw.getSafe(c) ?: 100 }

  private Str ts() { "${(Duration.now - Duration.boot).toMillis}ms" }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const Str[] cellEvents := [
    "mousedown",
    "mouseup",
    "click",
    "dblclick",

    // TODO: opt into these events?
    // "mousemove",
    // "mouseover",
    // "mouseout",
  ]

  private Func? cbBeforeSelect
  private Func? cbSelect
  private Func? cbAction
  private Func? cbSort
  private Func? cbKeyDown
  private Str:Func cbTableEvent := [:]
  private Func? cbHeaderPopup

  // scrollbars
  private const Int sbarsz := 15
  private const Int thumbMargin := 2
  private const Int overScroll := sbarsz + 2
  private const Duration scrollPageFreq := 100ms
  private const Duration scrollPulseDir := 300ms

  // refresh
  private Elem? thead
  private Elem? tbody
  private Elem? hbar
  private Elem? vbar
  private Int:Elem headers := [:]
  private TablePos:Elem cells := [:]
  private Int theadh            // thead height
  private Int tbodyw            // tbody width
  private Int tbodyh            // tbody height
  private Int numCols           // num cols in model
  private Int numRows           // num rows in model
  private Int[] colx := [,]     // col x offsets
  private Int[] colw := [,]     // col widths
  private Int:Int ucolw := [:]  // user defined col width (via resize)
  private Int rowh              // row height
  private Int numVisCols        // num of visible cols
  private Int numVisRows        // num of visible rows
  private Int maxScrollx        // max scroll x value
  private Int maxScrolly        // max scroll y value
  private Bool hasScrollx       // is horiz scolling
  private Bool hasScrolly       // is vert scolling
  private Int htrackw           // hbar track width
  private Int hthumbw           // hbar thumb width
  private Int vtrackh           // vbar track height
  private Int vthumbh           // vbar thumb height

  // resize
  private Int? resizeCol        // column being resized
  private Elem? resizeElem      // visual indication of resize col size

  // headerPopup
  private Elem? hpbut             // header popup button
  private Bool hasHpbut           // hpbut != null
  private const Int hpbutw := 22  // width of header popup button

  // scroll
  private Int scrollx           // current x scroll pos
  private Int scrolly           // current y scroll pos
  private Int? hbarPulseId      // hbar pulse timeout func id
  private Int? vbarPulseId      // vbar pulse timeout func id
  private Int? hbarPageId       // hbar page interval func id
  private Int? vbarPageId       // vbar page interval func id
  private Int? hthumbDragOff    // offset of hthumb drag pos
  private Int? vthumbDragOff    // offset of vthumb drag pos

  // update
  private Int firstVisCol    // first visible col
  private Int firstVisRow    // first visible row

  // onSelect (always in view refrence; not model)
  private Int? pivot

  // focus/blur
  private Bool manFocus := false
}

**************************************************************************
** TablePos
**************************************************************************

**
** TablePos provides an JS optimized hash key for col,row cell position
**
@Js
internal const class TablePos
{
  new make(Int c, Int r) { col = c; row = r; toStr = "$c,$r"; hash = toStr.hash }
  const Int col
  const Int row
  const override Int hash
  const override Str toStr
  override Bool equals(Obj? that) { toStr == that.toStr }
}

**************************************************************************
** TableModel
**************************************************************************

**
** TableModel backs the data model for a `Table`
**
@Js class TableModel
{
  ** Number of columns in table.
  virtual Int numCols() { 0 }

  ** Number of rows in table.
  virtual Int numRows() { 0 }

  ** Return height of header.
  virtual Int headerHeight() { 20 }

  ** Return width of given column.
  virtual Int colWidth(Int col) { 100 }

  ** Return height of rows.
  virtual Int rowHeight() { 20 }

  ** Return item for the given row to be used with selection.
  virtual Obj item(Int row) { row }

  ** Callback to update content for column header at given index.
  virtual Void onHeader(Elem header, Int col)
  {
    header.text = "Col $col"
  }

  ** Return default visible/hidden state for column
  virtual Bool isVisibleDef(Int col) { true }

  ** Callback to update the cell content at given location.
  virtual Void onCell(Elem cell, Int col, Int row, TableFlags flags)
  {
    cell.text = "C$col:R$row"
  }

  ** Compare two cells when sorting the given col.  Return -1,
  ** 0, or 1 according to the same semanatics as `sys::Obj.compare`.
  ** See `domkit::Table.sort`.
  virtual Int sortCompare(Int col, Int row1, Int row2) { 0 }

  ** Callback when table is resorted
  @NoDoc virtual Void onSort(Int? col, Dir dir) {}
}

**************************************************************************
** TableFlags
**************************************************************************

** Table specific flags for eventing
@Js const class TableFlags
{
  ** Default value with all flags cleared
  static const TableFlags defVal := make {}

  new make(|This| f) { f(this) }

  ** Table has focus.
  const Bool focused

  ** Row is selected.
  const Bool selected

  override Str toStr()
  {
    "TableFlags { focused=$focused; selected=$selected }"
  }
}

**************************************************************************
** TableEvent
**************************************************************************

**
** TableEvents are generated by `Table` cells.
**
@Js class TableEvent
{
  internal new make(Table t, |This| f)
  {
    this.table = t
    f(this)
  }

  Table table { private set }

  ** Event type.
  const Str type

  ** Column index for this event.
  const Int col

  ** Row index for this event.
  const Int row

  ** Mouse position relative to page.
  const Point pagePos

  ** Mouse position relative to cell.
  const Point cellPos

  ** Size of cell for this event.
  const Size size

  // TODO: not sure how this works yet
  @NoDoc Event? _event

  override Str toStr()
  {
    "TableEvent { type=$type row=$row col=$col pagePos=$pagePos cellPos=$cellPos size=$size }"
  }
}

**************************************************************************
** TableSelection
**************************************************************************

@Js internal class TableSelection : IndexSelection
{
  new make(TableView view) { this.view = view }
  override Int max() { view.numRows }
// TODO FIXIT: selection is always kept in original order
  override Obj toItem(Int index) { view.table.model.item(index) }
  override Int? toIndex(Obj item)
  {
    numRows := view.numRows
    for (row := 0; row < numRows; ++row)
      if (view.table.model.item(row) == item) return row
    return null
  }
  // override Obj toItem(Int index) { view.item(index) }
  // override Int? toIndex(Obj item)
  // {
  //   numRows := view.numRows
  //   for (row := 0; row < numRows; ++row)
  //     if (view.item(row) == item) return row
  //   return null
  // }
  override Void onUpdate(Int[] oldIndexes, Int[] newIndexes)
  {
    oldIndexes.each |i| { if (i < max) view.table.refreshRow(view.rowModelToView(i)) }
    newIndexes.each |i| { if (i < max) view.table.refreshRow(view.rowModelToView(i)) }
  }
  private TableView view
}

**************************************************************************
** TableView
**************************************************************************

**
** TableView wraps the table model to implement the row/col mapping
** from the view coordinate space to the model coordinate space based
** on column visibility and row sort order.
**
@NoDoc @Js class TableView : TableModel
{
  new make(Table table) { this.table = table }

//////////////////////////////////////////////////////////////////////////
// TableModel overrides
//////////////////////////////////////////////////////////////////////////

  override Int numCols() { cols.size }
  override Int numRows() { rows.size }
  override Int headerHeight() { table.model.headerHeight }
  override Int colWidth(Int c) { table.model.colWidth(cols[c]) }
  override Int rowHeight() { table.model.rowHeight }
  override Obj item(Int r) { table.model.item(rows[r]) }
  override Void onHeader(Elem e, Int c) { table.model.onHeader(e, cols[c]) }
  override Void onCell(Elem e, Int c, Int r, TableFlags f) { table.model.onCell(e, cols[c], rows[r], f) }

//////////////////////////////////////////////////////////////////////////
// View Methods
//////////////////////////////////////////////////////////////////////////

  Bool isColVisible(Int col) { vis[col] }

  This setColVisible(Int col, Bool visible)
  {
    // if not changing anything then short circuit
    if (vis[col] == visible) return this

    // update column mappings
    vis[col] = visible
    cols.clear
    vis.each |v, i| { if (v) cols.add(i) }
    return this
  }

  Void sort(Int? col, Dir dir := Dir.up)
  {
    model := table.model
    sortCol = col
    sortDir = dir
    if (col == null)
    {
      rows.each |val, i| { rows[i] = i }
    }
    else
    {
      if (dir === Dir.up)
        rows.sort |a, b| { model.sortCompare(col, a, b) }
      else
        rows.sortr |a, b| { model.sortCompare(col, a, b) }
    }
  }

  Void refresh()
  {
    model := table.model
    if (rows.size != model.numRows) refreshRows
    if (vis.size  != model.numCols) refreshCols
  }

  private Void refreshRows()
  {
    // rebuild from scratch using base model order
    model := table.model
    rows.clear
    rows.capacity = model.numRows
    model.numRows.times |i| { rows.add(i) }

    // if sort was in-place, then resort
    if (sortCol != null && sortCol < model.numCols) sort(sortCol, sortDir)
  }

  private Void refreshCols()
  {
    // rebuild from scratch
    model := table.model
    cols.clear; cols.capacity = model.numCols
    vis.clear; vis.capacity = model.numCols
    model.numCols.times |i|
    {
      visDef := model.isVisibleDef(i)
      vis.add(visDef)
      if (visDef) cols.add(i)
    }
  }

  // View -> Model
  Int rowViewToModel(Int i) { rows[i] }
  Int colViewToModel(Int i) { cols[i] }
  Int[] rowsViewToModel(Int[] i) { i.map |x->Int| { rows[x] } }
  Int[] colsViewToModel(Int[] i) { i.map |x->Int| { cols[x] } }

  // Model -> View (need to optimize linear scan)
  Int rowModelToView(Int i) { rows.findIndex |x| { x == i } }
  Int colModelToView(Int i) { cols.findIndex |x| { x == i } }
  Int[] rowsModelToView(Int[] i)  { i.map |x->Int| { rowModelToView(x) } }
  Int[] colsModelToView(Int[] i)  { i.map |x->Int| { colModelToView(x) } }

  internal Table table
  private Int[] rows := [,]   // view to model row index mapping
  private Int[] cols := [,]   // view to model col index mapping
  private Bool[] vis := [,]   // visible
  internal Int? sortCol { private set }  // model based index
  internal Dir sortDir := Dir.up { private set }
}