//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Dec 09  Andy Frank  Creation
//

using compiler
using fandoc

**
** HtmlTheme decorates a HtmlGenerator
**
class HtmlTheme
{
  **
  ** Write the beginning content for the page.
  **
  virtual Void startPage(OutStream out, Str title, Str pathToRoot)
  {
    out.print("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n")
    out.print(" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n")
    out.print("<html xmlns='http://www.w3.org/1999/xhtml'>\n")
    out.print("<head>\n")
    out.print("  <title>$title</title>\n")
    out.print("  <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/>\n")
    out.print("  <link rel='stylesheet' type='text/css' href='${pathToRoot}doc.css'/>\n")
    out.print("  <script type='text/javascript' src='${pathToRoot}doc.js'></script>\n")
    //out.print("  <script type='text/javascript' src='${pathToRoot}searchIndex.js'></script>\n")
    out.print("<!--[if lt IE 7]>\n")
    out.print("<script src='http://ie7-js.googlecode.com/svn/version/2.0(beta3)/IE7.js'")
    out.print(" type='text/javascript'></script>\n")
    out.print("<![endif]-->\n")

    out.print("</head>\n")
    out.print("<body onload='Login.check();'>\n")

    out.print("<div class='header'>\n")
    out.print("<div>\n")
    out.print("<h1><a href='/'>Fantom</a></h1>\n")
    out.print("<p id='sidewalkLogin_'>&nbsp;</p>\n")
    out.print("<form method='get' action='/sidewalk/search/'>\n")
    out.print("<p>\n")
    out.print("<input type='text' name='q' size='30' value='Search...'")
    out.print(" onfocus='if (value==\"Search...\") value=\"\"' onblur='if (value==\"\") value=\"Search...\"' />\n")
    out.print("</p>\n")
    out.print("</form>\n")
    out.print("<ul>\n")
    out.print("<li><a href='/'>Home</a></li>\n")
    out.print("<li class='active'><a href='${pathToRoot}index.html'>Docs</a></li>\n")
    out.print("<li><a href='/sidewalk/blog/'>Blog</a></li>\n")
    out.print("<li><a href='/sidewalk/ticket/'>Tickets</a></li>\n")
    out.print("<li><a href='/sidewalk/topic/'>Discuss</a></li>\n")
    out.print("</ul>")
    out.print("</div>\n")
    out.print("</div>\n")
 }

  **
  ** Write the closing content for the page.
  **
  virtual Void endPage(OutStream out)
  {
    out.print("</body>\n")
    out.print("</html>\n")
    out.close
  }

}

