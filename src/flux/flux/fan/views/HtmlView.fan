//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 08  Brian Frank  Creation
//

using fwt

**
** HtmlView uses the web browser to view HTML.
**
@fluxViewMimeType="text/html"
internal class HtmlView : View
{
  override Void onLoad()
  {
    browser := WebBrowser()
    {
      onHyperlink.add(&onHyperlink)
    }
    content = BorderPane
    {
      content  = browser
      insets   = Insets(0,0,0,1)
      onBorder = |Graphics g, Insets i, Size s|
      {
        g.brush = Color.sysNormShadow
        g.drawLine(0, 0, 0, s.h)
      }
    }
    browser.load(resource.uri)
  }

  Void onHyperlink(Event event)
  {
    // don't hyperlink in place, instead we route the
    // hyperlink to the flux frame so that we get consistent
    // navigation
    Uri uri := event.data
    event.data = null
    frame.loadUri(uri)
  }

}