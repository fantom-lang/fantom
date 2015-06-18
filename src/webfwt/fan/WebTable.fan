//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 2012  Andy Frank  Creation
//

using fwt
using gfx

**
** WebTable extends Table with additional functionality.
**
@NoDoc
@Js
class WebTable : Table
{
  ** Constructor.
  new make(|This|? f := null) : super(f) {}

  ** Pos relative to table for given cell.
  native Point cellPos(Int col, Int row)

  **
  ** Callback when mouse pressed inside a table cell.
  ** Event.data is Str:Str map:
  **  - posOnDisplay: mouse pos relative to display
  **  - cellSize: cell size in pixels
  **  - col: table column of cell
  **  - row: table row of cell
  **
  once EventListeners onCellMouseDown() { EventListeners() }

  ** Scroll to bottom of table content.
  native This scrollToBottom()

  ** The number of pixels that the content of the table is scrolled upward.
  @NoDoc native Int scrollTop
}
