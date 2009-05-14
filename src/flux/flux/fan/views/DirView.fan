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
@fluxViewMimeType="x-directory"
internal class DirView : View
{
  override Void onLoad()
  {
    model = DirViewModel { files=((FileResource)resource).children }
    content = Table
    {
      it.multi = true
      it.onAction.add(&this.onAction)
      it.onPopup.add(&this.onPopup)
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

  override Image? image(Int col, Int row)
  {
    return (col == 0) ? files[row].icon : null
  }
}