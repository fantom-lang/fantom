//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

**
** Image represents a graphical image.
**
abstract class Image
{

  **
  ** Load an image from file.
  **
  static Image make(File f)
  {
    if (f == null) throw NullErr("file is null")
    if (!f.exists) throw ArgErr("file does not exist: $f")
    return FileImage.internalMake(f)
  }

  **
  ** Internal make.
  **
  internal new internalMake() {}

  **
  ** Get the size of the image or 0,0 if not loaded yet.
  **
  native Size size()

  **
  ** Free any operating system resources used by this instance.
  **
  native Void dispose()

}


**************************************************************************
** FileImage
**************************************************************************

internal class FileImage : Image
{
  internal new internalMake(File f) { file = f }

  const File file

  override Str toStr() { return file.toStr }
}
