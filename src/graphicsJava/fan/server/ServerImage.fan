//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2021  Brian Frank  Creation
//

using graphics

**
** ServerImage implements the Image API for server side layout and rendering.
** It utilizes a set of decoders to extract meta-data for size and color model.
**
internal const class ServerImage : Image
{
  static new load(Uri uri, Buf buf, Bool checked := true)
  {
    try
    {
      if (JpegDecoder.isJpeg(buf)) return JpegDecoder(uri, buf.in).decode
      if (PngDecoder.isPng(buf))   return PngDecoder(uri, buf.in).decode
      if (SvgDecoder.isSvg(buf))   return SvgDecoder(uri, buf.in).decode
      throw ArgErr("Could not determine image type")
    }
    catch (Err err)
    {
      if (checked) throw err
    }
    return null
  }

  new make(|This| f) { f(this) }

  const override Uri uri

  const override MimeType mime

  const override Size size

  const Str:Obj props

  override Bool isLoaded() { true }

  @Operator override Obj? get(Str name) { props[name] }
}