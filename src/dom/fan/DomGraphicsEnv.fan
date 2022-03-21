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

    // create DomImage
    image = loadImage(uri)

    // safely add to the cache
    return images.getOrAdd(uri, image)
  }

  private DomImage loadImage(Uri uri)
  {
    mime := Image.mimeForExt(uri.ext ?: "")
    elem := Elem("img")
    elem->src = uri.encode
    return DomImage(uri, mime, elem)
  }

  private const ConcurrentMap images := ConcurrentMap()
}




