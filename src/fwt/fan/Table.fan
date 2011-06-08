//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

using gfx

**
** Table displays grid of rows and columns.
**
@Js
@Serializable
class Table : Widget
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Callback when row is double clicked or Return/Enter
  ** key is pressed.
  **
  ** Event id fired:
  **   - `EventId.action`
  **
  ** Event fields:
  **   - `Event.index`: the row index.
  **
  once EventListeners onAction() { EventListeners() }

  **
  ** Callback when selected rows change.
  **
  ** Event id fired:
  **   - `EventId.select`
  **
  ** Event fields:
  **   - `Event.index`: the primary selection row index.
  **
  once EventListeners onSelect() { EventListeners() }

  **
  ** Callback when user invokes a right click popup action.
  ** If the callback wishes to display a popup, then set
  ** the `Event.popup` field with menu to open.  If multiple
  ** callbacks are installed, the first one to return a nonnull
  ** popup consumes the event.
  **
  ** Event id fired:
  **   - `EventId.popup`
  **
  ** Event fields:
  **   - `Event.index`: the row index, or 'null' if this is a
  **     background popup.
  **   - `Event.pos`: the mouse position of the popup.
  **
  once EventListeners onPopup() { EventListeners() }

  **
  ** Horizontal scroll bar.
  **
  @Transient ScrollBar hbar := ScrollBar.makeNative(Orientation.horizontal) { private set }

  **
  ** Vertical scroll bar.
  **
  @Transient ScrollBar vbar := ScrollBar.makeNative(Orientation.vertical) { private set }

  **
  ** Draw a border around the widget.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

  **
  ** True to enable multi-row selection, false for single
  ** row selection.  Default is false.  This field cannot
  ** be changed once the widget is constructed.
  **
  const Bool multi := false

  **
  ** Backing data model of table.
  **
  TableModel model := TableModel()

  **
  ** Is the header visible. Defaults to true.
  **
  native Bool headerVisible

  **
  ** Update the rows at the selected indices
  **
  native Void refreshRows(Int[] indices)

  **
  ** Update the entire table's contents from the model.
  **
  native Void refreshAll()

  **
  ** Get and set the selected row indices.
  **
  native Int[] selected

  **
  ** Get the zero based row index at the specified coordinate
  ** relative to this widget or null if not over a valid cell.
  **
  native Int? rowAt(Point pos)

  **
  ** Get the zero based column index at the specified coordinate
  ** relative to this widget or null if not over a valid cell.
  **
  native Int? colAt(Point pos)

  **
  ** Return if the given column is visible.  All columns are
  ** visible by default and can be toggled via `setColVisible`.
  **
  Bool isColVisible(Int col) { view.isColVisible(col) }

  **
  ** Show or hide the given column.  Changing visibility of columns
  ** does not modify the indexing of TableModel, it only changes how
  ** the model is viewed.  See `isColVisible`.  This method does not
  ** automatically refresh table, call `refreshAll` when complete.
  **
  Void setColVisible(Int col, Bool visible) { view.setColVisible(col, visible) }

  **
  ** The column index by which the table is currently sorted, or null
  ** if the table is not currently sorted by a column.  See `sort`.
  **
  Int? sortCol() { view.sortCol }

  **
  ** Return if the table is currently sorting up or down.  See `sort`.
  **
  SortMode sortMode() { view.sortMode }

  **
  ** Sort a table by the given column index. If col is null, then
  ** the table is ordered by its natural order of the table model.
  ** Sort order is determined by `TableModel.sortCompare`.  Sorting
  ** does not modify the indexing of TableModel, it only changes how
  ** the model is viewed.  Also see `sortCol` and `sortMode`.  This
  ** method automatically refreshes the table.
  **
  native Void sort(Int? col, SortMode mode := SortMode.up)

  **
  ** The view wraps the table model to implement the row/col mapping
  ** from the view coordinate space to the model coordinate space based
  ** on column visibility and row sort order.
  **
  internal TableView view := TableView(this) { get { &view.sync } }
}

**************************************************************************
** TableModel
**************************************************************************

**
** TableModel models the data of a table widget.
**
@Js
class TableModel
{

  **
  ** Get number of rows in table.
  **
  virtual Int numRows() { 0 }

  **
  ** Get number of columns in table.  Default returns 1.
  **
  virtual Int numCols() { 1 }

  **
  ** Get the header text for specified column.
  **
  virtual Str header(Int col) { "Header $col" }

  **
  ** Get the horizontal alignment for specified column.
  ** Default is left.
  **
  virtual Halign halign(Int col) { Halign.left }

  **
  ** Return the preferred width in pixels for this column.
  ** Return null (the default) to use the Tables default
  ** width.
  **
  virtual Int? prefWidth(Int col) { null }

  **
  ** Get the text to display for specified cell.
  **
  virtual Str text(Int col, Int row) { "$col:$row" }

  **
  ** Get the image to display for specified cell or null.
  **
  virtual Image? image(Int col, Int row) { null }

  **
  ** Get the font used to render the text for this cell.
  ** If null, use the default system font.
  **
  virtual Font? font(Int col, Int row) { null }

  **
  ** Get the foreground color for this cell. If null, use
  ** the default foreground color.
  **
  virtual Color? fg(Int col, Int row) { null }

  **
  ** Get the background color for this cell. If null, use
  ** the default background color.
  **
  virtual Color? bg(Int col, Int row) { null }

  **
  ** Compare two cells when sorting the given col.  Return -1,
  ** 0, or 1 according to the same semanatics as `sys::Obj.compare`.
  ** Default behavior sorts `text` using `sys::Str.localeCompare`.
  ** See `fwt::Table.sort`.
  **
  virtual Int sortCompare(Int col, Int row1, Int row2)
  {
    text(col, row1).localeCompare(text(col, row2))
  }
}

**************************************************************************
** TableView
**************************************************************************

**
** TableView wraps the table model to implement the row/col mapping
** from the view coordinate space to the model coordinate space based
** on column visibility and row sort order.
**
@Js
internal class TableView : TableModel
{
  new make(Table table) { this.table = table }

//////////////////////////////////////////////////////////////////////////
// TableModel overrides
//////////////////////////////////////////////////////////////////////////

  override Int numRows() { rows.size }

  override Int numCols() { cols.size }

  override Str header(Int col) { table.model.header(cols[col]) }

  override Halign halign(Int col) { table.model.halign(cols[col]) }

  override Int? prefWidth(Int col) { table.model.prefWidth(cols[col]) }

  override Str text(Int col, Int row) { table.model.text(cols[col], rows[row]) }

  override Image? image(Int col, Int row) { table.model.image(cols[col], rows[row]) }

  override Font? font(Int col, Int row) { table.model.font(cols[col], rows[row]) }

  override Color? fg(Int col, Int row) { table.model.fg(cols[col], rows[row]) }

  override Color? bg(Int col, Int row) { table.model.bg(cols[col], rows[row]) }

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

  Void sort(Int? col, SortMode mode := SortMode.up)
  {
    model := table.model
    sortCol = col
    sortMode = mode
    if (col == null)
    {
      rows.each |val, i| { rows[i] = i }
    }
    else
    {
      if (mode === SortMode.up)
        rows.sort |a, b| { model.sortCompare(col, a, b) }
      else
        rows.sortr |a, b| { model.sortCompare(col, a, b) }
    }
  }

  This sync()
  {
    model := table.model
    if (rows.size != model.numRows) syncRows
    if (vis.size  != model.numCols) syncCols
    return this
  }

  private Void syncRows()
  {
    // rebuild from scratch using base model order
    model := table.model
    rows.clear
    rows.capacity = model.numRows
    model.numRows.times |i| { rows.add(i) }

    // if sort was in-place, then resort
    if (sortCol != null) sort(sortCol, sortMode)
  }

  private Void syncCols()
  {
    // rebuild from scratch
    model := table.model
    cols.clear; cols.capacity = model.numCols
    vis.clear; vis.capacity = model.numCols
    model.numCols.times |i| { cols.add(i); vis.add(true) }
  }

  private Table table
  private Int[] rows := [,]   // view to base row index mapping
  private Int[] cols := [,]   // view to base col index mapping
  private Bool[] vis := [,]   // visible
  internal Int? sortCol { private set }
  internal SortMode sortMode := SortMode.up { private set }
}

