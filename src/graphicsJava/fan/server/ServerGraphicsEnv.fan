//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Mar 2021  Brian Frank  Creation
//

using concurrent
using graphics

**
** ServerGraphicsEnv provides a simple headless server-side implementation
** of the graphics toolkit.  It is largely concerned with font metrics and
** image sizes for layout in headless rendering engines.
**
** Images are parsed to determine size and other meta-data such as the color
** model.  The following image file types are supported: PNG, JPEG, and SVG.
**
** Currently we rely on Font.metrics and FontData as implemented in the
** graphics pod itself.  However, that not a tenable long term solution.
**
const class ServerGraphicsEnv : GraphicsEnv
{

  ** Images only support size for server-side layout and rendering
  override Image image(Uri uri, Buf? data := null)
  {
    // get from cache
    image := images.get(uri) as Image
    if (image != null) return image

    // load
    if (data == null) data = resolveImageData(uri)
    image = ServerImage.load(uri, data)

    // safely add to the cache
    return images.getOrAdd(uri, image)
  }

  ** Hook to resolve a URI to its file data
  virtual Buf resolveImageData(Uri uri) { uri.toFile.readAllBuf }

  ** Image cache
  private const ConcurrentMap images := ConcurrentMap()

}