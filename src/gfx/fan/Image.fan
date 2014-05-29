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
@Js
@Serializable { simple = true }
const class Image
{

  **
  ** Convenience for `makeFile` to create an image which
  ** is loaded from the file referenced by `sys::Uri.get`.
  **
  static new make(Uri uri, Bool checked := true)
  {
    try
    {
      f := (File)uri.get
      if (!f.exists) throw UnresolvedErr("file does not exist: $f")
      return makeFields(uri, f)
    }
    catch (Err e)
    {
      if (checked) throw e
      return null
    }
  }

  **
  ** Create a new image which is painted by the given function.
  **
  ** Example:
  **   Image.makePainted(Size(100, 100)) |g|
  **   {
  **     g.brush = Color.green
  **     g.fillRect(0, 0, 100, 100)
  **   }
  **
  static new makePainted(Size size, |Graphics| f)
  {
    GfxEnv.cur.imagePaint(size, f)
  }

  **
  ** Create an image to load from file.  If checked is true and the
  ** file doesn't exist then throw an exception.  If checked is false
  ** then return null.  The supported file formats are based on
  ** the target graphics environment, but typically include PNG, GIF,
  ** and JPEG.
  **
  ** Note: since the image is loaded asynchronously upon demand,
  ** there is no guarantee that the file actually stores a valid
  ** image once this method completes successfully.  Completion of
  ** this method is based only on file existence.
  **
  static new makeFile(File f, Bool checked := true)
  {
    try
    {
      if (!f.exists) throw UnresolvedErr("file does not exist: $f")
      return makeFields(f.uri, f)
    }
    catch (Err e)
    {
      if (checked) throw e
      return null
    }
  }

  **
  ** Convenience for 'make(uri.toUri, checked)'.
  **
  static new fromStr(Str uri, Bool checked := true)
  {
    make(uri.toUri, checked)
  }

  **
  ** Construct with field values.  This constructor is used
  ** for subclasses and graphics toolkits.  Developers
  ** should use `make` or `makeFile`.
  **
  @NoDoc new makeFields(Uri uri, File file)
  {
    this.uri = uri
    this.file = file
  }

  **
  ** The uri which identifies this image.  If this
  ** image maps to an image file, then this is the file's uri.
  **
  const Uri uri

  **
  ** The file referenced by this image's uri.  This field is
  ** null if this image represents a buffered image in memory.
  **
  const File? file

  **
  ** Free any operating system resources used by this image.
  ** Dispose is required if this image has been used in an operation
  ** such as FWT onPaint which allocated a system resource to
  ** represent this instance.
  **
  Void dispose() { GfxEnv.cur(false)?.imageDispose(this) }

  **
  ** Return 'uri.hash'.
  **
  override Int hash() { uri.hash }

  **
  ** Equality is based on uri.
  **
  override Bool equals(Obj? that)
  {
    x := that as Image
    if (x == null) return false
    return uri == x.uri
  }

  **
  ** Return 'uri.toStr'.
  **
  override Str toStr() { uri.toStr }

  **
  ** Get the size of the image or 0,0 if not loaded yet.
  **
  Size size() { GfxEnv.cur.imageSize(this) }

  **
  ** Resize this image into a new image.  Also see `Graphics.copyImage`.
  **
  Image resize(Size size) { GfxEnv.cur.imageResize(this, size) }

  **
  ** Write this image to the output stream as the given as a mime type.
  ** The following mime types are supported:
  **   - image/png
  **   - image/jpeg
  **   - image/gif
  **
  Void write(MimeType type, OutStream out) { GfxEnv.cur.imageWrite(this, type, out) }

}
