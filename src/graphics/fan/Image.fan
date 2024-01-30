//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2017  Matthew Giannini  Creation
//

**
** Graphical image.  Images are loaded from a file using `GraphicsEnv.image`.
**
@Js
mixin Image
{
  ** Render a new image with the given MIME type and size using the
  ** provided Graphics instance. Throws 'UnsupportedErr' if rendering
  ** is not supported in this env.
  static Image render(MimeType mime, Size size, |Graphics| f)
  {
    try
    {
      // render is currently only supported for the Java2D env, which
      // is not the default for VM. So we need to directly query impl
      // to check for platform support
      GraphicsEnv env := Type.find("graphicsJava::Java2DGraphicsEnv").make
      return env.renderImage(mime, size, f)
    }
    catch
    {
      throw UnsupportedErr("Image.render not supported in this env")
    }
  }

  ** Unique uri key for this image in the GraphicsEnv cache.
  abstract Uri uri()

  ** Is this image completely loaded into memory for use.  When a given
  ** uri is first accessed by `GraphicsEnv.image` it may be asynchronously
  ** loaded in the background and false is returned until load is complete.
  abstract Bool isLoaded()

  ** Image format based on file type:
  **   - 'image/png'
  **   - 'image/gif'
  **   - 'image/jpeg'
  **   - 'image/svg+xml'
  abstract MimeType mime()

  ** Get the natural size of this image.
  ** If the image has not been loaded yet, then return 0,0.
  abstract Size size()

  ** Get the size width
  virtual Float w() { size.w }

  ** Get the size height
  virtual Float h() { size.h }

  ** Write image content to the given output stream, where encoding
  ** is based on `mime` type.  Throws 'UnsupportedErr' if write is
  ** not supported in this env.
  virtual Void write(OutStream out)
  {
    throw UnsupportedErr("Image.write not supported in this env")
  }

  ** Image properties
  **  - 'colorSpace' (Str) - the image color space (e.g.RGB, RGBA, CMYK)
  **  - 'colorSpaceBits' (Int) - bits-per-channel of the color space
  @NoDoc @Operator abstract Obj? get(Str prop)

  ** Map file extension to mime type
  @NoDoc static MimeType mimeForExt(Str ext)
  {
    ext = ext.lower
    if (ext == "svg") return mimeSvg
    if (ext == "png") return mimePng
    if (ext == "jpg" || ext == "jpeg") return mimeJpeg
    if (ext == "gif") return mimeGif
    return MimeType.forExt(ext) ?: MimeType("image/unknown")
  }

  @NoDoc static const MimeType mimePng  := MimeType("image/png")
  @NoDoc static const MimeType mimeGif  := MimeType("image/gif")
  @NoDoc static const MimeType mimeJpeg := MimeType("image/jpeg")
  @NoDoc static const MimeType mimeSvg  := MimeType("image/svg+xml")
}

**************************************************************************
** PngImage
**************************************************************************

**
** Details for an PNG image.  This is just a temporary solution
** until we flush out formal APIs for color models, pixel access, etc.
**
@Js @NoDoc
mixin PngImage : Image
{
  ** Does the image have an alpha channel
  Bool hasAlpha() { colorType == 4 || colorType == 6 }

  ** Does the image have a palette index
  Bool hasPalette() { palette.size > 0 }

  ** Does the image have simple transparency alpha channel
  Bool hasTransparency() { transparency.size > 0 }

  ** Color type code
  Int colorType() { get("colorType") }

  ** Number of color components
  Int colors()
  {
    c := (colorType == 2 || colorType == 6) ? 3 : 1
    return hasAlpha ? c + 1 : c
  }

  ** Number of bits in a pixel
  Int pixelBits() { colors * ((Int)get("colorSpaceBits")) }

  ** The palette index. The Buf is immutable.
  Buf palette() { get("palette") }

  ** The simple transparency alpha channel. The Buf is immutable.
  Buf transparency() { get("transparency") }

  ** Raw image data. The Buf is immutable.
  Buf imgData() { get("imgData") }

  ** Get decompressed pixels. The Buf is immutable.
  abstract Buf pixels()
}