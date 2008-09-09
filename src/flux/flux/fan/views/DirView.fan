//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

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
      onAction.add(&onAction)
      model = this.model
    }
  }

  internal Void onAction(Event event)
  {
    frame.load(model.files[event.index])
  }

  DirViewModel model
}

internal class DirViewModel : TableModel
{
  FileResource[] files
  Str[] headers := ["Name", "Size", "Modified"]

  override Int numCols() { return 3 }
  override Int numRows() { return files.size }
  override Str header(Int col) { return headers[col] }
  override Halign halign(Int col) { return col == 1 ? Halign.right : Halign.left }

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

  override Image image(Int col, Int row)
  {
    return (col == 0) ? files[row].icon : null
  }
}