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
  ** Draw a border around the widget.  Default is true.  This
  ** field cannot be changed once the widget is constructed.
  **
  const Bool border := true

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
  native Void updateAll()
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
  ** Get the text to display for specified cell.
  **
  abstract Str text(Int col, Int row)

  **
  ** Get the image to display for specified cell or null.
  **
  virtual Image image(Int col, Int row) { return null }
}