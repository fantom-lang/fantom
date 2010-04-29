//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** DirView displays a directory as a details table.
**
internal class DirView : View
{
  override Void onLoad()
  {
    model = DirViewModel { files=((FileResource)resource).children }
    content = Table
    {
      it.multi = true
      it.onAction.add |e| { this.onAction(e) }
      it.onPopup.add  |e| { this.onPopup(e) }
      it.border = false
      it.model = this.model
    }
  }

  internal Void onAction(Event event)
  {
    file := model.file(event.index)
    if (file != null)
      frame.load(file.uri, LoadMode(event))
  }

  internal Void onPopup(Event event)
  {
    r := model.file(event.index) ?: resource
    event.popup = r.popup(frame, event)
  }

  DirViewModel? model
}

internal class DirViewModel : TableModel
{
  FileResource[]? files
  Str[] headers := ["Name", "Size", "Modified"]

  FileResource? file(Int? i) { return i == null ? null : files[i] }

  override Int numCols() { return 3 }
  override Int numRows() { return files.size }
  override Str header(Int col) { return headers[col] }
  override Halign halign(Int col) { return col == 1 ? Halign.right : Halign.left }

  override Int? prefWidth(Int col)
  {
    switch (col)
    {
      case 0:  return 175
      case 1:  return 75
      case 2:  return 175
      default: return null
    }
  }

  override Str text(Int col, Int row)
  {
    f := files[row]
    switch (col)
    {
      case 0:  return f.name
      case 1:  return FileResource.sizeToStr(f.file.size)
      case 2:  return f.file.modified?.toLocale ?: ""
      default: return "?"
    }
  }

  override Int sortCompare(Int col, Int row1, Int row2)
  {
    a := files[row1]
    b := files[row2]
    switch (col)
    {
      case 1:  return a.file.size <=> b.file.size
      case 2:  return a.file.modified <=> b.file.modified
      default: return super.sortCompare(col, row1, row2)
    }
  }

  override Image? image(Int col, Int row)
  {
    return (col == 0) ? files[row].icon : null
  }
}