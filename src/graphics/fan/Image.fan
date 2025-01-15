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

  ** Map file extension for GraphicsEnv.image
  @NoDoc static MimeType mimeForLoad(Uri uri, Buf? data)
  {
    // prefer data over URI if available
    if (data != null)
    {
      mime := mimeForData(data)
      if (mime != null) return mime
    }

    // try to infer from URI extension
    return mimeForUri(uri) ?: mimeUnknown
  }

  ** Map file extension to mime type or return null
  @NoDoc static MimeType? mimeForUri(Uri uri)
  {
    ext := uri.ext?.lower ?: ""
    if (ext == "svg") return mimeSvg
    if (ext == "png") return mimePng
    if (ext == "jpg" || ext == "jpeg") return mimeJpeg
    if (ext == "gif") return mimeGif
    return MimeType.forExt(ext)
  }

  ** Try to map image file to mime type
  @NoDoc static MimeType? mimeForData(Buf data)
  {
    if (data.size > 4)
    {
      d0 := data[0]
      d1 := data[1]
      d2 := data[2]
      d3 := data[3]
      if (d0 == '<' && d1 == 's' && d2 == 'v' && d3 == 'g') return mimeSvg
      if (d0==0x89 && d1==0x50 && d2==0x4E && d3==0x47) return mimePng
      if (d0==0x47 && d1==0x49 && d2==0x46) return mimeGif
      if (d0==0xFF && d1==0xD8) return mimeJpeg
    }
    return null
  }

  @NoDoc static const MimeType mimePng     := MimeType("image/png")
  @NoDoc static const MimeType mimeGif     := MimeType("image/gif")
  @NoDoc static const MimeType mimeJpeg    := MimeType("image/jpeg")
  @NoDoc static const MimeType mimeSvg     := MimeType("image/svg+xml")
  @NoDoc static const MimeType mimeUnknown := MimeType("image/unknown")
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

