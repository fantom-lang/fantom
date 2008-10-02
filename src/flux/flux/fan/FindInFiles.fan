//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 08  Andy Frank  Creation
//

using fwt

**
** FindInFiles searches a set of files for a query string.
**
class FindInFiles
{
  **
  ** Open the dialog.
  **
  static Void open(Frame parent)
  {
    content := GridPane
    {
      numCols = 2
      Label { text="Find" }
      Text  { prefCols=30 }
      Label { text="In Files" }
      Text  { text="*.fan"; prefCols=30 }
      Label { text="In Folder" }
      Text  { text="file:/C:/dev/fan/src/flux/flux/fan/"; prefCols=30 }
    }
    dlg := Dialog(parent, content, [Dialog.ok, Dialog.cancel])
      { title = FindInFiles#.loc("findInFiles.name") }
    if (Dialog.ok != dlg.open) return

    content2 := GridPane
    {
      Label { text = "Doesn't actually do anything yet..." }
      ProgressBar { indeterminate = true }
    }
    dlg = Dialog(parent, content2, [Dialog.cancel])
      { title = FindInFiles#.loc("findInFiles.name") }
    dlg.open
  }

}