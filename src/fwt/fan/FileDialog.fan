//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Nov 08  Brian Frank  Creation
//

**
** FileDialog is used to prompt for file and directory selections.
** This class isn't actually a dialog, it merely defines the various
** options used to open the operating system's native file dialog.
**
class FileDialog
{

  **
  ** Default constructor.
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
  }

  **
  ** Mode is used to define whether we are opening or saving
  ** a single file, multiple files, or a directory.
  **
  const FileDialogMode mode := FileDialogMode.openFile

  **
  ** The initial directory to display
  **
  const File? dir

  **
  ** The initial filename to display
  **
  const Str? name

  **
  ** File extensions to display, for example:
  **   filterExts = ["*.gif", "*.png", "*.jpg"]
  **
  const Str[]? filterExts := null

  **
  ** Return the user selection or null if canceled.  Result is
  ** based on mode:
  **  - openFile: File
  **  - openFiles: File[]
  **  - saveFile: File
  **  - openDir: File
  **
  native Obj? open(Window? parent)

}