//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Apr 10  Andy Frank  Creation
//

using fwt
using gfx

**
** WebTableModel extends TableModel with additional functionality.
**
@NoDoc
@Js
abstract class WebTableModel : TableModel
{
  ** Image alignment relative to text.
  virtual Halign halignImage(Int c) { Halign.left }

  ** Optional image to display when row is selected.
  virtual Image? imageSel(Int col, Int row) { null }

  ** Get the Uri used for this cell. Returning a Uri converts
  ** cell content to a hyperlink.
  virtual Uri? uri(Int col, Int row) { null }

  ** Get the <a target> for the Uri used for this cell, or 'null'
  ** for the default behavoir.
  virtual Str? uriTarget(Int col, Int row) { null }

  ** Callback when mouse is pressed down on a cell.
  @Deprecated { msg="Use WebTableModel.onCellMouseDown" }
  virtual Void onMouseDown(Event event, Int col, Int row) {}
}


