//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2022  Brian Frank  Creation
//

using [java] java.awt::Image as AwtImage
using [java] javax.imageio
using [java] fanx.interop
using concurrent
using graphics

**
** Java2D graphics environment
**
const class Java2DGraphicsEnv : GraphicsEnv
{
  ** Get an image for the given uri.
  override Java2DImage image(Uri uri, Buf? data := null)
  {
    // get from cache
    image := images.get(uri) as Java2DImage
    if (image != null) return image

    // TODO: we are just loading synchronously
    if (data == null) data = resolveImageData(uri)
    image = loadImage(uri, data)

    // safely add to the cache
    return images.getOrAdd(uri, image)
  }

  ** Read memory data into BufferedImage
  Java2DImage loadImage(Uri uri, Buf data)
  {
    awt := ImageIO.read(Interop.toJava(data.in))
    mime := Image.mimeForExt(uri.ext ?: "")
    return Java2DImage(uri, mime, awt)
  }

  ** Hook to resolve a URI to its file data
  virtual Buf resolveImageData(Uri uri) { uri.toFile.readAllBuf }

  ** Image cache
  private const ConcurrentMap images := ConcurrentMap()
}

