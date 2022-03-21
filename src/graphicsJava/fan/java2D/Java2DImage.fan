//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Brian Frank  Creation
//

using [java] java.awt.image::BufferedImage
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

  @Operator override Obj? get(Str prop) { null }

  BufferedImage? awt() { awtRef.val }

  const Unsafe awtRef
}