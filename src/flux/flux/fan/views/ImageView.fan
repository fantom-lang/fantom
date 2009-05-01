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
@fluxViewMimeType="image"
internal class ImageView : View
{
  override Void onLoad()
  {
    image = Image.makeFile(resource->file)
    details := BorderPane
    {
      it.content = InsetPane(6)
      {
        GridPane
        {
          numCols = 2
          Label { text="Size"; font=Desktop.sysFont.toBold },
          Label { text="${this.image.size.w}px x ${this.image.size.h}px" },
        },
      }
      it.insets  = Insets(0,0,2,0)
      it.onBorder = |Graphics g, Size size|
      {
        g.brush = Desktop.sysNormShadow
        g.drawLine(0, size.h-2, size.w, size.h-2)
        g.brush = Desktop.sysHighlightShadow
        g.drawLine(0, size.h-1, size.w, size.h-1)
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

internal class ImageViewWidget : Widget
{
  new make(Image image) { this.image = image }
  override Void onPaint(Graphics g)
  {
    g.drawImage(image, 8, 8)
  }
  Image image
}