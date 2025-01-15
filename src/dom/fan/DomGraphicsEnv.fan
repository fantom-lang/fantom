//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Mar 2022  Brian Frank  Creation
//

using concurrent
using graphics

**
** Browser implementation of GraphicsEnv
**
@NoDoc @Js
const class DomGraphicsEnv : GraphicsEnv
{
  override Image image(Uri uri, Buf? data := null)
  {
    // get from cache
    image := images.get(uri) as DomImage
    if (image != null) return image

    // prep for DomImage
    src  := uri.encode
    mime := Image.mimeForLoad(uri, data)

    // if we have data, then use "data:" URI for element src
    if (data != null && data.size > 10)
      src = "data:${mime};base64," + data.toBase64

    // create DomImage
    image = loadImage(uri, mime, src)

    // safely add to the cache
    return images.getOrAdd(uri, image)
  }

  private DomImage loadImage(Uri uri, MimeType mime, Str src)
  {
    elem := Elem("img")
    elem->src = src
    return DomImage(uri, mime, elem)
  }

  private const ConcurrentMap images := ConcurrentMap()
}

