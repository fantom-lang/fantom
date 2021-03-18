//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2017  Matthew Giannini  Creation
//

**
** Models an Image
**
@NoDoc @Js const class Image
{
  ** Construct with it-block
  new make(|This| f) { f(this) }

  ** Decode a buffer into an Image
  static new decode(Buf buf, Bool checked := true)
  {
    try
    {
      if (JpegDecoder.isJpeg(buf)) return JpegDecoder(buf.in).decode
      if (PngDecoder.isPng(buf))   return PngDecoder(buf.in).decode
      if (SvgDecoder.isSvg(buf))   return SvgDecoder(buf.in).decode
      throw ArgErr("Could not determine image type")
    }
    catch (Err err)
    {
      if (checked) throw err
    }
    return null
  }

  ** Image format
  const MimeType mime

  ** Image size
  const Size size

  ** Image-specific properties
  protected const Str:Obj props

  ** Image properties
  **  - 'colorSpace' (Str) - the image color space (e.g.RGB, RGBA, CMYK)
  **  - 'colorSpaceBits' (Int) - bits-per-channel of the color space
  **
  @Operator Obj? get(Str prop) { props[prop] }
}