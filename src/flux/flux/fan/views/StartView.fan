//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 08  Andy Frank  Creation
//

using fwt

**
** StartView is the default splash screen view
**
@fluxView=StartResource#
internal class StartView : View
{

  override Void onLoad()
  {
    html := StrBuf()
    html.add(
     "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
       \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
      <html xmlns='http://www.w3.org/1999/xhtml'>
      <head>
       <title>StartView</title>
       <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>
       <style type='text/css'>
         body
         {
           font: 11px 'Lucida Grande', 'Segoe UI', Tahoma, sans-serif;
           margin: 1em; padding: 0;
         }
         a { color: #00f; }
         ul.clean { list-style: none; margin: 0; }
         ul.clean li { margin: 0.5em 0; padding:0; }
       </style>
      </head>
      <body>")
    html.add("<p><b>Recently Viewed</b></p>\n")
    html.add("<ul class='clean'>\n")
    History.load.items.each |HistoryItem item|
    {
      html.add("<li><a href='$item.uri'>$item.uri<a></li>\n")
    }
    html.add("</ul>\n")
    html.add("</body>\n</html>")

    content = BorderPane
    {
      content = WebBrowser
      {
        onHyperlink.add |Event e| { frame.loadUri(e.data); e.data = null }
        loadStr(html.toStr)
      }
      insets   = Insets(0,0,0,1)
      onBorder = |Graphics g, Insets i, Size s|
      {
        g.brush = Color.sysNormShadow
        g.drawLine(0, 0, 0, s.h)
      }
    }
  }

}

**
** StartResource models an Start document.
**
internal class StartResource : Resource
{
  new make(Uri uri) { this.uri = uri }
  override Uri uri
  override Str name() { return uri.toStr }
  override Image icon() { return Flux.icon(`/x16/dialog-information.png`) }
}