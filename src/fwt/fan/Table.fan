//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jun 08  Brian Frank  Creation
//

**
** Table displays grid of rows and columns.
**
class Table : Widget
{

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
  @transient readonly EventListeners onAction := EventListeners()

  **
  ** Callback when selected rows change.
  **
  ** Event id fired:
  **   - `EventId.select`
  **
  ** Event fields:
  **   - `Event.index`: the primary selection row index.
  **
  @transient readonly EventListeners onSelect := EventListeners()

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
  **
  @transient readonly EventListeners onPopup := EventListeners()

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
  TableModel model

  **
  ** Is the header visible.. Defaults to true.
  **
  native Bool headerVisible

  **
  ** Update the entire table's contents from the model.
  **
  native Void refreshAll()

  **
  ** Get and set the selected row indices.
  **
  native Int[] selected
}

**************************************************************************
** TableModel
**************************************************************************

**
** TableModel models the data of a table widget.
**
mixin TableModel
{

  **
  ** Get number of rows in table.
  **
  abstract Int numRows()

  **
  ** Get number of columns in table.  Default returns 1.
  **
  virtual Int numCols() { return 1 }

  **
  ** Get the header text for specified column.
  **
  virtual Str header(Int col) { return "Header $col" }

  **
  ** Get the horizontal alignment for specified column.
  ** Default is left.
  **
  virtual Halign halign(Int col) { return Halign.left }

  **
  ** Return the preferred width in pixels for this column.
  ** Return null (the default) to use the Tables default
  ** width.
  **
  virtual Int prefWidth(Int col) { return null }

  **
  ** Get the text to display for specified cell.
  **
  abstract Str text(Int col, Int row)

  **
  ** Get the image to display for specified cell or null.
  **
  virtual Image? image(Int col, Int row) { return null }

  **
  ** Get the font used to render the text for this cell.
  ** If null, use the default system font.
  **
  virtual Font? font(Int col, Int row) { return null }

  **
  ** Get the foreground color for this cell. If null, use
  ** the default foreground color.
  **
  virtual Color? fg(Int col, Int row) { return null }

  **
  ** Get the background color for this cell. If null, use
  ** the default background color.
  **
  virtual Color? bg(Int col, Int row) { return null }

}