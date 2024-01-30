//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using [java] java.awt.image::BufferedImage
using [java] javax.imageio
using [java] fanx.interop
using graphics

**
** Java2D image
**
const class Java2DImage : Image
{
  new make(Uri uri, MimeType mime, BufferedImage? awt)
  {
    this.uri = uri
    this.mime = mime
    this.size = awt == null ? Size.defVal : Size(awt.getWidth, awt.getHeight)
    this.awtRef = Unsafe(awt)
  }

  const override Uri uri

  const override MimeType mime

  override Bool isLoaded() { true }

  override const Size size

  override Void write(OutStream out)
  {
    // NOTE: ImageIO.write does not appear to throw any exceptions if the
    // format is unsupported, it simply writes zero content, so make sure
    // any formats added here get tested

    // get encoding format
    Str? format
    switch (mime)
    {
      case Image.mimePng: format = "png"
      case Image.mimeGif: format = "gif"
      default: throw UnsupportedErr("Mime type not supported '${mime}'")
    }

    // sanity check
    if (awt == null) throw IOErr("No raster data available")

    // write
    ImageIO.write(awt, format, Interop.toJava(out))
  }

  @Operator override Obj? get(Str prop) { null }

  BufferedImage? awt() { awtRef.val }

  const Unsafe awtRef
}