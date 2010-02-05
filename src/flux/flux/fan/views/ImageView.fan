//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** ImageView is a simple viewer for image files.
**
internal class ImageView : View
{
  override Void onLoad()
  {
    image = Image.makeFile(resource->file)
    details := EdgePane
    {
      it.top = InsetPane(6)
      {
        GridPane
        {
          numCols = 2
          Label { text="Size"; font=Desktop.sysFont.toBold },
          Label { text="${this.image.size.w}px x ${this.image.size.h}px" },
        },
      }
      it.bottom = BorderPane
      {
        it.border = Border("1,0,1,0 $Desktop.sysNormShadow,#000,$Desktop.sysHighlightShadow")
      }
    }
    content = EdgePane
    {
      top = details
      center = ImageViewWidget(image)
    }
  }

  override Void onUnload()
  {
    if (image != null) Desktop.disposeImage(image)
  }

  Image? image
}

internal class ImageViewWidget : Canvas
{
  new make(Image image) { this.image = image }
  override Void onPaint(Graphics g)
  {
    g.drawImage(image, 8, 8)
  }
  Image image
}