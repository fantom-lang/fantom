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
    details := BorderPane
    {
      content = InsetPane(6)
      {
        GridPane
        {
          numCols = 2
          Label { text="Size"; font=Font.sys.toBold }
          Label { text="${image.size.w}px x ${image.size.h}px" }
        }
      }
      insets  = Insets(0,0,2,0)
      onBorder = |Graphics g, Size size|
      {
        g.brush = Color.sysNormShadow
        g.drawLine(0, size.h-2, size.w, size.h-2)
        g.brush = Color.sysHighlightShadow
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