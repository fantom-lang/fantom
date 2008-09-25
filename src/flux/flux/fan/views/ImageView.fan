//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** ImageView is a simple viewer for image files.
**
@fluxViewMimeType="image"
internal class ImageView : View
{
  override Void onLoad()
  {
    image = Image(resource->file)
    content = ImageViewWidget(image)
  }

  override Void onUnload()
  {
    image?.dispose
  }

  Image image
}

internal class ImageViewWidget : Widget
{
  new make(Image image) { this.image = image }
  override Void onPaint(Graphics g)
  {
    g.drawImage(image, 8, 8)
  }
  Image image
}