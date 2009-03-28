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
  ** Load an image from uri to file.  If checked is true then throw
  ** UnresolvedErr if uri cannot be resolved.  If checked is false
  ** then return null on error - although since the image is loaded
  ** asynchronously upon demand we don't know the image can actually
  ** be loaded upon return.
  **
  static Image? make(Uri uri, Bool checked := true)
  {
    try
    {
      FileImage? img := makeFile(uri.get, checked)
      if (img != null) img.uri = uri
      return img
    }
    catch (Err e)
    {
      if (checked) throw e
      return null
    }
  }

  **
  ** Load an image from file.  If checked is true and the file
  ** doesn't exist then throw an exception.  If checked is false
  ** then return null - although since the image is loaded
  ** asynchronously upon demand we don't know the image can actually
  ** be loaded upon return.
  **
  static Image? makeFile(File f, Bool checked := true)
  {
    try
    {
      if (!f.exists) throw ArgErr("file does not exist: $f")
      return FileImage.internalMake(f)
    }
    catch (Err e)
    {
      if (checked) throw e
      return null
    }
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

  **
  ** Resize this image into a new image.
  **
  native Image resize(Size size)

  **
  ** Return the uri used to load this file, or null if this
  ** image wasn't created from a uri.
  **
  virtual Uri? uri() { return null }

}

**************************************************************************
** MemImage
**************************************************************************

internal class MemImage : Image
{
  internal new internalMake() {}

  override Uri? uri() { null }

  override Str toStr() { "MemImage" }
}

**************************************************************************
** FileImage
**************************************************************************

internal class FileImage : Image
{
  internal new internalMake(File f)
  {
    file = f
    uri  = f.uri
  }

  const File file

  override Uri? uri { internal set }

  override Str toStr() { return file.toStr }
}