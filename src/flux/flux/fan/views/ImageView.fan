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
    content = Label { halign=Halign.center; image = image }
  }

  override Void onUnload()
  {
    image?.dispose
  }

  Image image
}