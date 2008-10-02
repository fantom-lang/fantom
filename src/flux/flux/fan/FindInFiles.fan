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
internal class FindInFiles
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

    dlg := Dialog(parent)
    {
      title = FindInFiles#.loc("findInFiles.name")
      body=content
      commands=[Dialog.ok, Dialog.cancel]
    }

    if (Dialog.ok != dlg.open) return

    content2 := GridPane
    {
      Label { text = "Doesn't actually do anything yet..." }
      ProgressBar { indeterminate = true }
    }

    dlg = Dialog(parent)
    {
      title = FindInFiles#.loc("findInFiles.name")
      body = content2
      commands=[Dialog.cancel]
    }

    dlg.open
  }

}